import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's watchlist ("My List") and per-movie playback
/// resume positions to local storage via SharedPreferences.
class StorageService {
  static const _keyWatchlist = 'storage.watchlist';
  static const _keyPlaybackPrefix = 'storage.playback.';
  static const _keyPerformanceMode = 'storage.performanceMode';

  Future<Set<int>> getWatchlistIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyWatchlist) ?? const [];
    return raw.map(int.parse).toSet();
  }

  Future<void> toggleWatchlist(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyWatchlist) ?? const []).toSet();
    final idStr = '$movieId';
    if (current.contains(idStr)) {
      current.remove(idStr);
    } else {
      current.add(idStr);
    }
    await prefs.setStringList(_keyWatchlist, current.toList());
  }

  Future<bool> isInWatchlist(int movieId) async {
    final ids = await getWatchlistIds();
    return ids.contains(movieId);
  }

  /// Saves the current playback position (in seconds) for a movie, used
  /// to power "Continue Watching" and resume-from-last-position.
  Future<void> savePlaybackPosition(int movieId, Duration position, Duration total) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'positionMs': position.inMilliseconds,
      'totalMs': total.inMilliseconds,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await prefs.setString('$_keyPlaybackPrefix$movieId', payload);
  }

  Future<PlaybackPosition?> getPlaybackPosition(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPlaybackPrefix$movieId');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PlaybackPosition(
        position: Duration(milliseconds: decoded['positionMs'] as int? ?? 0),
        total: Duration(milliseconds: decoded['totalMs'] as int? ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          decoded['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// All movie IDs with a saved in-progress position, most-recent first
  /// — backs the "Continue Watching" row.
  Future<List<int>> getContinueWatchingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPlaybackPrefix));
    final entries = <MapEntry<int, DateTime>>[];
    for (final key in keys) {
      final movieId = int.tryParse(key.substring(_keyPlaybackPrefix.length));
      if (movieId == null) continue;
      final pos = await getPlaybackPosition(movieId);
      if (pos == null) continue;
      // Treat >=95% watched as complete; exclude from Continue Watching.
      if (pos.total.inMilliseconds > 0 &&
          pos.position.inMilliseconds / pos.total.inMilliseconds >= 0.95) {
        continue;
      }
      entries.add(MapEntry(movieId, pos.updatedAt));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  Future<AppPerformanceModePref> getPerformanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyPerformanceMode);
    return value == 'reduced' ? AppPerformanceModePref.reduced : AppPerformanceModePref.auto;
  }

  Future<void> setPerformanceMode(AppPerformanceModePref mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPerformanceMode, mode.name);
  }
}

class PlaybackPosition {
  final Duration position;
  final Duration total;
  final DateTime updatedAt;

  const PlaybackPosition({
    required this.position,
    required this.total,
    required this.updatedAt,
  });

  double get fraction {
    if (total.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }
}

enum AppPerformanceModePref { auto, reduced }
