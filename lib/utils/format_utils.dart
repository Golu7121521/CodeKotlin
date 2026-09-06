/// Human-readable formatting helpers for sizes, durations and speeds.
class FormatUtils {
  FormatUtils._();

  static String formatBytes(int? bytes, {int decimals = 1}) {
    if (bytes == null || bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : decimals)} ${units[unitIndex]}';
  }

  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${formatBytes(bytesPerSecond.round())}/s';
  }

  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatRemaining(Duration d) {
    if (d.inSeconds <= 0) return '~0 sec';
    if (d.inSeconds < 60) return '~${d.inSeconds} sec';
    if (d.inMinutes < 60) return '~${d.inMinutes} min';
    return '~${d.inHours} hr';
  }

  static String formatPercent(double progress) {
    return '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';
  }
}
