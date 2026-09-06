import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

/// Local persistence for favorites, recently played, and playlists.
/// Backed by SharedPreferences with JSON-serialized song lists.
class StorageService {
  static const String _keyFavorites = 'favorites';
  static const String _keyRecentlyPlayed = 'recently_played';
  static const String _keyPlaylistNames = 'playlist_names';
  static const String _keyPlaylistPrefix = 'playlist_';
  static const String _keyThemeMode = 'theme_mode';
  static const int _maxRecentlyPlayed = 50;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---------------- Theme ----------------

  Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyThemeMode, mode);
  }

  // ---------------- Favorites ----------------

  Future<List<Song>> getFavorites() async {
    final prefs = await _prefs;
    return _decodeSongList(prefs.getString(_keyFavorites));
  }

  Future<bool> isFavorite(Song song) async {
    final favorites = await getFavorites();
    return favorites.any((s) => s.identityKey == song.identityKey);
  }

  /// Returns true if the song is now favorited, false if it was removed.
  Future<bool> toggleFavorite(Song song) async {
    final prefs = await _prefs;
    final favorites = await getFavorites();

    final existingIndex = favorites.indexWhere((s) => s.identityKey == song.identityKey);
    bool nowFavorite;

    if (existingIndex >= 0) {
      favorites.removeAt(existingIndex);
      nowFavorite = false;
    } else {
      favorites.insert(0, song);
      nowFavorite = true;
    }

    await prefs.setString(_keyFavorites, _encodeSongList(favorites));
    return nowFavorite;
  }

  // ---------------- Recently Played ----------------

  Future<List<Song>> getRecentlyPlayed() async {
    final prefs = await _prefs;
    return _decodeSongList(prefs.getString(_keyRecentlyPlayed));
  }

  Future<void> addRecentlyPlayed(Song song) async {
    final prefs = await _prefs;
    final recent = await getRecentlyPlayed();

    recent.removeWhere((s) => s.identityKey == song.identityKey);
    recent.insert(0, song);

    while (recent.length > _maxRecentlyPlayed) {
      recent.removeLast();
    }

    await prefs.setString(_keyRecentlyPlayed, _encodeSongList(recent));
  }

  Future<void> clearRecentlyPlayed() async {
    final prefs = await _prefs;
    await prefs.setString(_keyRecentlyPlayed, '[]');
  }

  // ---------------- Playlists ----------------

  Future<List<String>> getPlaylistNames() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyPlaylistNames);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final names = await getPlaylistNames();
    if (names.any((n) => n.toLowerCase() == trimmed.toLowerCase())) {
      return false;
    }

    names.add(trimmed);
    await _savePlaylistNames(names);

    final prefs = await _prefs;
    await prefs.setString(_playlistKey(trimmed), '[]');
    return true;
  }

  Future<void> deletePlaylist(String name) async {
    final names = await getPlaylistNames();
    names.remove(name);
    await _savePlaylistNames(names);

    final prefs = await _prefs;
    await prefs.remove(_playlistKey(name));
  }

  Future<bool> renamePlaylist(String oldName, String newName) async {
    final trimmedNew = newName.trim();
    if (trimmedNew.isEmpty) return false;

    final names = await getPlaylistNames();
    if (!names.contains(oldName)) return false;
    if (names.any((n) => n.toLowerCase() == trimmedNew.toLowerCase())) {
      return false;
    }

    final songs = await getPlaylistSongs(oldName);

    final index = names.indexOf(oldName);
    names[index] = trimmedNew;
    await _savePlaylistNames(names);

    final prefs = await _prefs;
    await prefs.remove(_playlistKey(oldName));
    await prefs.setString(_playlistKey(trimmedNew), _encodeSongList(songs));
    return true;
  }

  Future<List<Song>> getPlaylistSongs(String name) async {
    final prefs = await _prefs;
    return _decodeSongList(prefs.getString(_playlistKey(name)));
  }

  Future<void> addSongToPlaylist(String name, Song song) async {
    final songs = await getPlaylistSongs(name);
    if (songs.any((s) => s.identityKey == song.identityKey)) return;

    songs.add(song);
    final prefs = await _prefs;
    await prefs.setString(_playlistKey(name), _encodeSongList(songs));
  }

  Future<void> removeSongFromPlaylist(String name, Song song) async {
    final songs = await getPlaylistSongs(name);
    songs.removeWhere((s) => s.identityKey == song.identityKey);

    final prefs = await _prefs;
    await prefs.setString(_playlistKey(name), _encodeSongList(songs));
  }

  Future<void> _savePlaylistNames(List<String> names) async {
    final prefs = await _prefs;
    await prefs.setString(_keyPlaylistNames, jsonEncode(names));
  }

  String _playlistKey(String name) => '$_keyPlaylistPrefix$name';

  // ---------------- Encoding helpers ----------------

  String _encodeSongList(List<Song> songs) {
    return jsonEncode(songs.map((s) => s.toStorageJson()).toList());
  }

  List<Song> _decodeSongList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => Song.fromStorageJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
