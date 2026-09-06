import 'package:flutter_test/flutter_test.dart';
import 'package:movie_stream/models/download_item_model.dart';

void main() {
  group('DownloadItem.progress', () {
    test('returns 0.0 when totalBytes is null', () {
      final item = DownloadItem(
        movieId: 1,
        title: 'Test',
        sourceUrl: 'https://example.com/v.mp4',
        downloadedBytes: 50,
      );
      expect(item.progress, 0.0);
    });

    test('computes correct fraction', () {
      final item = DownloadItem(
        movieId: 1,
        title: 'Test',
        sourceUrl: 'https://example.com/v.mp4',
        downloadedBytes: 50,
        totalBytes: 200,
      );
      expect(item.progress, 0.25);
    });

    test('clamps progress to 1.0', () {
      final item = DownloadItem(
        movieId: 1,
        title: 'Test',
        sourceUrl: 'https://example.com/v.mp4',
        downloadedBytes: 300,
        totalBytes: 200,
      );
      expect(item.progress, 1.0);
    });
  });

  group('DownloadItem JSON round-trip', () {
    test('preserves all fields through serialization', () {
      final original = DownloadItem(
        movieId: 42,
        title: 'My Movie',
        posterUrl: 'https://example.com/poster.jpg',
        sourceUrl: 'https://example.com/v.mp4',
        localPath: '/tmp/movie_42.mp4',
        status: DownloadStatus.downloading,
        downloadedBytes: 1000,
        totalBytes: 2000,
      );

      final restored = DownloadItem.fromJson(original.toJson());

      expect(restored.movieId, original.movieId);
      expect(restored.title, original.title);
      expect(restored.sourceUrl, original.sourceUrl);
      expect(restored.status, original.status);
      expect(restored.downloadedBytes, original.downloadedBytes);
      expect(restored.totalBytes, original.totalBytes);
    });

    test('falls back to failed status for unknown status string', () {
      final item = DownloadItem(
        movieId: 1,
        title: 'Test',
        sourceUrl: 'https://example.com/v.mp4',
      );
      final json = item.toJson();
      json['status'] = 'some_unknown_status';
      final restored = DownloadItem.fromJson(json);
      expect(restored.status, DownloadStatus.failed);
    });
  });
}
