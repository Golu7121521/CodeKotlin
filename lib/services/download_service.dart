import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

enum DownloadStatus { idle, requesting, downloading, completed, failed }

class DownloadProgress {
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0
  final String? filePath;
  final String? errorMessage;

  DownloadProgress({
    required this.status,
    this.progress = 0.0,
    this.filePath,
    this.errorMessage,
  });
}

/// Handles downloading a song's audio file to the device's public
/// Downloads folder (Android) using path_provider + permission_handler + dio.
class DownloadService {
  final Dio _dio = Dio();

  /// Requests storage permission where required. On Android 13+ (API 33+)
  /// scoped storage means broad WRITE_EXTERNAL_STORAGE isn't needed for
  /// writing to the public Downloads directory via MediaStore-safe paths,
  /// but we still request on older APIs where it's required.
  Future<bool> _ensurePermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    return result.isGranted;
  }

  /// Returns the public Downloads directory on Android, or the app
  /// documents directory as a fallback on platforms without a public
  /// Downloads concept.
  Future<Directory> _resolveDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Standard public Downloads path on Android.
      final downloadsDir = Directory('/storage/emulated/0/Download/Synesthesia');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    }

    final dir = await getApplicationDocumentsDirectory();
    final synesthesiaDir = Directory('${dir.path}/Synesthesia');
    if (!await synesthesiaDir.exists()) {
      await synesthesiaDir.create(recursive: true);
    }
    return synesthesiaDir;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  /// Downloads the song's audio to the Downloads/Synesthesia folder.
  /// Emits progress via [onProgress] callback.
  Future<void> downloadSong(
    Song song, {
    required void Function(DownloadProgress) onProgress,
  }) async {
    if (!song.hasPlayableUrl) {
      onProgress(DownloadProgress(
        status: DownloadStatus.failed,
        errorMessage: 'This song has no downloadable audio.',
      ));
      return;
    }

    onProgress(DownloadProgress(status: DownloadStatus.requesting));

    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      onProgress(DownloadProgress(
        status: DownloadStatus.failed,
        errorMessage: 'Storage permission is required to download songs.',
      ));
      return;
    }

    try {
      final dir = await _resolveDownloadsDirectory();
      final fileName = '${_sanitizeFileName('${song.artist} - ${song.title}')}.m4a';
      final filePath = '${dir.path}/$fileName';

      onProgress(DownloadProgress(status: DownloadStatus.downloading, progress: 0));

      await _dio.download(
        song.mediaUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(DownloadProgress(
              status: DownloadStatus.downloading,
              progress: received / total,
            ));
          }
        },
      );

      onProgress(DownloadProgress(
        status: DownloadStatus.completed,
        progress: 1.0,
        filePath: filePath,
      ));
    } catch (e) {
      onProgress(DownloadProgress(
        status: DownloadStatus.failed,
        errorMessage: 'Download failed. Please try again.',
      ));
    }
  }
}
