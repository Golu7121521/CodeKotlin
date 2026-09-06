import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/movie_model.dart';
import 'fallback_catalog.dart';

/// Thrown for API failures that were not recoverable via the embedded
/// fallback catalog (used sparingly — most call sites prefer degrading
/// to fallback data over throwing, per the "never breaks the app"
/// resilience requirement).
class ApiServiceException implements Exception {
  final String message;
  ApiServiceException(this.message);
  @override
  String toString() => 'ApiServiceException: $message';
}

/// Fetches and paginates TMDB catalog metadata. Every public method is
/// resilient to network failure: on timeout, DNS failure, or a
/// SocketException (all common on flaky Indian ISP DNS routing, per the
/// original resilience requirement), list-returning methods fall back to
/// [FallbackCatalog] rather than surfacing an error to the UI.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final params = {
      'api_key': ApiConstants.tmdbApiKey,
      ...?query,
    };
    return Uri.parse('${ApiConstants.tmdbBaseUrl}$path').replace(queryParameters: params);
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(ApiConstants.requestTimeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on TimeoutException {
      return null;
    } on SocketException {
      // Covers DNS resolution failures and connection refusal, the
      // dominant failure mode on unreliable mobile networks.
      return null;
    } on HttpException {
      return null;
    } on FormatException {
      // Malformed JSON in the response body.
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Trending movies this week. Falls back to an embedded catalog on any
  /// network failure so the Home screen is never empty.
  Future<MoviePage> getTrending({int page = 1}) async {
    final uri = _buildUri(ApiConstants.endpointTrendingMoviesWeek, {
      'page': '$page',
    });
    final json = await _getJson(uri);
    if (json == null) {
      final fallback = FallbackCatalog.trending();
      return MoviePage(page: 1, results: fallback, totalPages: 1, totalResults: fallback.length);
    }
    return MoviePage.fromJson(json);
  }

  /// Discovers Hindi/Bollywood cinema via original_language + region
  /// filters, sorted by popularity, with pagination support.
  Future<MoviePage> getBollywoodDiscovery({int page = 1}) async {
    final uri = _buildUri(ApiConstants.endpointDiscoverMovie, {
      'with_original_language': ApiConstants.bollywoodLanguageFilter,
      'region': ApiConstants.indiaRegion,
      'sort_by': 'popularity.desc',
      'page': '$page',
    });
    final json = await _getJson(uri);
    if (json == null) {
      final fallback = FallbackCatalog.bollywood();
      return MoviePage(page: 1, results: fallback, totalPages: 1, totalResults: fallback.length);
    }
    return MoviePage.fromJson(json);
  }

  /// Generic discover query, e.g. for genre-filtered rows on Home.
  Future<MoviePage> discoverByGenre({required int genreId, int page = 1}) async {
    final uri = _buildUri(ApiConstants.endpointDiscoverMovie, {
      'with_genres': '$genreId',
      'sort_by': 'popularity.desc',
      'page': '$page',
    });
    final json = await _getJson(uri);
    if (json == null) return MoviePage.empty();
    return MoviePage.fromJson(json);
  }

  /// Full-text search with pagination. Returns an empty page (not the
  /// fallback catalog — showing unrelated fallback results for a failed
  /// search would be misleading) on network failure so the UI can show a
  /// dedicated "couldn't search right now" state.
  Future<MoviePage> search(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return MoviePage.empty();
    final uri = _buildUri(ApiConstants.endpointSearchMovie, {
      'query': query.trim(),
      'page': '$page',
      'include_adult': 'false',
    });
    final json = await _getJson(uri);
    if (json == null) return MoviePage.empty();
    return MoviePage.fromJson(json);
  }

  /// Fetches full movie details (runtime, genres, tagline, status) and
  /// merges them onto the base [Movie] the caller already has from a
  /// list/search response.
  Future<Movie> getMovieDetails(Movie base) async {
    final uri = _buildUri('${ApiConstants.endpointMovieDetails}/${base.id}');
    final json = await _getJson(uri);
    if (json == null) return base;
    final detailed = Movie.fromJson(json);
    return base.copyWithDetails(
      runtimeMinutes: detailed.runtimeMinutes,
      genres: detailed.genres,
      tagline: detailed.tagline,
      status: detailed.status,
    );
  }

  /// Top-billed cast for a movie, ordered as TMDB returns them (already
  /// sorted by billing order).
  Future<List<CastMember>> getCast(int movieId) async {
    final uri = _buildUri('${ApiConstants.endpointMovieDetails}/$movieId${ApiConstants.endpointMovieCredits}');
    final json = await _getJson(uri);
    if (json == null) return const [];
    final cast = json['cast'];
    if (cast is! List) return const [];
    return cast
        .whereType<Map<String, dynamic>>()
        .map(CastMember.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// All movie genres, used to populate filter chips. Falls back to a
  /// small embedded list of common genres on failure.
  Future<List<Genre>> getGenres() async {
    final uri = _buildUri(ApiConstants.endpointGenreList);
    final json = await _getJson(uri);
    if (json == null) return FallbackCatalog.genres();
    final genres = json['genres'];
    if (genres is! List) return FallbackCatalog.genres();
    return genres.whereType<Map<String, dynamic>>().map(Genre.fromJson).toList();
  }

  void dispose() {
    _client.close();
  }
}
