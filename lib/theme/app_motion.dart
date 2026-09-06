import 'package:flutter/animation.dart';

/// Motion tokens defining the exact easing curves and durations used
/// throughout MovieStream. Every animation in the app should reference
/// one of these rather than inventing a bespoke curve/duration, so the
/// whole product feels like it has one consistent physical "weight".
class AppMotion {
  AppMotion._();

  // ---------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------

  /// Standard curve for most UI transitions (page slides, fades, expands).
  /// Cubic-bezier(0.25, 0.1, 0.25, 1.0) — an "ease-out"-dominant curve:
  /// quick acceleration, long gentle deceleration, so motion feels
  /// responsive to start but never abrupt at the end.
  static const Curve standard = Cubic(0.25, 0.1, 0.25, 1.0);

  /// Spring/bounce curve for playful confirmations (add-to-list checkmark,
  /// download-complete pop). Cubic-bezier(0.175, 0.885, 0.32, 1.275) —
  /// the >1.0 endpoint produces a small overshoot before settling.
  static const Curve spring = Cubic(0.175, 0.885, 0.32, 1.275);

  /// Emphasized deceleration for large, "hero" transitions (poster to
  /// backdrop morph). Cubic-bezier(0.05, 0.7, 0.1, 1.0) — near-linear
  /// start with a long emphasized deceleration tail.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Sharp acceleration for elements leaving the screen (dismissals).
  /// Cubic-bezier(0.3, 0.0, 0.8, 0.15).
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Linear — used only for continuous/looping motion (shimmer sweep,
  /// buffering spinner) where easing would look like stuttering.
  static const Curve linear = Curves.linear;

  // ---------------------------------------------------------------------
  // Durations (ms) — three tiers matching motion scale.
  // ---------------------------------------------------------------------

  /// Micro-interactions: button press scale, icon toggle, ripple.
  static const Duration micro = Duration(milliseconds: 100);

  /// Small: chip select, switch toggle, tooltip appear.
  static const Duration small = Duration(milliseconds: 150);

  /// Medium: page slide transitions, card expand, sheet present.
  static const Duration medium = Duration(milliseconds: 300);

  /// Macro: hero image morph, shared-element transition, full-screen
  /// player open/close.
  static const Duration macro = Duration(milliseconds: 450);

  /// Ambient/looping: shimmer sweep cycle, subtle background parallax.
  static const Duration ambient = Duration(milliseconds: 1400);

  /// Low-end device fallback: when AppPerformanceMode.reduced is active,
  /// all durations above should be replaced with Duration.zero or this
  /// minimal stub duration to keep transitions instant but not jarring
  /// (a single frame's worth, ~16ms) rather than fully un-animated jumps
  /// that can look like a rendering glitch.
  static const Duration reducedMotionStub = Duration(milliseconds: 16);
}
