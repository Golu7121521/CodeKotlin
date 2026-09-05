import 'dart:io';

/// Utility for producing safe, filesystem-valid filenames and handling
/// duplicate-name resolution.
class FilenameSanitizer {
  FilenameSanitizer._();

  static final RegExp _invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  /// Removes/replaces characters that are unsafe for filesystem use and
  /// trims to a reasonable max length.
  static String sanitize(String rawName) {
    var name = rawName.trim();
    if (name.isEmpty) {
      name = 'video';
    }

    name = name.replaceAll(_invalidChars, '_');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Avoid names that are only dots or empty after cleanup.
    if (name.replaceAll('.', '').trim().isEmpty) {
      name = 'video';
    }

    const maxLength = 100;
    if (name.length > maxLength) {
      name = name.substring(0, maxLength);
    }

    return name;
  }

  /// Splits a filename into base name and extension (extension includes
  /// the leading dot, or is empty string if none).
  static (String, String) splitExt(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == filename.length - 1) {
      return (filename, '');
    }
    return (filename.substring(0, dotIndex), filename.substring(dotIndex));
  }

  /// Given a desired filename and a directory, returns a filename that
  /// does not collide with an existing file, using "name (1).ext",
  /// "name (2).ext", etc.
  static String resolveUniqueName(String directory, String desiredFilename) {
    final sanitized = sanitize(desiredFilename);
    final (base, ext) = splitExt(sanitized);

    var candidate = sanitized;
    var counter = 1;
    while (File('$directory${Platform.pathSeparator}$candidate').existsSync()) {
      candidate = '$base ($counter)$ext';
      counter++;
    }
    return candidate;
  }

  /// Pure logic version of [resolveUniqueName] for testing without disk IO.
  /// [existingNames] is the set of filenames already present.
  static String resolveUniqueNameFromSet(
    Set<String> existingNames,
    String desiredFilename,
  ) {
    final sanitized = sanitize(desiredFilename);
    if (!existingNames.contains(sanitized)) return sanitized;

    final (base, ext) = splitExt(sanitized);
    var counter = 1;
    var candidate = '$base ($counter)$ext';
    while (existingNames.contains(candidate)) {
      counter++;
      candidate = '$base ($counter)$ext';
    }
    return candidate;
  }
}
