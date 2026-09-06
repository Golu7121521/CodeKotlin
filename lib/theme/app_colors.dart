import 'package:flutter/material.dart';

/// Semantic color tokens for the MovieStream design system.
///
/// Philosophy: "OLED-True Black" — the base surface is pure black (#000000)
/// so OLED panels turn those pixels fully off, saving battery and giving
/// maximum contrast for poster art. Depth is created not with drop shadows
/// (which look muddy on true black) but with extremely subtle *lightness*
/// steps between elevation layers — each level up is a small, flat
/// brightness increment rather than a shadow, closer to how frosted glass
/// panes stack than how paper does.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Base surfaces — each elevation step is a ~3-4% lightness increment.
  // No shadows are used at elevation 0-2; a hairline border stands in for
  // depth instead, since shadows read as "dirty" on true black.
  // ---------------------------------------------------------------------
  static const Color bgBase = Color(0xFF000000); // True black canvas
  static const Color bgSurface = Color(0xFF0A0A0C); // Cards, rows
  static const Color bgSurfaceElevated = Color(0xFF141417); // Modals, sheets
  static const Color bgSurfaceElevatedHigh = Color(0xFF1C1C20); // Popovers, menus
  static const Color bgSurfaceOverlay = Color(0xCC000000); // Scrim, 80% black

  // Hairline borders used in place of shadows at low elevations.
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white
  static const Color borderDefault = Color(0x1FFFFFFF); // 12% white
  static const Color borderStrong = Color(0x33FFFFFF); // 20% white

  // ---------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textTertiary = Color(0x73FFFFFF); // 45% white
  static const Color textDisabled = Color(0x40FFFFFF); // 25% white
  static const Color textOnAccent = Color(0xFF0A0000);

  // ---------------------------------------------------------------------
  // Brand accent — a warm cinematic red, close to the classic "marquee"
  // red used by major studios, chosen for strong contrast against black
  // and instant recognizability as the primary call-to-action color.
  // ---------------------------------------------------------------------
  static const Color accentBrand = Color(0xFFE50914);
  static const Color accentBrandHover = Color(0xFFF6121D);
  static const Color accentBrandPressed = Color(0xFFB80710);
  static const Color accentBrandMuted = Color(0x26E50914); // 15% for tints

  // Secondary accent — a cool cyan used sparingly for "new"/"live" badges
  // and secondary interactive elements, chosen to sit at high contrast
  // against the brand red without competing for attention.
  static const Color accentSecondary = Color(0xFF00D9FF);
  static const Color accentSecondaryMuted = Color(0x2600D9FF);

  // Gold used exclusively for ratings/premium badges (4K, Dolby Atmos).
  static const Color accentGold = Color(0xFFE6B325);

  // ---------------------------------------------------------------------
  // Semantic states
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF2ECC71);
  static const Color successMuted = Color(0x262ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningMuted = Color(0x26F5A623);
  static const Color error = Color(0xFFFF453A);
  static const Color errorMuted = Color(0x26FF453A);
  static const Color info = Color(0xFF0A84FF);
  static const Color infoMuted = Color(0x260A84FF);

  // ---------------------------------------------------------------------
  // Gradients — used for hero banner scrims and card overlays. Angles are
  // shallow (values below are expressed as begin/end Alignment, which for
  // a near-vertical wash approximates a 2° tilt via a slight horizontal
  // component) to avoid a mechanical, perfectly-vertical look.
  // ---------------------------------------------------------------------
  static const List<Color> heroScrimColors = [
    Color(0x00000000), // transparent at top
    Color(0x00000000),
    Color(0xCC000000), // 80% black at bottom
    Color(0xFF000000),
  ];
  static const List<double> heroScrimStops = [0.0, 0.4, 0.85, 1.0];

  static const List<Color> cardHoverGlow = [
    Color(0x00E50914),
    Color(0x1AE50914), // 10% brand red
  ];
}
