import '../constants/api_constants.dart';

/// Represents a single movie entry sourced from TMDB metadata.
///
/// Every field has a safe fallback so a partially-malformed API response
/// (a missing poster, a null overview, a genre_ids list absent from a
/// /search result) never crashes JSON parsing — it degrades to sensible
/// defaults ("No overview available.", empty genre list, null image URL)
/// instead.
class Movie {
  final int id;
  final String title;
  final String originalTitle;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final DateTime? releaseDate;
  final List<int> genreIds;
  final String originalLanguage;
  final double popularity;
  final bool adult;

  // Populated only by the movie-details endpoint (not list/search
  // responses); null until fetched via ApiService.getMovieDetails.
  final int? runtimeMinutes;
  final List<Genre>? genres;
  final String? tagline;
  final String? status;

  const Movie({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    required this.genreIds,
    required this.originalLanguage,
    required this.popularity,
    required this.adult,
    this.runtimeMinutes,
    this.genres,
    this.tagline,
    this.status,
  });

  String? get posterUrl =>
      posterPath != null ? '${ApiConstants.imageBaseUrlPoster}$posterPath' : null;

  String? get backdropUrl =>
      backdropPath != null ? '${ApiConstants.imageBaseUrlBackdrop}$backdropPath' : null;

  int? get releaseYear => releaseDate?.year;

  String get ratingLabel => voteAverage > 0 ? voteAverage.toStringAsFixed(1) : 'N/A';

  String get runtimeLabel {
    final minutes = runtimeMinutes;
    if (minutes == null || minutes <= 0) return '';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: _asInt(json['id']) ?? 0,
      title: _asString(json['title']) ?? _asString(json['name']) ?? 'Untitled',
      originalTitle: _asString(json['original_title']) ??
          _asString(json['original_name']) ??
          _asString(json['title']) ??
          'Untitled',
      overview: _asString(json['overview'])?.trim().isNotEmpty == true
          ? json['overview'] as String
          : 'No overview available.',
      posterPath: _asString(json['poster_path']),
      backdropPath: _asString(json['backdrop_path']),
      voteAverage: _asDouble(json['vote_average']) ?? 0.0,
      voteCount: _asInt(json['vote_count']) ?? 0,
      releaseDate: _asDate(json['release_date']) ?? _asDate(json['first_air_date']),
      genreIds: _asIntList(json['genre_ids']),
      originalLanguage: _asString(json['original_language']) ?? 'en',
      popularity: _asDouble(json['popularity']) ?? 0.0,
      adult: json['adult'] == true,
      runtimeMinutes: _asInt(json['runtime']),
      genres: (json['genres'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(Genre.fromJson)
          .toList(),
      tagline: _asString(json['tagline']),
      status: _asString(json['status']),
    );
  }

  Movie copyWithDetails({
    int? runtimeMinutes,
    List<Genre>? genres,
    String? tagline,
    String? status,
  }) {
    return Movie(
      id: id,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      voteCount: voteCount,
      releaseDate: releaseDate,
      genreIds: genreIds,
      originalLanguage: originalLanguage,
      popularity: popularity,
      adult: adult,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      genres: genres ?? this.genres,
      tagline: tagline ?? this.tagline,
      status: status ?? this.status,
    );
  }

  static String? _asString(dynamic v) => v is String ? v : null;

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _asDate(dynamic v) {
    if (v is! String || v.trim().isEmpty) return null;
    return DateTime.tryParse(v);
  }

  static List<int> _asIntList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => _asInt(e)).whereType<int>().toList();
  }
}

/// A TMDB genre (id + display name).
class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: Movie._asInt(json['id']) ?? 0,
      name: Movie._asString(json['name']) ?? 'Unknown',
    );
  }
}

/// A single cast member from TMDB's /credits endpoint.
class CastMember {
  final int id;
  final String name;
  final String character;
  final String? profilePath;
  final int order;

  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
    required this.order,
  });

  String? get profileUrl =>
      profilePath != null ? '${ApiConstants.imageBaseUrlProfile}$profilePath' : null;

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: Movie._asInt(json['id']) ?? 0,
      name: Movie._asString(json['name']) ?? 'Unknown',
      character: Movie._asString(json['character']) ?? '',
      profilePath: Movie._asString(json['profile_path']),
      order: Movie._asInt(json['order']) ?? 999,
    );
  }
}

/// A paginated TMDB list response wrapper (trending/discover/search all
/// share this shape).
class MoviePage {
  final int page;
  final List<Movie> results;
  final int totalPages;
  final int totalResults;

  const MoviePage({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  bool get hasNextPage => page < totalPages;

  factory MoviePage.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    return MoviePage(
      page: Movie._asInt(json['page']) ?? 1,
      results: rawResults is List
          ? rawResults
              .whereType<Map<String, dynamic>>()
              .map(Movie.fromJson)
              .toList()
          : const [],
      totalPages: Movie._asInt(json['total_pages']) ?? 1,
      totalResults: Movie._asInt(json['total_results']) ?? 0,
    );
  }

  factory MoviePage.empty() =>
      const MoviePage(page: 1, results: [], totalPages: 1, totalResults: 0);
}
