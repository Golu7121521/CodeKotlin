import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/api_service.dart';

enum SearchStatus { idle, loading, success, empty, error, offline }

class SearchProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Timer? _debounceTimer;

  SearchStatus _status = SearchStatus.idle;
  List<Song> _results = [];
  String? _errorMessage;
  String _lastQuery = '';

  SearchStatus get status => _status;
  List<Song> get results => _results;
  String? get errorMessage => _errorMessage;

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _status = SearchStatus.idle;
      _results = [];
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      _executeSearch(query);
    });
  }

  Future<void> searchImmediately(String query) async {
    _debounceTimer?.cancel();
    await _executeSearch(query);
  }

  Future<void> _executeSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == _lastQuery && _results.isNotEmpty) return;

    _lastQuery = trimmed;
    _status = SearchStatus.loading;
    notifyListeners();

    final result = await _api.searchSongs(trimmed);

    if (!result.success) {
      _status = SearchStatus.error;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return;
    }

    _results = result.data ?? [];
    _status = _results.isEmpty ? SearchStatus.empty : SearchStatus.success;
    notifyListeners();
  }

  void retry() {
    if (_lastQuery.isNotEmpty) {
      _executeSearch(_lastQuery);
    }
  }

  void reset() {
    _debounceTimer?.cancel();
    _status = SearchStatus.idle;
    _results = [];
    _lastQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
