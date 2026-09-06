import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// Tracks the user's "My List" (watchlist) membership set, so any screen
/// can show/toggle the add-to-list state without re-reading storage.
class WatchlistProvider extends ChangeNotifier {
  WatchlistProvider({StorageService? storageService})
      : _storage = storageService ?? StorageService();

  final StorageService _storage;
  Set<int> _ids = {};

  Set<int> get ids => _ids;

  Future<void> load() async {
    _ids = await _storage.getWatchlistIds();
    notifyListeners();
  }

  bool isInList(int movieId) => _ids.contains(movieId);

  Future<void> toggle(int movieId) async {
    await _storage.toggleWatchlist(movieId);
    if (_ids.contains(movieId)) {
      _ids = {..._ids}..remove(movieId);
    } else {
      _ids = {..._ids, movieId};
    }
    notifyListeners();
  }
}
