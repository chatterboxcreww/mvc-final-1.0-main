// lib/shared/utils/app_typography.dart
import 'package:flutter/material.dart';

class AppTypography {
  // Display text styles for large headings
  static TextStyle display1(BuildContext context) => 
      Theme.of(context).textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ) ?? const TextStyle();

  static TextStyle display2(BuildContext context) => 
      Theme.of(context).textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ) ?? const TextStyle();

  // Headline styles for section headers
  static TextStyle headline1(BuildContext context) => 
      Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ) ?? const TextStyle();

  static TextStyle headline2(BuildContext context) => 
      Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ) ?? const TextStyle();

  static TextStyle headline3(BuildContext context) => 
      Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ) ?? const TextStyle();

  // Title styles for card headers
  static TextStyle title1(BuildContext context) => 
      Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ) ?? const TextStyle();

  static TextStyle title2(BuildContext context) => 
      Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ) ?? const TextStyle();

  static TextStyle title3(BuildContext context) => 
      Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ) ?? const TextStyle();

  // Body text styles
  static TextStyle body1(BuildContext context) => 
      Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.5,
      ) ?? const TextStyle();

  static TextStyle body2(BuildContext context) => 
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.4,
      ) ?? const TextStyle();

  static TextStyle body3(BuildContext context) => 
      Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.3,
      ) ?? const TextStyle();

  // Utility text styles
  static TextStyle button(BuildContext context) => 
      Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ) ?? const TextStyle();

  static TextStyle caption(BuildContext context) => 
      Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ) ?? const TextStyle();

  static TextStyle overline(BuildContext context) => 
      Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ) ?? const TextStyle();
}

// Spacing utilities for consistent layouts
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Common edge insets
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0);
  
  // Common sized boxes
  static const SizedBox verticalXS = SizedBox(height: xs);
  static const SizedBox verticalSM = SizedBox(height: sm);
  static const SizedBox verticalMD = SizedBox(height: md);
  static const SizedBox verticalLG = SizedBox(height: lg);
  static const SizedBox verticalXL = SizedBox(height: xl);
  
  static const SizedBox horizontalXS = SizedBox(width: xs);
  static const SizedBox horizontalSM = SizedBox(width: sm);
  static const SizedBox horizontalMD = SizedBox(width: md);
  static const SizedBox horizontalLG = SizedBox(width: lg);
  static const SizedBox horizontalXL = SizedBox(width: xl);
}

// Border radius utilities
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
  static BorderRadius circularSM = BorderRadius.circular(sm);
  static BorderRadius circularMD = BorderRadius.circular(md);
  static BorderRadius circularLG = BorderRadius.circular(lg);
  static BorderRadius circularXL = BorderRadius.circular(xl);
  static BorderRadius circularXXL = BorderRadius.circular(xxl);
}

// Shadow utilities
class AppShadows {
  static List<BoxShadow> soft(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> strong(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
