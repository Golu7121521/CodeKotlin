import 'package:flutter/material.dart';

/// Central place for sizing so every toolbar / icon / button stays small
/// and consistent across the app (per design requirement: compact UI).
class AppSizes {
  static const double toolbarIcon = 18.0;
  static const double toolbarHeight = 40.0;
  static const double tabIcon = 16.0;
  static const double tabHeight = 34.0;
  static const double smallButton = 30.0;
  static const double fontEditor = 13.0;
  static const double fontTerminal = 12.5;
  static const double radius = 8.0;
}

class AppTheme {
  static ThemeData dark() {
    const bg = Color(0xFF1E1E1E);
    const surface = Color(0xFF252526);
    const accent = Color(0xFF4FC3F7);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        toolbarHeight: AppSizes.toolbarHeight,
        titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(size: AppSizes.toolbarIcon),
      ),
      iconTheme: const IconThemeData(size: AppSizes.toolbarIcon),
      visualDensity: VisualDensity.compact,
      dividerColor: Colors.white12,
      fontFamily: 'monospace',
      useMaterial3: true,
    );
  }
}
