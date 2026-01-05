import 'package:flutter/material.dart';

/// Scaled spacing helpers using spacing scale factor.
/// Provides consistent spacing values that scale with lab mode.
class LabSpacing {
  LabSpacing._();

  /// Base spacing values (before scaling)
  static const double baseXs = 4.0;
  static const double baseSm = 8.0;
  static const double baseMd = 12.0;
  static const double baseLg = 16.0;
  static const double baseXl = 20.0;
  static const double baseXxl = 24.0;
  static const double baseXxxl = 32.0;

  /// Scaled spacing values (scale defaults to 1.0 if not provided)
  static double gapXs([double scale = 1.0]) => baseXs * scale;
  static double gapSm([double scale = 1.0]) => baseSm * scale;
  static double gapMd([double scale = 1.0]) => baseMd * scale;
  static double gapLg([double scale = 1.0]) => baseLg * scale;
  static double gapXl([double scale = 1.0]) => baseXl * scale;
  static double gapXxl([double scale = 1.0]) => baseXxl * scale;
  static double gapXxxl([double scale = 1.0]) => baseXxxl * scale;

  /// Page inset (horizontal padding for page content)
  static double insetPage([double scale = 1.0]) => gapLg(scale);

  /// Card inset (internal padding for cards)
  static double insetCard([double scale = 1.0]) => gapLg(scale);

  /// Tile inset (padding for list tiles)
  static double insetTile([double scale = 1.0]) => gapLg(scale);

  /// EdgeInsets helpers
  static EdgeInsets pageInsets([double scale = 1.0]) {
    final inset = insetPage(scale);
    return EdgeInsets.symmetric(horizontal: inset);
  }

  static EdgeInsets cardInsets([double scale = 1.0]) {
    final inset = insetCard(scale);
    return EdgeInsets.all(inset);
  }

  static EdgeInsets tileInsets([double scale = 1.0]) {
    final inset = insetTile(scale);
    return EdgeInsets.all(inset);
  }

  /// Vertical spacing helpers
  static SizedBox verticalGap(double base, [double scale = 1.0]) {
    return SizedBox(height: base * scale);
  }

  /// Horizontal spacing helpers
  static SizedBox horizontalGap(double base, [double scale = 1.0]) {
    return SizedBox(width: base * scale);
  }
}
