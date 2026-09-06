enum AppThemeMode { system, light, dark }

AppThemeMode themeModeFromString(String value) {
  return AppThemeMode.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AppThemeMode.system,
  );
}

/// Holds user-configurable app settings, backed by SharedPreferences.
class AppSettings {
  AppThemeMode themeMode;
  bool askBeforeDownload;
  bool autoCleanupTemp;
  double defaultPlaybackSpeed;
  bool autoFullscreen;
  bool rememberZoom;
  bool autoHideControls;

  AppSettings({
    this.themeMode = AppThemeMode.system,
    this.askBeforeDownload = true,
    this.autoCleanupTemp = true,
    this.defaultPlaybackSpeed = 1.0,
    this.autoFullscreen = false,
    this.rememberZoom = false,
    this.autoHideControls = true,
  });
}
