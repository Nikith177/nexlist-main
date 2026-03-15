import 'package:flutter/material.dart';

class AppSpacing {
  // Common Padding and Margins
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0; // Standard layout margin
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Screen Edge Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md);
  
  // Widget Spacings (Gaps)
  static const Widget gapXs = SizedBox(height: xs, width: xs);
  static const Widget gapSm = SizedBox(height: sm, width: sm);
  static const Widget gapMd = SizedBox(height: md, width: md);
  static const Widget gapLg = SizedBox(height: lg, width: lg);
  static const Widget gapXl = SizedBox(height: xl, width: xl);

  // Border Radius
  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0; // Cards and standard buttons
  static const double radiusLg = 16.0; 
  static const double radiusXl = 24.0;
  static const double radiusCircular = 1000.0; // For pills/circular images

  // Helper Radii
  static BorderRadius defaultBorderRadius = BorderRadius.circular(radiusMd);
}
