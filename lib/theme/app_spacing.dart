/// Spacing tokens built on a strict 8pt base grid. Every value in the app
/// — padding, gaps, margins — should trace back to one of these tokens so
/// the whole UI shares one consistent rhythm.
class AppSpacing {
  AppSpacing._();

  static const double none = 0;
  static const double xxs = 2; // Hairline adjustments only
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double xxxxxl = 48;
  static const double xxxxxxl = 64;

  /// Radius tokens, following the same halved-step logic as spacing.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  /// Safe-area insets beyond the platform-reported safe area, added for
  /// comfortable thumb reach and to keep content clear of camera cutouts
  /// even on devices that under-report their safe inset.
  static const double safeAreaExtraTop = 8;
  static const double safeAreaExtraBottom = 8;

  /// TV overscan margin — broadcast content traditionally keeps a 5-10%
  /// margin free of the screen edge since many TVs crop the outer edge of
  /// the signal. We use a fixed 48px title-safe margin on 1920-width
  /// canvases (2.5%), which is conservative enough for modern TVs while
  /// not wasting excessive space on screens with accurate overscan.
  static const double tvOverscanMargin = 48;
}
