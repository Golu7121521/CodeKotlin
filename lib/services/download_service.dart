import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/download_item_model.dart';

class DownloadFailure implements Exception {
  final String message;
  DownloadFailure(this.message);
  @override
  String toString() => 'DownloadFailure: $message';
}

/// Handles saving a resolved stream URL to local storage for offline
/// playback, with progress monitoring and cancellation support. Uses Dio
/// for its built-in download progress callbacks and cancel tokens.
class DownloadService {
  DownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<int, CancelToken> _cancelTokens = {};

  Future<Directory> getDownloadsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Starts (or resumes) a download for [item], reporting progress via
  /// [onProgress]. Only supports direct-file formats (mp4) — HLS/DASH
  /// sources are streamed live rather than downloaded in this reference
  /// implementation, since offline HLS requires manifest+segment
  /// management beyond a single file download.
  Future<String> download({
    required DownloadItem item,
    required void Function(int received, int total) onProgress,
  }) async {
    final dir = await getDownloadsDirectory();
    final safeName = 'movie_${item.movieId}.mp4';
    final destPath = '${dir.path}/$safeName';

    final cancelToken = CancelToken();
    _cancelTokens[item.movieId] = cancelToken;

    try {
      await _dio.download(
        item.sourceUrl,
        destPath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );
      return destPath;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw DownloadFailure('Download cancelled.');
      }
      throw DownloadFailure('Download failed: ${e.message ?? 'network error'}');
    } finally {
      _cancelTokens.remove(item.movieId);
    }
  }

  void cancel(int movieId) {
    _cancelTokens[movieId]?.cancel('User cancelled');
  }

  /// Checks whether a movie's file is present on disk (used to validate
  /// the Downloaded state hasn't gone stale, e.g. after the OS clears
  /// app storage).
  Future<bool> isDownloadedOnDisk(String localPath) async {
    if (localPath.isEmpty) return false;
    return File(localPath).exists();
  }

  Future<void> deleteDownload(String localPath) async {
    if (localPath.isEmpty) return;
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<int> getDownloadedFileSize(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) return 0;
    return file.length();
  }
}
