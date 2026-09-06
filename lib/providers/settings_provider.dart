import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// Exposes [AppSettings] to the widget tree and persists changes.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? service})
      : _service = service ?? SettingsService();

  final SettingsService _service;
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    _settings = await _service.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateThemeMode(AppThemeMode mode) async {
    _settings.themeMode = mode;
    notifyListeners();
    await _service.save(_settings);
  }

  Future<void> updateAskBeforeDownload(bool value) async {
    _settings.askBeforeDownload = value;
    notifyListeners();
    await _service.save(_settings);
  }

  Future<void> updateAutoCleanupTemp(bool value) async {
    _settings.autoCleanupTemp = value;
    notifyListeners();
    await _service.save(_settings);
  }

  Future<void> updatePlaybackSpeed(double value) async {
    _settings.defaultPlaybackSpeed = value;
    notifyListeners();
    await _service.save(_settings);
  }

  Future<void> updateAutoFullscreen(bool value) async {
    _settings.autoFullscreen = value;
    notifyListeners();
    await _service.save(_settings);
  }

  Future<void> updateRememberZoom(bool value) async {
    _settings.rememberZoom = value;
    notifyListeners();
    await _service.save(_settings);
  }

  Future<void> updateAutoHideControls(bool value) async {
    _settings.autoHideControls = value;
    notifyListeners();
    await _service.save(_settings);
  }
}
