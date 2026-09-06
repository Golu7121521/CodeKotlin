import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/utils/filename_sanitizer.dart';

void main() {
  group('FilenameSanitizer.sanitize', () {
    test('replaces invalid filesystem characters', () {
      final result = FilenameSanitizer.sanitize('video:name*with?bad<chars>.mp4');
      expect(result.contains(':'), isFalse);
      expect(result.contains('*'), isFalse);
      expect(result.contains('?'), isFalse);
      expect(result.contains('<'), isFalse);
      expect(result.contains('>'), isFalse);
    });

    test('falls back to "video" for empty input', () {
      expect(FilenameSanitizer.sanitize(''), 'video');
    });

    test('falls back to "video" for whitespace-only input', () {
      expect(FilenameSanitizer.sanitize('   '), 'video');
    });

    test('collapses repeated whitespace', () {
      expect(FilenameSanitizer.sanitize('my   video   file.mp4'), 'my video file.mp4');
    });

    test('preserves valid extension', () {
      expect(FilenameSanitizer.sanitize('clip.mp4'), 'clip.mp4');
    });

    test('truncates excessively long names', () {
      final longName = '${'a' * 200}.mp4';
      final result = FilenameSanitizer.sanitize(longName);
      expect(result.length, lessThanOrEqualTo(100));
    });
  });

  group('FilenameSanitizer.splitExt', () {
    test('splits base name and extension', () {
      final (base, ext) = FilenameSanitizer.splitExt('video.mp4');
      expect(base, 'video');
      expect(ext, '.mp4');
    });

    test('returns empty extension when none present', () {
      final (base, ext) = FilenameSanitizer.splitExt('video');
      expect(base, 'video');
      expect(ext, '');
    });

    test('handles leading dot (hidden file) without treating as extension', () {
      final (base, ext) = FilenameSanitizer.splitExt('.hidden');
      expect(base, '.hidden');
      expect(ext, '');
    });
  });

  group('FilenameSanitizer.resolveUniqueNameFromSet', () {
    test('returns sanitized name unchanged when no collision', () {
      final result = FilenameSanitizer.resolveUniqueNameFromSet({}, 'video.mp4');
      expect(result, 'video.mp4');
    });

    test('appends (1) on first collision', () {
      final result = FilenameSanitizer.resolveUniqueNameFromSet(
        {'video.mp4'},
        'video.mp4',
      );
      expect(result, 'video (1).mp4');
    });

    test('increments counter for repeated collisions', () {
      final result = FilenameSanitizer.resolveUniqueNameFromSet(
        {'video.mp4', 'video (1).mp4', 'video (2).mp4'},
        'video.mp4',
      );
      expect(result, 'video (3).mp4');
    });
  });
}
