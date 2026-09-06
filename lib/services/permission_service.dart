import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Centralizes runtime permission requests, requested only when actually
/// needed (not on app launch) and following scoped-storage rules on
/// modern Android where app-specific directories require no permission.
class PermissionService {
  /// Requests notification permission (used for showing download
  /// progress/completion notifications on Android 13+). Safe to call
  /// even if not required on older versions.
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    return Permission.notification.status.isGranted;
  }
}
