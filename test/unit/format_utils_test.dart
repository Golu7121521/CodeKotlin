import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/utils/format_utils.dart';

void main() {
  group('FormatUtils.formatBytes', () {
    test('formats zero as 0 B', () {
      expect(FormatUtils.formatBytes(0), '0 B');
    });

    test('formats null as 0 B', () {
      expect(FormatUtils.formatBytes(null), '0 B');
    });

    test('formats bytes under 1KB as B', () {
      expect(FormatUtils.formatBytes(512), '512 B');
    });

    test('formats kilobytes', () {
      expect(FormatUtils.formatBytes(2048), '2.0 KB');
    });

    test('formats megabytes', () {
      expect(FormatUtils.formatBytes(5 * 1024 * 1024), '5.0 MB');
    });

    test('formats gigabytes', () {
      expect(FormatUtils.formatBytes(2 * 1024 * 1024 * 1024), '2.0 GB');
    });
  });

  group('FormatUtils.formatDuration', () {
    test('formats seconds under a minute as mm:ss', () {
      expect(FormatUtils.formatDuration(const Duration(seconds: 45)), '00:45');
    });

    test('formats minutes and seconds', () {
      expect(FormatUtils.formatDuration(const Duration(minutes: 3, seconds: 5)), '03:05');
    });

    test('formats hours when present', () {
      expect(
        FormatUtils.formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });
  });

  group('FormatUtils.formatPercent', () {
    test('formats 0.5 as 50%', () {
      expect(FormatUtils.formatPercent(0.5), '50%');
    });

    test('clamps values above 1.0', () {
      expect(FormatUtils.formatPercent(1.5), '100%');
    });

    test('clamps negative values to 0', () {
      expect(FormatUtils.formatPercent(-0.2), '0%');
    });
  });

  group('FormatUtils.formatRemaining', () {
    test('formats sub-minute as seconds', () {
      expect(FormatUtils.formatRemaining(const Duration(seconds: 5)), '~5 sec');
    });

    test('formats sub-hour as minutes', () {
      expect(FormatUtils.formatRemaining(const Duration(minutes: 10)), '~10 min');
    });
  });
}
