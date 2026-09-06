import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/models/download_item.dart';

void main() {
  DownloadItem buildItem({
    DownloadStatus status = DownloadStatus.preparing,
    int? fileSizeBytes,
    int? downloadedBytes,
  }) {
    return DownloadItem(
      id: 'test-id',
      url: 'https://example.com/source',
      downloadUrl: 'https://example.com/video.mp4',
      filename: 'video.mp4',
      status: status,
      fileSizeBytes: fileSizeBytes,
      downloadedBytes: downloadedBytes,
    );
  }

  group('DownloadItem.progress', () {
    test('returns 0.0 when fileSizeBytes is null', () {
      final item = buildItem(downloadedBytes: 50);
      expect(item.progress, 0.0);
    });

    test('returns 0.0 when fileSizeBytes is zero', () {
      final item = buildItem(fileSizeBytes: 0, downloadedBytes: 50);
      expect(item.progress, 0.0);
    });

    test('computes correct fraction', () {
      final item = buildItem(fileSizeBytes: 200, downloadedBytes: 50);
      expect(item.progress, 0.25);
    });

    test('clamps progress to 1.0 max', () {
      final item = buildItem(fileSizeBytes: 100, downloadedBytes: 150);
      expect(item.progress, 1.0);
    });

    test('treats null downloadedBytes as zero', () {
      final item = buildItem(fileSizeBytes: 100);
      expect(item.progress, 0.0);
    });
  });

  group('DownloadItem.toMap / fromMap round-trip', () {
    test('preserves all fields through serialization', () {
      final original = DownloadItem(
        id: 'abc123',
        url: 'https://example.com/source',
        downloadUrl: 'https://example.com/video.mp4',
        filename: 'my video.mp4',
        localPath: '/tmp/my video.mp4',
        thumbnailPath: null,
        fileSizeBytes: 1000,
        downloadedBytes: 500,
        durationMs: 12000,
        title: 'My Video',
        status: DownloadStatus.downloading,
      );

      final restored = DownloadItem.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.url, original.url);
      expect(restored.downloadUrl, original.downloadUrl);
      expect(restored.filename, original.filename);
      expect(restored.localPath, original.localPath);
      expect(restored.fileSizeBytes, original.fileSizeBytes);
      expect(restored.downloadedBytes, original.downloadedBytes);
      expect(restored.durationMs, original.durationMs);
      expect(restored.title, original.title);
      expect(restored.status, original.status);
    });

    test('falls back to failed status for unknown status string', () {
      final item = buildItem();
      final map = item.toMap();
      map['status'] = 'some_unknown_status';
      final restored = DownloadItem.fromMap(map);
      expect(restored.status, DownloadStatus.failed);
    });
  });

  group('DownloadItem.copyWith', () {
    test('overrides only specified fields', () {
      final original = buildItem(status: DownloadStatus.preparing);
      final updated = original.copyWith(status: DownloadStatus.completed);

      expect(updated.status, DownloadStatus.completed);
      expect(updated.id, original.id);
      expect(updated.filename, original.filename);
    });
  });
}
