import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/download_item.dart';
import '../services/download_service.dart';

/// Central store for all download/history items. Backed by [AppDatabase]
/// for persistence and [DownloadService] for the actual file operations.
class DownloadsProvider extends ChangeNotifier {
  DownloadsProvider({
    AppDatabase? database,
    DownloadService? downloadService,
  })  : _db = database ?? AppDatabase.instance,
        _downloadService = downloadService ?? DownloadService();

  final AppDatabase _db;
  final DownloadService _downloadService;
  final _uuid = const Uuid();

  final Map<String, DownloadItem> _items = {};
  final Map<String, CancelToken> _cancelTokens = {};

  List<DownloadItem> get all =>
      _items.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<DownloadItem> get active => all
      .where((i) =>
          i.status == DownloadStatus.downloading ||
          i.status == DownloadStatus.connecting ||
          i.status == DownloadStatus.preparing ||
          i.status == DownloadStatus.paused)
      .toList();

  List<DownloadItem> get completed =>
      all.where((i) => i.status == DownloadStatus.completed).toList();

  List<DownloadItem> get failed => all
      .where((i) =>
          i.status == DownloadStatus.failed || i.status == DownloadStatus.cancelled)
      .toList();

  Future<void> loadFromDatabase() async {
    try {
      final items = await _db.getAll();
      _items.clear();
      for (final item in items) {
        _items[item.id] = item;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load download history: $e');
    }
  }

  DownloadItem createPendingItem({
    required String sourceUrl,
    required String downloadUrl,
    required String filename,
  }) {
    final item = DownloadItem(
      id: _uuid.v4(),
      url: sourceUrl,
      downloadUrl: downloadUrl,
      filename: filename,
      status: DownloadStatus.preparing,
    );
    _items[item.id] = item;
    notifyListeners();
    return item;
  }

  void updateItem(DownloadItem item) {
    _items[item.id] = item;
    notifyListeners();
    // Persist asynchronously; failures are logged, not surfaced, since
    // this is a best-effort cache of state already held in memory.
    _db.insertOrUpdate(item).catchError((e) {
      debugPrint('Failed to persist download item: $e');
    });
  }

  DownloadItem? getById(String id) => _items[id];

  CancelToken registerCancelToken(String id) {
    final token = CancelToken();
    _cancelTokens[id] = token;
    return token;
  }

  void cancelDownload(String id) {
    _cancelTokens[id]?.cancel();
    final item = _items[id];
    if (item != null) {
      updateItem(item.copyWith(status: DownloadStatus.cancelled));
    }
  }

  Future<void> deleteItem(String id, {bool deleteFile = false}) async {
    final item = _items[id];
    if (deleteFile && item?.localPath != null) {
      try {
        final file = File(item!.localPath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('Failed to delete file: $e');
      }
    }
    _items.remove(id);
    notifyListeners();
    try {
      await _db.delete(id);
    } catch (e) {
      debugPrint('Failed to delete history entry: $e');
    }
  }

  Future<void> clearHistory() async {
    _items.clear();
    notifyListeners();
    try {
      await _db.deleteAll();
    } catch (e) {
      debugPrint('Failed to clear history: $e');
    }
  }

  Future<List<DownloadItem>> search(String query) async {
    if (query.trim().isEmpty) return all;
    try {
      return await _db.search(query.trim());
    } catch (e) {
      debugPrint('Search failed: $e');
      return all
          .where((i) =>
              i.filename.toLowerCase().contains(query.toLowerCase()) ||
              (i.title?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              i.url.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
