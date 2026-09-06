import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/movie_model.dart';
import '../services/api_service.dart';

enum SearchState { idle, loading, loaded, empty, error }

/// Drives the Search screen: debounced predictive search with
/// pagination (load-more on scroll).
class SearchProvider extends ChangeNotifier {
  SearchProvider({ApiService? apiService}) : _api = apiService ?? ApiService();

  final ApiService _api;
  Timer? _debounce;

  String _query = '';
  List<Movie> _results = [];
  SearchState _state = SearchState.idle;
  int _page = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  String get query => _query;
  List<Movie> get results => _results;
  SearchState get state => _state;
  bool get hasMore => _page < _totalPages;
  bool get isLoadingMore => _isLoadingMore;

  void onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _results = [];
      _state = SearchState.idle;
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    _state = SearchState.loading;
    notifyListeners();

    try {
      final page = await _api.search(value, page: 1);
      _results = page.results;
      _page = page.page;
      _totalPages = page.totalPages;
      _state = _results.isEmpty ? SearchState.empty : SearchState.loaded;
    } catch (_) {
      _state = SearchState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _query.trim().isEmpty) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _api.search(_query, page: _page + 1);
      _results = [..._results, ...page.results];
      _page = page.page;
      _totalPages = page.totalPages;
    } catch (_) {
      // Silently keep existing results; load-more failures aren't
      // critical enough to disrupt an already-successful search.
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
