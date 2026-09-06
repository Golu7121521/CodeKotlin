import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/filename_sanitizer.dart';

/// Reports progress for an in-flight download/preview fetch.
class DownloadProgress {
  final int downloadedBytes;
  final int? totalBytes;
  final double bytesPerSecond;

  const DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.bytesPerSecond,
  });

  double get fraction {
    if (totalBytes == null || totalBytes == 0) return 0.0;
    final f = downloadedBytes / totalBytes!;
    return f.isFinite ? f.clamp(0.0, 1.0) : 0.0;
  }
}

class DownloadFailure implements Exception {
  final String userMessage;
  final Object? cause;
  DownloadFailure(this.userMessage, [this.cause]);

  @override
  String toString() => 'DownloadFailure: $userMessage';
}

/// Handles fetching remote video bytes into the app's temporary cache
/// directory, and moving/copying completed temp files into permanent
/// app-scoped storage. Does not attempt to bypass any access restriction:
/// it only streams whatever bytes the provided authorized URL serves.
class DownloadService {
  DownloadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _connectTimeout = Duration(seconds: 30);

  /// Returns the app's temporary preview directory, creating it if needed.
  Future<Directory> getTempPreviewDir() async {
    final cacheDir = await getTemporaryDirectory();
    final previewDir = Directory(p.join(cacheDir.path, 'preview_cache'));
    if (!await previewDir.exists()) {
      await previewDir.create(recursive: true);
    }
    return previewDir;
  }

  /// Returns the app's permanent, app-scoped download directory
  /// (scoped external storage on Android; no special permission required
  /// for app-specific directories on modern Android versions).
  Future<Directory> getPermanentDownloadDir() async {
    Directory base;
    try {
      final dirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
      base = (dirs != null && dirs.isNotEmpty)
          ? dirs.first
          : await getApplicationDocumentsDirectory();
    } catch (_) {
      base = await getApplicationDocumentsDirectory();
    }
    final downloadDir = Directory(p.join(base.path, 'Downloads'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// Downloads [url] into the temporary preview directory, streaming to
  /// disk to avoid loading large videos fully into memory. Reports
  /// progress via [onProgress]. Returns the local temp file path.
  Future<String> downloadToTemp({
    required String url,
    required String suggestedFilename,
    void Function(DownloadProgress progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw DownloadFailure('This media format is not supported.');
    }

    final tempDir = await getTempPreviewDir();
    final safeName = FilenameSanitizer.sanitize(suggestedFilename);
    final tempFile = File(p.join(tempDir.path, safeName));

    late final http.StreamedResponse response;
    try {
      final request = http.Request('GET', uri);
      response = await _client.send(request).timeout(_connectTimeout);
    } on TimeoutException {
      throw DownloadFailure('Request timed out. Please try again.');
    } on SocketException {
      throw DownloadFailure('Internet connection unavailable.');
    } catch (e) {
      throw DownloadFailure('Unable to process this URL.', e);
    }

    if (response.statusCode != 200) {
      throw DownloadFailure('Video preview could not be loaded.');
    }

    final total = response.contentLength;
    var received = 0;
    final sink = tempFile.openWrite();
    final stopwatch = Stopwatch()..start();
    var lastReportedBytes = 0;
    var lastReportedTime = 0;

    try {
      await for (final chunk in response.stream) {
        if (cancelToken != null && cancelToken.isCancelled) {
          throw DownloadFailure('Download cancelled.');
        }
        sink.add(chunk);
        received += chunk.length;

        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (elapsedMs - lastReportedTime >= 200 || received == total) {
          final deltaBytes = received - lastReportedBytes;
          final deltaSec = (elapsedMs - lastReportedTime) / 1000.0;
          final speed = deltaSec > 0 ? deltaBytes / deltaSec : 0.0;
          onProgress?.call(DownloadProgress(
            downloadedBytes: received,
            totalBytes: total,
            bytesPerSecond: speed,
          ));
          lastReportedBytes = received;
          lastReportedTime = elapsedMs;
        }
      }
    } catch (e) {
      await sink.close();
      if (await tempFile.exists()) {
        await tempFile.delete().catchError((_) => tempFile);
      }
      if (e is DownloadFailure) rethrow;
      throw DownloadFailure('Video preview could not be loaded.', e);
    }

    await sink.flush();
    await sink.close();

    if (!await tempFile.exists() || await tempFile.length() == 0) {
      throw DownloadFailure('Video preview could not be loaded.');
    }

    return tempFile.path;
  }

  /// Moves an existing temp preview file to permanent storage, avoiding
  /// re-downloading. Handles filename collisions. Returns the new
  /// permanent file path.
  Future<String> moveTempToPermanent({
    required String tempFilePath,
    required String desiredFilename,
  }) async {
    final tempFile = File(tempFilePath);
    if (!await tempFile.exists()) {
      throw DownloadFailure('Not enough storage available.');
    }

    final permanentDir = await getPermanentDownloadDir();
    final uniqueName = FilenameSanitizer.resolveUniqueName(
      permanentDir.path,
      desiredFilename,
    );
    final destPath = p.join(permanentDir.path, uniqueName);

    try {
      final moved = await tempFile.rename(destPath);
      return moved.path;
    } on FileSystemException {
      // rename() can fail across filesystems/volumes; fall back to copy.
      try {
        final copied = await tempFile.copy(destPath);
        await tempFile.delete().catchError((_) => tempFile);
        return copied.path;
      } catch (e) {
        throw DownloadFailure('Not enough storage available.', e);
      }
    }
  }

  /// Deletes all files in the temp preview cache directory.
  Future<void> clearTempCache() async {
    final dir = await getTempPreviewDir();
    if (await dir.exists()) {
      final entries = await dir.list().toList();
      for (final entry in entries) {
        try {
          await entry.delete();
        } catch (_) {
          // Best-effort cleanup; ignore individual failures.
        }
      }
    }
  }

  /// Deletes temp files older than [maxAge]. Intended to run on app
  /// startup to clean up orphaned preview files from crashed sessions.
  Future<void> cleanupOrphanedTempFiles({Duration maxAge = const Duration(hours: 6)}) async {
    final dir = await getTempPreviewDir();
    if (!await dir.exists()) return;
    final cutoff = DateTime.now().subtract(maxAge);
    final entries = await dir.list().toList();
    for (final entry in entries) {
      try {
        final stat = await entry.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entry.delete();
        }
      } catch (_) {
        // Ignore individual failures.
      }
    }
  }

  Future<int> getTempCacheSizeBytes() async {
    final dir = await getTempPreviewDir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // Ignore unreadable entries.
        }
      }
    }
    return total;
  }

  void dispose() {
    _client.close();
  }
}

/// Simple cooperative cancellation token for in-progress downloads.
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
