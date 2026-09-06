import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Signature "Synesthesia" palette: electric violet -> magenta -> cyan,
/// carried over from the native Android build, now expressed for both
/// dark and light Material themes.
class AppColors {
  static const Color accentViolet = Color(0xFF7C3AFF);
  static const Color accentVioletDark = Color(0xFF4C1D9E);
  static const Color accentMagenta = Color(0xFFFF3D9A);
  static const Color accentCyan = Color(0xFF22E5FF);

  // Dark theme surfaces
  static const Color darkBgPrimary = Color(0xFF07060D);
  static const Color darkBgSecondary = Color(0xFF0E0C1A);
  static const Color darkSurfaceCard = Color(0xFF17142A);
  static const Color darkSurfaceElevated = Color(0xFF201B38);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB4ACD1);
  static const Color darkTextTertiary = Color(0xFF6E6690);
  static const Color darkStroke = Color(0xFF2A2447);

  // Light theme surfaces
  static const Color lightBgPrimary = Color(0xFFF7F5FB);
  static const Color lightBgSecondary = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0EDF7);
  static const Color lightTextPrimary = Color(0xFF1A1625);
  static const Color lightTextSecondary = Color(0xFF6B647F);
  static const Color lightTextTertiary = Color(0xFF9992AC);
  static const Color lightStroke = Color(0xFFE4DFF0);

  static const Color successGreen = Color(0xFF2EE6A6);
  static const Color errorRed = Color(0xFFFF5C7A);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentVioletDark, accentViolet, accentMagenta],
  );

  static const LinearGradient playButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentViolet, accentMagenta, accentCyan],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBgPrimary,
      primaryColor: AppColors.accentViolet,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accentViolet,
        secondary: AppColors.accentMagenta,
        surface: AppColors.darkSurfaceCard,
        error: AppColors.errorRed,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: null,
      ),
      cardColor: AppColors.darkSurfaceCard,
      dividerColor: AppColors.darkStroke,
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBgSecondary,
        selectedItemColor: AppColors.accentViolet,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentViolet,
        inactiveTrackColor: AppColors.darkSurfaceElevated,
        thumbColor: AppColors.accentMagenta,
        overlayColor: AppColors.accentViolet.withOpacity(0.2),
        trackHeight: 3,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBgPrimary,
      primaryColor: AppColors.accentViolet,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accentViolet,
        secondary: AppColors.accentMagenta,
        surface: AppColors.lightSurfaceCard,
        error: AppColors.errorRed,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: null,
      ),
      cardColor: AppColors.lightSurfaceCard,
      dividerColor: AppColors.lightStroke,
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBgSecondary,
        selectedItemColor: AppColors.accentViolet,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentViolet,
        inactiveTrackColor: AppColors.lightSurfaceElevated,
        thumbColor: AppColors.accentMagenta,
        overlayColor: AppColors.accentViolet.withOpacity(0.15),
        trackHeight: 3,
      ),
    );
  }
}

/// Theme-aware color accessor so widgets don't need to branch on
/// Theme.of(context).brightness everywhere.
class AppColorsX {
  final BuildContext context;
  AppColorsX(this.context);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bgPrimary => _isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
  Color get bgSecondary => _isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary;
  Color get surfaceCard => _isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard;
  Color get surfaceElevated =>
      _isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
  Color get textPrimary => _isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      _isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textTertiary => _isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  Color get stroke => _isDark ? AppColors.darkStroke : AppColors.lightStroke;
}

extension AppColorsExtension on BuildContext {
  AppColorsX get colors => AppColorsX(this);
}
