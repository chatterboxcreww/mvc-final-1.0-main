// lib/core/theme/responsive.dart
import 'package:flutter/material.dart';

/// Material 3 responsive breakpoints and layout utilities
class Responsive {
  Responsive._();

  // Material 3 window size classes
  static const double compactMaxWidth = 600;
  static const double mediumMaxWidth = 840;
  static const double expandedMinWidth = 841;

  /// Get the current window size class
  static WindowSizeClass getWindowSizeClass(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < compactMaxWidth) {
      return WindowSizeClass.compact;
    } else if (width < mediumMaxWidth) {
      return WindowSizeClass.medium;
    } else {
      return WindowSizeClass.expanded;
    }
  }

  /// Check if device is in compact mode (phone)
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < compactMaxWidth;
  }

  /// Check if device is in medium mode (tablet portrait)
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= compactMaxWidth && width < mediumMaxWidth;
  }

  /// Check if device is in expanded mode (tablet landscape, desktop)
  static bool isExpanded(BuildContext context) {
    return MediaQuery.of(context).size.width >= expandedMinWidth;
  }

  /// Get responsive value based on window size class
  static T valueWhen<T>({
    required BuildContext context,
    required T compact,
    T? medium,
    T? expanded,
  }) {
    final sizeClass = getWindowSizeClass(context);
    
    switch (sizeClass) {
      case WindowSizeClass.compact:
        return compact;
      case WindowSizeClass.medium:
        return medium ?? compact;
      case WindowSizeClass.expanded:
        return expanded ?? medium ?? compact;
    }
  }

  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    return valueWhen(
      context: context,
      compact: const EdgeInsets.all(16),
      medium: const EdgeInsets.all(24),
      expanded: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    return valueWhen(
      context: context,
      compact: const EdgeInsets.symmetric(horizontal: 16),
      medium: const EdgeInsets.symmetric(horizontal: 24),
      expanded: const EdgeInsets.symmetric(horizontal: 32),
    );
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    return valueWhen(
      context: context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );
  }

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    return valueWhen(
      context: context,
      compact: double.infinity,
      medium: 400,
      expanded: 500,
    );
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    return valueWhen(
      context: context,
      compact: MediaQuery.of(context).size.width * 0.9,
      medium: 560,
      expanded: 600,
    );
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get screen width
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Check if text scaling is enabled
  static bool isTextScalingEnabled(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0) > 1.0;
  }
}

/// Window size class enum
enum WindowSizeClass {
  compact,  // < 600dp (phones)
  medium,   // 600-840dp (tablets portrait)
  expanded, // > 840dp (tablets landscape, desktop)
}

/// Extension for responsive context
extension ResponsiveContext on BuildContext {
  WindowSizeClass get windowSizeClass => Responsive.getWindowSizeClass(this);
  bool get isCompact => Responsive.isCompact(this);
  bool get isMedium => Responsive.isMedium(this);
  bool get isExpanded => Responsive.isExpanded(this);
  bool get isLandscape => Responsive.isLandscape(this);
  bool get isPortrait => Responsive.isPortrait(this);
  
  EdgeInsets get responsivePadding => Responsive.getPadding(this);
  EdgeInsets get responsiveHorizontalPadding => Responsive.getHorizontalPadding(this);
  int get responsiveGridColumns => Responsive.getGridColumns(this);
}
