/// TMDB (The Movie Database) API configuration. TMDB provides catalog
/// **metadata only** — titles, posters, backdrops, cast, ratings — never
/// video files. Actual playback in this app is served exclusively by
/// [StreamResolver] against a source you configure yourself (see
/// lib/services/stream_resolver.dart), keeping metadata discovery and
/// video delivery as two entirely separate, independently-swappable
/// concerns.
class ApiConstants {
  ApiConstants._();

  /// TMDB v3 API key. In a production fork, prefer injecting this via
  /// --dart-define at build time rather than committing a real key to
  /// source control; the value below is left as a plain constant only to
  /// match this project's existing demo-build conventions.
  static const String tmdbApiKey = 'C13a231e53124174bb1247c2b4fc051e';

  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

  static const String imageBaseUrlPoster = 'https://image.tmdb.org/t/p/w500';
  static const String imageBaseUrlBackdrop = 'https://image.tmdb.org/t/p/original';
  static const String imageBaseUrlProfile = 'https://image.tmdb.org/t/p/w185';

  // Endpoints (appended to tmdbBaseUrl)
  static const String endpointTrendingMoviesWeek = '/trending/movie/week';
  static const String endpointTrendingMoviesDay = '/trending/movie/day';
  static const String endpointDiscoverMovie = '/discover/movie';
  static const String endpointSearchMovie = '/search/movie';
  static const String endpointMovieDetails = '/movie'; // + /{id}
  static const String endpointMovieCredits = '/credits'; // appended to /movie/{id}
  static const String endpointMovieVideos = '/videos'; // appended to /movie/{id}
  static const String endpointGenreList = '/genre/movie/list';

  /// Hindi/Bollywood cinema discovery filter: original_language=hi with
  /// region=IN, sorted by popularity.
  static const String bollywoodLanguageFilter = 'hi';
  static const String indiaRegion = 'IN';

  static const Duration requestTimeout = Duration(seconds: 12);

  /// Timeout for stream resolution/probing before falling back to a
  /// secondary source, per the "15s timeout, multi-server fallback"
  /// requirement.
  static const Duration streamResolveTimeout = Duration(seconds: 15);
}
