import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/utils/url_validator.dart';

void main() {
  group('UrlValidator.isValid', () {
    test('accepts valid https URL', () {
      expect(UrlValidator.isValid('https://example.com/video.mp4'), isTrue);
    });

    test('accepts valid http URL', () {
      expect(UrlValidator.isValid('http://example.com/video.mp4'), isTrue);
    });

    test('rejects empty string', () {
      expect(UrlValidator.isValid(''), isFalse);
    });

    test('rejects whitespace-only string', () {
      expect(UrlValidator.isValid('   '), isFalse);
    });

    test('rejects non-http(s) scheme', () {
      expect(UrlValidator.isValid('ftp://example.com/video.mp4'), isFalse);
    });

    test('rejects malformed URL without host', () {
      expect(UrlValidator.isValid('https://'), isFalse);
    });

    test('rejects plain text', () {
      expect(UrlValidator.isValid('not a url'), isFalse);
    });

    test('rejects relative path', () {
      expect(UrlValidator.isValid('/videos/1.mp4'), isFalse);
    });
  });

  group('UrlValidator.normalize', () {
    test('trims surrounding whitespace on valid URL', () {
      expect(
        UrlValidator.normalize('  https://example.com/a.mp4  '),
        'https://example.com/a.mp4',
      );
    });

    test('returns null for invalid URL', () {
      expect(UrlValidator.normalize('not a url'), isNull);
    });
  });

  group('UrlValidator.buildApiUrl', () {
    test('percent-encodes the video URL as query parameter', () {
      final result = UrlValidator.buildApiUrl(
        'https://api.example.com/download?url=',
        'https://cdn.example.com/v.mp4?x=1&y=2',
      );
      expect(
        result,
        'https://api.example.com/download?url='
        '${Uri.encodeQueryComponent('https://cdn.example.com/v.mp4?x=1&y=2')}',
      );
      expect(result.contains('&y=2'), isFalse);
    });

    test('produces a URL parseable by Uri.parse', () {
      final result = UrlValidator.buildApiUrl(
        'https://api.example.com/download?url=',
        'https://cdn.example.com/video with spaces.mp4',
      );
      expect(Uri.tryParse(result), isNotNull);
    });
  });
}
