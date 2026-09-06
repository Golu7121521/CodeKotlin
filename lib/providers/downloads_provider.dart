import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_item_model.dart';
import '../models/movie_model.dart';
import '../services/download_service.dart';

/// Drives the download-manager state machine: Queued -> Downloading ->
/// (Paused) -> Downloaded -> (Expired), persisting entries to
/// SharedPreferences so downloads survive app restarts.
class DownloadsProvider extends ChangeNotifier {
  DownloadsProvider({DownloadService? downloadService})
      : _downloadService = downloadService ?? DownloadService();

  static const _storageKey = 'downloads.items';

  final DownloadService _downloadService;
  final Map<int, DownloadItem> _items = {};

  List<DownloadItem> get all => _items.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<DownloadItem> get active => all
      .where((i) =>
          i.status == DownloadStatus.queued ||
          i.status == DownloadStatus.downloading ||
          i.status == DownloadStatus.paused)
      .toList();

  List<DownloadItem> get downloaded =>
      all.where((i) => i.status == DownloadStatus.downloaded).toList();

  DownloadItem? forMovie(int movieId) => _items[movieId];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    _items.clear();
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        final item = DownloadItem.fromJson(decoded);
        _items[item.movieId] = item;
      } catch (_) {
        // Skip corrupted entries rather than failing the whole load.
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _items.values.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_storageKey, serialized);
  }

  Future<void> startDownload(Movie movie, String sourceUrl) async {
    final item = DownloadItem(
      movieId: movie.id,
      title: movie.title,
      posterUrl: movie.posterUrl,
      sourceUrl: sourceUrl,
      status: DownloadStatus.downloading,
    );
    _items[movie.id] = item;
    notifyListeners();
    await _persist();

    try {
      final path = await _downloadService.download(
        item: item,
        onProgress: (received, total) {
          item.downloadedBytes = received;
          item.totalBytes = total > 0 ? total : null;
          notifyListeners();
        },
      );
      item.localPath = path;
      item.status = DownloadStatus.downloaded;
      item.completedAt = DateTime.now();
    } on DownloadFailure {
      item.status = DownloadStatus.failed;
    } catch (_) {
      item.status = DownloadStatus.failed;
    }
    notifyListeners();
    await _persist();
  }

  /// Resumes a paused/failed/expired download by restarting it from the
  /// beginning against its originally-recorded source URL (this
  /// reference implementation does not persist partial-byte-range resume
  /// state; a production build could add HTTP Range support to Dio's
  /// download call for a true resume-from-offset).
  Future<void> resumeDownload(int movieId) async {
    final existing = _items[movieId];
    if (existing == null) return;
    existing.status = DownloadStatus.downloading;
    existing.downloadedBytes = 0;
    notifyListeners();
    await _persist();

    try {
      final path = await _downloadService.download(
        item: existing,
        onProgress: (received, total) {
          existing.downloadedBytes = received;
          existing.totalBytes = total > 0 ? total : null;
          notifyListeners();
        },
      );
      existing.localPath = path;
      existing.status = DownloadStatus.downloaded;
      existing.completedAt = DateTime.now();
    } on DownloadFailure {
      existing.status = DownloadStatus.failed;
    } catch (_) {
      existing.status = DownloadStatus.failed;
    }
    notifyListeners();
    await _persist();
  }

  /// Pauses an in-progress download, recording why (used for the
  /// automatic low-battery/no-Wi-Fi pause states in the spec).
  void pauseDownload(int movieId, {String reason = 'Paused by user'}) {
    final item = _items[movieId];
    if (item == null) return;
    _downloadService.cancel(movieId);
    item.status = DownloadStatus.paused;
    item.pauseReason = reason;
    notifyListeners();
    _persist();
  }

  Future<void> cancelDownload(int movieId) async {
    _downloadService.cancel(movieId);
    final item = _items.remove(movieId);
    if (item != null) {
      await _downloadService.deleteDownload(item.localPath);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteDownload(int movieId) async {
    final item = _items.remove(movieId);
    if (item != null) {
      await _downloadService.deleteDownload(item.localPath);
    }
    notifyListeners();
    await _persist();
  }

  /// Re-checks all "downloaded" items against disk (and, in a real DRM
  /// deployment, against license expiry) marking any that are missing as
  /// Expired rather than silently failing to play.
  Future<void> validateDownloads() async {
    for (final item in _items.values.where((i) => i.status == DownloadStatus.downloaded)) {
      final stillPresent = await _downloadService.isDownloadedOnDisk(item.localPath);
      if (!stillPresent) {
        item.status = DownloadStatus.expired;
      }
    }
    notifyListeners();
    await _persist();
  }
}
