import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Persists [AppSettings] to SharedPreferences.
class SettingsService {
  static const _keyThemeMode = 'settings.themeMode';
  static const _keyAskBeforeDownload = 'settings.askBeforeDownload';
  static const _keyAutoCleanupTemp = 'settings.autoCleanupTemp';
  static const _keyPlaybackSpeed = 'settings.playbackSpeed';
  static const _keyAutoFullscreen = 'settings.autoFullscreen';
  static const _keyRememberZoom = 'settings.rememberZoom';
  static const _keyAutoHideControls = 'settings.autoHideControls';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      themeMode: themeModeFromString(prefs.getString(_keyThemeMode) ?? 'system'),
      askBeforeDownload: prefs.getBool(_keyAskBeforeDownload) ?? true,
      autoCleanupTemp: prefs.getBool(_keyAutoCleanupTemp) ?? true,
      defaultPlaybackSpeed: prefs.getDouble(_keyPlaybackSpeed) ?? 1.0,
      autoFullscreen: prefs.getBool(_keyAutoFullscreen) ?? false,
      rememberZoom: prefs.getBool(_keyRememberZoom) ?? false,
      autoHideControls: prefs.getBool(_keyAutoHideControls) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, settings.themeMode.name);
    await prefs.setBool(_keyAskBeforeDownload, settings.askBeforeDownload);
    await prefs.setBool(_keyAutoCleanupTemp, settings.autoCleanupTemp);
    await prefs.setDouble(_keyPlaybackSpeed, settings.defaultPlaybackSpeed);
    await prefs.setBool(_keyAutoFullscreen, settings.autoFullscreen);
    await prefs.setBool(_keyRememberZoom, settings.rememberZoom);
    await prefs.setBool(_keyAutoHideControls, settings.autoHideControls);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('settings.onboardingComplete') ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings.onboardingComplete', true);
  }
}
