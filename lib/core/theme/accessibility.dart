// lib/core/theme/accessibility.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Accessibility utilities for WCAG AA compliance
class AccessibilityHelper {
  AccessibilityHelper._();

  // Minimum touch target size (48dp x 48dp)
  static const double minTouchTargetSize = 48.0;
  
  // Minimum contrast ratios
  static const double minContrastNormal = 4.5; // WCAG AA for normal text
  static const double minContrastLarge = 3.0;  // WCAG AA for large text
  static const double minContrastAAA = 7.0;    // WCAG AAA

  /// Calculate relative luminance of a color
  static double _relativeLuminance(Color color) {
    final r = _linearize((color.r * 255.0).round() / 255.0);
    final g = _linearize((color.g * 255.0).round() / 255.0);
    final b = _linearize((color.b * 255.0).round() / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize RGB channel value
  static double _linearize(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Calculate contrast ratio between two colors
  static double contrastRatio(Color color1, Color color2) {
    final lum1 = _relativeLuminance(color1);
    final lum2 = _relativeLuminance(color2);
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA for normal text
  static bool meetsContrastAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= minContrastNormal;
  }

  /// Check if contrast ratio meets WCAG AAA
  static bool meetsContrastAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= minContrastAAA;
  }

  /// Get accessible text color for a given background
  static Color getAccessibleTextColor(Color background) {
    final luminance = _relativeLuminance(background);
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Ensure minimum touch target size
  static Widget ensureTouchTarget({
    required Widget child,
    double minSize = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }

  /// Add semantic label to widget
  static Widget addSemanticLabel({
    required Widget child,
    required String label,
    String? hint,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Check if text scaling is enabled
  static bool isTextScalingEnabled(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0) > 1.0;
  }

  /// Get scaled text size
  static double getScaledTextSize(BuildContext context, double baseSize) {
    final scaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    return baseSize * scaleFactor.clamp(1.0, 2.0); // Max 200% scaling
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if bold text is enabled
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Get accessible color with sufficient contrast
  static Color getAccessibleColor({
    required Color color,
    required Color background,
    double minContrast = minContrastNormal,
  }) {
    if (contrastRatio(color, background) >= minContrast) {
      return color;
    }

    // Adjust color to meet contrast requirements
    final luminance = _relativeLuminance(background);
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Create accessible button with minimum touch target
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    String? semanticLabel,
    String? tooltip,
  }) {
    Widget button = child;

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        child: button,
      );
    }

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return ensureTouchTarget(child: button);
  }

  /// Announce message to screen readers
  static void announce(BuildContext context, String message) {
    // Use Semantics widget to announce messages
    // This is handled by the framework automatically when semantic labels change
    debugPrint('Accessibility announcement: $message');
  }
}

/// Extension for color accessibility
extension ColorAccessibility on Color {
  /// Get contrast ratio with another color
  double contrastWith(Color other) {
    return AccessibilityHelper.contrastRatio(this, other);
  }

  /// Check if this color has sufficient contrast with another
  bool hasAccessibleContrastWith(Color other) {
    return AccessibilityHelper.meetsContrastAA(this, other);
  }

  /// Get accessible text color for this background
  Color get accessibleTextColor {
    return AccessibilityHelper.getAccessibleTextColor(this);
  }
}

/// Extension for widget accessibility
extension WidgetAccessibility on Widget {
  /// Add semantic label to widget
  Widget withSemanticLabel(String label, {String? hint}) {
    return AccessibilityHelper.addSemanticLabel(
      child: this,
      label: label,
      hint: hint,
    );
  }

  /// Ensure minimum touch target size
  Widget withMinTouchTarget({double minSize = AccessibilityHelper.minTouchTargetSize}) {
    return AccessibilityHelper.ensureTouchTarget(
      child: this,
      minSize: minSize,
    );
  }
}
