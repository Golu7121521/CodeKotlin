import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the design tokens (colors, typography, spacing) into a
/// single Material 3 [ThemeData]. MovieStream is a single-theme (always
/// dark, OLED-true-black) product by design — a "light mode" would break
/// the cinematic viewing philosophy — so there is deliberately no light
/// theme variant here.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: AppColors.bgBase,
      onSurface: AppColors.textPrimary,
      primary: AppColors.accentBrand,
      onPrimary: AppColors.textOnAccent,
      secondary: AppColors.accentSecondary,
      onSecondary: AppColors.textOnAccent,
      error: AppColors.error,
      onError: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.bgSurfaceElevatedHigh,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      fontFamily: AppTypography.fontFamily,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentBrand,
          foregroundColor: AppColors.textOnAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: AppTypography.labelLg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurfaceElevated,
        hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.accentBrand, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSurfaceElevated.withValues(alpha: 0.92),
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.accentBrandMuted,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBrand,
        linearTrackColor: AppColors.bgSurfaceElevatedHigh,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgSurfaceElevatedHigh,
        contentTextStyle: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSurfaceElevated,
        selectedColor: AppColors.accentBrand,
        labelStyle: AppTypography.labelSm,
        secondaryLabelStyle: AppTypography.labelSm.copyWith(color: AppColors.textOnAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),
    );
  }
}

/// Runtime performance mode used for the "Low-End Device Fallback" spec:
/// on detected low-end devices (or when the user opts in via Settings),
/// the app disables blur/glassmorphism effects, clamps animation
/// durations toward zero, and swaps shimmer loading effects for static
/// placeholders.
enum AppPerformanceMode { full, reduced }
