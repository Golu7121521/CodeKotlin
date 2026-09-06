import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/models/api_response.dart';

void main() {
  group('ApiVideoResponse.fromJson', () {
    test('parses a valid minimal response', () {
      final response = ApiVideoResponse.fromJson({
        'download_url': 'https://example.com/video.mp4',
      });
      expect(response.downloadUrl, 'https://example.com/video.mp4');
      expect(response.title, isNull);
    });

    test('parses a full response with optional fields', () {
      final response = ApiVideoResponse.fromJson({
        'download_url': 'https://example.com/video.mp4',
        'title': 'My Video',
        'file_size': 1048576,
        'duration_ms': 60000,
        'thumbnail': 'https://example.com/thumb.jpg',
      });
      expect(response.title, 'My Video');
      expect(response.fileSizeBytes, 1048576);
      expect(response.durationMs, 60000);
      expect(response.thumbnailUrl, 'https://example.com/thumb.jpg');
    });

    test('throws FormatException when download_url is missing', () {
      expect(
        () => ApiVideoResponse.fromJson({'title': 'No URL here'}),
        throwsFormatException,
      );
    });

    test('throws FormatException when download_url is empty', () {
      expect(
        () => ApiVideoResponse.fromJson({'download_url': ''}),
        throwsFormatException,
      );
    });

    test('throws FormatException when download_url is not a string', () {
      expect(
        () => ApiVideoResponse.fromJson({'download_url': 12345}),
        throwsFormatException,
      );
    });

    test('throws FormatException when download_url is not absolute http(s)', () {
      expect(
        () => ApiVideoResponse.fromJson({'download_url': 'not-a-url'}),
        throwsFormatException,
      );
    });

    test('throws FormatException for non-http(s) scheme', () {
      expect(
        () => ApiVideoResponse.fromJson({'download_url': 'ftp://example.com/v.mp4'}),
        throwsFormatException,
      );
    });

    test('parses file_size given as a string', () {
      final response = ApiVideoResponse.fromJson({
        'download_url': 'https://example.com/video.mp4',
        'file_size': '2048',
      });
      expect(response.fileSizeBytes, 2048);
    });

    test('gracefully ignores unparseable optional numeric fields', () {
      final response = ApiVideoResponse.fromJson({
        'download_url': 'https://example.com/video.mp4',
        'file_size': 'not-a-number',
      });
      expect(response.fileSizeBytes, isNull);
    });
  });
}
