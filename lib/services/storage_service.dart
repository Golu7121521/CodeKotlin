import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Provides aggregate storage statistics used on the Settings screen.
class StorageService {
  Future<int> getDirectorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {
            // Skip unreadable files.
          }
        }
      }
    } catch (_) {
      // Directory may not be accessible; return what we have so far.
    }
    return total;
  }

  Future<int> getAppCacheSize() async {
    final dir = await getTemporaryDirectory();
    return getDirectorySize(dir);
  }

  Future<Map<String, int>> getDiskStats() async {
    // Best-effort: Dart has no direct cross-platform disk stat API without
    // platform channels, so we report app-scoped sizes only, which is what
    // the Settings screen actually needs.
    return {
      'cache': await getAppCacheSize(),
    };
  }
}
