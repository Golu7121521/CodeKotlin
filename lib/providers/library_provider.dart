import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/storage_service.dart';

/// Reactive layer over StorageService so UI rebuilds automatically when
/// favorites, playlists, or recently-played history change.
class LibraryProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Song> _favorites = [];
  List<Song> _recentlyPlayed = [];
  List<String> _playlistNames = [];

  List<Song> get favorites => _favorites;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<String> get playlistNames => _playlistNames;

  Future<void> loadAll() async {
    _favorites = await _storage.getFavorites();
    _recentlyPlayed = await _storage.getRecentlyPlayed();
    _playlistNames = await _storage.getPlaylistNames();
    notifyListeners();
  }

  bool isFavorite(Song song) {
    return _favorites.any((s) => s.identityKey == song.identityKey);
  }

  Future<bool> toggleFavorite(Song song) async {
    final result = await _storage.toggleFavorite(song);
    _favorites = await _storage.getFavorites();
    notifyListeners();
    return result;
  }

  Future<void> refreshRecentlyPlayed() async {
    _recentlyPlayed = await _storage.getRecentlyPlayed();
    notifyListeners();
  }

  Future<void> clearRecentlyPlayed() async {
    await _storage.clearRecentlyPlayed();
    _recentlyPlayed = [];
    notifyListeners();
  }

  Future<bool> createPlaylist(String name) async {
    final success = await _storage.createPlaylist(name);
    if (success) {
      _playlistNames = await _storage.getPlaylistNames();
      notifyListeners();
    }
    return success;
  }

  Future<void> deletePlaylist(String name) async {
    await _storage.deletePlaylist(name);
    _playlistNames = await _storage.getPlaylistNames();
    notifyListeners();
  }

  Future<bool> renamePlaylist(String oldName, String newName) async {
    final success = await _storage.renamePlaylist(oldName, newName);
    if (success) {
      _playlistNames = await _storage.getPlaylistNames();
      notifyListeners();
    }
    return success;
  }

  Future<List<Song>> getPlaylistSongs(String name) {
    return _storage.getPlaylistSongs(name);
  }

  Future<void> addSongToPlaylist(String name, Song song) async {
    await _storage.addSongToPlaylist(name, song);
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String name, Song song) async {
    await _storage.removeSongFromPlaylist(name, song);
    notifyListeners();
  }
}
