import 'package:flutter/material.dart';

/// Typographic scale for MovieStream, built on a 1.25 "Major Third"
/// modular ratio from a 16px base. Each step's font size is the previous
/// step multiplied by 1.25, then rounded to the nearest even pixel for
/// crisp sub-pixel rendering.
///
/// Line-height is expressed as an absolute px value (not a multiplier)
/// per design-token convention, chosen so multi-line paragraphs keep a
/// consistent vertical rhythm on the 8pt grid (see AppSpacing).
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  // ---------------------------------------------------------------------
  // Scale: base 16px × 1.25^n
  // xs   12.8 -> 13px
  // sm   16px  (base)
  // md   20px
  // lg   25px
  // xl   31px -> 32px
  // 2xl  39px -> 40px
  // 3xl  49px -> 48px  (clamped for display sanity)
  // 4xl  61px -> 60px
  // ---------------------------------------------------------------------

  static const TextStyle displayXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: 60,
    height: 68 / 60,
    letterSpacing: -0.02 * 60,
    fontWeight: FontWeight.w800,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -0.02 * 48,
    fontWeight: FontWeight.w800,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle headlineXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 48 / 40,
    letterSpacing: -0.015 * 40,
    fontWeight: FontWeight.w700,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
    fontWeight: FontWeight.w700,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 25,
    height: 32 / 25,
    letterSpacing: -0.01 * 25,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 24 / 17,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: Color(0xB3FFFFFF),
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: Color(0xB3FFFFFF),
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: 0.01 * 13,
    fontWeight: FontWeight.w400,
    color: Color(0x73FFFFFF),
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 0.02 * 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.03 * 12,
    fontWeight: FontWeight.w600,
    color: Color(0xB3FFFFFF),
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.02 * 11,
    fontWeight: FontWeight.w500,
    color: Color(0x73FFFFFF),
  );

  /// Scales a base text style for the current form factor. Mobile uses
  /// the scale as authored; tablets step up one tier for headline+ styles
  /// to preserve visual weight on larger canvases; TV (10-foot UI) scales
  /// everything up ~1.6x plus increases letter-spacing slightly, since
  /// viewing distance shrinks apparent size.
  static TextStyle responsive(TextStyle base, double screenWidth) {
    if (screenWidth >= 1920) {
      // TV / 10-foot UI
      return base.copyWith(
        fontSize: (base.fontSize ?? 16) * 1.6,
        letterSpacing: (base.letterSpacing ?? 0) * 1.2,
      );
    } else if (screenWidth >= 768) {
      // Tablet
      return base.copyWith(fontSize: (base.fontSize ?? 16) * 1.15);
    }
    return base; // Mobile: authored scale
  }
}
