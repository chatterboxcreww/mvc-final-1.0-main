// lib/core/theme/shapes.dart
import 'package:flutter/material.dart';

/// Material 3 shape system for the Health-TRKD app
class AppShapes {
  AppShapes._();

  // Material 3 shape scale
  static const double extraSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 28.0;
  static const double full = 9999.0; // Fully rounded

  // Border radius constants
  static const BorderRadius extraSmallRadius = BorderRadius.all(Radius.circular(extraSmall));
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(extraLarge));
  static const BorderRadius fullRadius = BorderRadius.all(Radius.circular(full));

  // Rounded rectangle borders
  static RoundedRectangleBorder extraSmallShape = RoundedRectangleBorder(
    borderRadius: extraSmallRadius,
  );

  static RoundedRectangleBorder smallShape = RoundedRectangleBorder(
    borderRadius: smallRadius,
  );

  static RoundedRectangleBorder mediumShape = RoundedRectangleBorder(
    borderRadius: mediumRadius,
  );

  static RoundedRectangleBorder largeShape = RoundedRectangleBorder(
    borderRadius: largeRadius,
  );

  static RoundedRectangleBorder extraLargeShape = RoundedRectangleBorder(
    borderRadius: extraLargeRadius,
  );

  static RoundedRectangleBorder fullShape = RoundedRectangleBorder(
    borderRadius: fullRadius,
  );

  // Component-specific shapes
  static RoundedRectangleBorder get cardShape => largeShape;
  static RoundedRectangleBorder get buttonShape => mediumShape;
  static RoundedRectangleBorder get chipShape => smallShape;
  static RoundedRectangleBorder get dialogShape => extraLargeShape;
  static RoundedRectangleBorder get bottomSheetShape => const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(extraLarge)),
  );
  static RoundedRectangleBorder get fabShape => largeShape;
}
