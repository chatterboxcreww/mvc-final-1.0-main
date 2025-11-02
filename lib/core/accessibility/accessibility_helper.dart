// lib/core/accessibility/accessibility_helper.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive accessibility helper for WCAG 2.1 AA compliance
class AccessibilityHelper {
  static const double _minContrastRatio = 4.5; // WCAG AA standard
  static const double _minTouchTargetSize = 44.0; // Minimum touch target size
  
  /// Make a widget accessible with proper semantics
  static Widget makeAccessible(
    Widget child, {
    required String semanticLabel,
    String? semanticHint,
    String? semanticValue,
    bool isButton = false,
    bool isHeader = false,
    bool isTextField = false,
    bool isImage = false,
    bool isLink = false,
    bool excludeSemantics = false,
    VoidCallback? onTap,
    bool enabled = true,
    bool selected = false,
    bool checked = false,
    bool expanded = false,
    bool hidden = false,
    int? sortKey,
  }) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      value: semanticValue,
      button: isButton,
      header: isHeader,
      textField: isTextField,
      image: isImage,
      link: isLink,
      onTap: onTap,
      enabled: enabled,
      selected: selected,
      checked: checked,
      expanded: expanded,
      hidden: hidden,
      sortKey: sortKey != null ? OrdinalSortKey(sortKey.toDouble()) : null,
      child: child,
    );
  }

  /// Create an accessible button with proper touch target size
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? semanticHint,
    double minSize = _minTouchTargetSize,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? foregroundColor,
    BorderRadius? borderRadius,
    bool enabled = true,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: enabled,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(8.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Create an accessible text field with proper labeling
  static Widget accessibleTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    bool enabled = true,
    bool required = false,
    int? maxLength,
    int? maxLines = 1,
  }) {
    final semanticLabel = required ? '$label (required)' : label;
    final semanticHint = hint != null 
        ? (errorText != null ? '$hint. Error: $errorText' : hint)
        : errorText;

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      textField: true,
      enabled: enabled,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onTap: onTap,
        enabled: enabled,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          suffixText: required ? '*' : null,
        ),
      ),
    );
  }

  /// Ensure color contrast meets WCAG standards
  static Color ensureContrast(Color foreground, Color background) {
    final contrastRatio = calculateContrastRatio(foreground, background);
    
    if (contrastRatio >= _minContrastRatio) {
      return foreground;
    }
    
    return adjustColorForContrast(foreground, background);
  }

  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = calculateLuminance(color1);
    final luminance2 = calculateLuminance(color2);
    
    final lighter = math.max(luminance1, luminance2);
    final darker = math.min(luminance1, luminance2);
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double calculateLuminance(Color color) {
    final r = _linearizeColorComponent(color.red / 255.0);
    final g = _linearizeColorComponent(color.green / 255.0);
    final b = _linearizeColorComponent(color.blue / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// Adjust color to meet contrast requirements
  static Color adjustColorForContrast(Color foreground, Color background) {
    final backgroundLuminance = calculateLuminance(background);
    
    // Determine if we should make the foreground lighter or darker
    final shouldLighten = backgroundLuminance > 0.5;
    
    Color adjustedColor = foreground;
    double currentRatio = calculateContrastRatio(adjustedColor, background);
    
    // Adjust color until contrast ratio is met
    while (currentRatio < _minContrastRatio) {
      if (shouldLighten) {
        adjustedColor = _lightenColor(adjustedColor, 0.1);
      } else {
        adjustedColor = _darkenColor(adjustedColor, 0.1);
      }
      
      currentRatio = calculateContrastRatio(adjustedColor, background);
      
      // Prevent infinite loop
      if ((shouldLighten && adjustedColor.computeLuminance() > 0.95) ||
          (!shouldLighten && adjustedColor.computeLuminance() < 0.05)) {
        break;
      }
    }
    
    return adjustedColor;
  }

  /// Lighten a color by a given amount
  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = math.min(1.0, hsl.lightness + amount);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken a color by a given amount
  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = math.max(0.0, hsl.lightness - amount);
    return hsl.withLightness(lightness).toColor();
  }

  /// Create accessible card with proper contrast and touch targets
  static Widget accessibleCard({
    required Widget child,
    required String semanticLabel,
    String? semanticHint,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? foregroundColor,
    double elevation = 2.0,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    final theme = ThemeData();
    final cardColor = backgroundColor ?? theme.cardColor;
    final textColor = foregroundColor ?? theme.textTheme.bodyLarge?.color ?? Colors.black;
    
    // Ensure proper contrast
    final adjustedTextColor = ensureContrast(textColor, cardColor);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      child: Card(
        color: cardColor,
        elevation: elevation,
        margin: margin,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _minTouchTargetSize,
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: DefaultTextStyle(
                style: TextStyle(color: adjustedTextColor),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Create accessible list tile
  static Widget accessibleListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    required String semanticLabel,
    String? semanticHint,
    VoidCallback? onTap,
    bool enabled = true,
    bool selected = false,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      enabled: enabled,
      selected: selected,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        enabled: enabled,
        selected: selected,
        minVerticalPadding: 12.0, // Ensure minimum touch target
      ),
    );
  }

  /// Create accessible icon button
  static Widget accessibleIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? semanticHint,
    double size = 24.0,
    Color? color,
    double minSize = _minTouchTargetSize,
    EdgeInsetsGeometry? padding,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(minSize / 2),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                size: size,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Create accessible switch
  static Widget accessibleSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
    required String semanticLabel,
    String? semanticHint,
    bool enabled = true,
  }) {
    final switchState = value ? 'enabled' : 'disabled';
    final fullLabel = '$semanticLabel, $switchState';
    
    return Semantics(
      label: fullLabel,
      hint: semanticHint,
      toggled: value,
      enabled: enabled,
      child: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  /// Create accessible slider
  static Widget accessibleSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    required String semanticLabel,
    String? semanticHint,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    String Function(double)? semanticFormatterCallback,
    bool enabled = true,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      slider: true,
      enabled: enabled,
      child: Slider(
        value: value,
        onChanged: enabled ? onChanged : null,
        min: min,
        max: max,
        divisions: divisions,
        semanticFormatterCallback: semanticFormatterCallback,
      ),
    );
  }

  /// Announce message to screen readers
  static void announceMessage(String message, {bool assertive = false}) {
    SemanticsService.announce(
      message,
      assertive ? Directionality.of(NavigationService.navigatorKey.currentContext!) 
                : TextDirection.ltr,
    );
  }

  /// Check if device has accessibility features enabled
  static bool get isAccessibilityEnabled {
    return MediaQuery.of(NavigationService.navigatorKey.currentContext!)
        .accessibleNavigation;
  }

  /// Get recommended font scale for accessibility
  static double getAccessibleFontScale(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    // Ensure text scale factor is within reasonable bounds
    return textScaleFactor.clamp(0.8, 3.0);
  }

  /// Create accessible progress indicator
  static Widget accessibleProgressIndicator({
    required double? value,
    required String semanticLabel,
    String? semanticHint,
    Color? backgroundColor,
    Color? valueColor,
    double strokeWidth = 4.0,
  }) {
    final progressText = value != null 
        ? '${(value * 100).round()}% complete'
        : 'Loading';
    
    return Semantics(
      label: '$semanticLabel, $progressText',
      hint: semanticHint,
      child: CircularProgressIndicator(
        value: value,
        backgroundColor: backgroundColor,
        valueColor: valueColor != null 
            ? AlwaysStoppedAnimation<Color>(valueColor)
            : null,
        strokeWidth: strokeWidth,
      ),
    );
  }

  /// Create accessible tab bar
  static Widget accessibleTabBar({
    required List<Tab> tabs,
    required TabController controller,
    required List<String> semanticLabels,
    List<String>? semanticHints,
  }) {
    return Semantics(
      container: true,
      child: TabBar(
        controller: controller,
        tabs: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          
          return Semantics(
            label: semanticLabels[index],
            hint: semanticHints?[index],
            selected: controller.index == index,
            button: true,
            child: tab,
          );
        }).toList(),
      ),
    );
  }

  /// Validate accessibility compliance
  static List<String> validateAccessibility(Widget widget, BuildContext context) {
    final issues = <String>[];
    
    // This would contain comprehensive accessibility validation logic
    // For now, returning basic checks
    
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    // Check text contrast
    if (textTheme.bodyLarge?.color != null) {
      final textColor = textTheme.bodyLarge!.color!;
      final backgroundColor = theme.scaffoldBackgroundColor;
      final contrast = calculateContrastRatio(textColor, backgroundColor);
      
      if (contrast < _minContrastRatio) {
        issues.add('Text contrast ratio ($contrast) is below WCAG AA standard ($_minContrastRatio)');
      }
    }
    
    return issues;
  }
}

/// Navigation service for global context access
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;
}