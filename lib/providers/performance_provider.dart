import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Drives the "Low-End Device Fallback" UI mode. In `auto` (the default),
/// [effectiveMode] degrades to [AppPerformanceMode.reduced] whenever
/// [reportLowEndSignal] has been called (e.g. after detecting a slow
/// device via a jank/frame-time heuristic at startup); the user can also
/// force reduced mode from Settings regardless of device capability.
class PerformanceProvider extends ChangeNotifier {
  PerformanceProvider({StorageService? storageService})
      : _storage = storageService ?? StorageService();

  final StorageService _storage;

  AppPerformanceModePref _userPreference = AppPerformanceModePref.auto;
  bool _lowEndSignalDetected = false;

  AppPerformanceModePref get userPreference => _userPreference;

  AppPerformanceMode get effectiveMode {
    if (_userPreference == AppPerformanceModePref.reduced || _lowEndSignalDetected) {
      return AppPerformanceMode.reduced;
    }
    return AppPerformanceMode.full;
  }

  Future<void> load() async {
    _userPreference = await _storage.getPerformanceMode();
    notifyListeners();
  }

  Future<void> setUserPreference(AppPerformanceModePref pref) async {
    _userPreference = pref;
    await _storage.setPerformanceMode(pref);
    notifyListeners();
  }

  /// Called after a lightweight startup heuristic (e.g. measuring first-
  /// frame build time, or checking Android API level / RAM via
  /// device_info_plus) determines the device is low-end.
  void reportLowEndSignal(bool isLowEnd) {
    if (_lowEndSignalDetected == isLowEnd) return;
    _lowEndSignalDetected = isLowEnd;
    notifyListeners();
  }
}
