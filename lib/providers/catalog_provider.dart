import 'package:flutter/foundation.dart';

import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum CatalogLoadState { loading, loaded, empty, error }

/// Drives the Home screen's discovery rows: trending, Bollywood, and
/// Continue Watching. Each row tracks its own load state independently
/// so a slow/failed genre row never blocks the rest of the screen from
/// rendering.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider({ApiService? apiService, StorageService? storageService})
      : _api = apiService ?? ApiService(),
        _storage = storageService ?? StorageService();

  final ApiService _api;
  final StorageService _storage;

  List<Movie> _trending = [];
  List<Movie> _bollywood = [];
  List<Movie> _continueWatching = [];
  Movie? _heroMovie;

  CatalogLoadState _trendingState = CatalogLoadState.loading;
  CatalogLoadState _bollywoodState = CatalogLoadState.loading;

  List<Movie> get trending => _trending;
  List<Movie> get bollywood => _bollywood;
  List<Movie> get continueWatching => _continueWatching;
  Movie? get heroMovie => _heroMovie;
  CatalogLoadState get trendingState => _trendingState;
  CatalogLoadState get bollywoodState => _bollywoodState;

  Future<void> loadHome() async {
    _trendingState = CatalogLoadState.loading;
    _bollywoodState = CatalogLoadState.loading;
    notifyListeners();

    await Future.wait([
      _loadTrending(),
      _loadBollywood(),
      _loadContinueWatching(),
    ]);
  }

  Future<void> _loadTrending() async {
    try {
      final page = await _api.getTrending();
      _trending = page.results;
      _heroMovie = page.results.isNotEmpty ? page.results.first : null;
      _trendingState = _trending.isEmpty ? CatalogLoadState.empty : CatalogLoadState.loaded;
    } catch (_) {
      _trendingState = CatalogLoadState.error;
    }
    notifyListeners();
  }

  Future<void> _loadBollywood() async {
    try {
      final page = await _api.getBollywoodDiscovery();
      _bollywood = page.results;
      _bollywoodState = _bollywood.isEmpty ? CatalogLoadState.empty : CatalogLoadState.loaded;
    } catch (_) {
      _bollywoodState = CatalogLoadState.error;
    }
    notifyListeners();
  }

  Future<void> _loadContinueWatching() async {
    final ids = await _storage.getContinueWatchingIds();
    if (ids.isEmpty) {
      _continueWatching = [];
      notifyListeners();
      return;
    }
    // Resolve continue-watching IDs against whatever's already loaded in
    // trending/bollywood to avoid extra network calls; movies not found
    // there are simply omitted (acceptable for a demo catalog).
    final pool = [..._trending, ..._bollywood];
    _continueWatching = ids
        .map((id) {
          try {
            return pool.firstWhere((m) => m.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Movie>()
        .toList();
    notifyListeners();
  }

  Future<void> refresh() => loadHome();
}
