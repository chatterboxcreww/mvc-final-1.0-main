// lib/core/theme/performance_theme_config.dart
import 'package:flutter/material.dart';

/// Performance-optimized theme configuration for 60fps animations
class PerformanceThemeConfig {
  /// Create a performance-optimized theme with smooth animations
  static ThemeData createOptimizedTheme({
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // Optimize animation curves for smooth 60fps performance
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // Optimized progress indicator theme with better light mode visibility
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: isDark 
            ? colorScheme.surfaceContainerHighest 
            : colorScheme.primary.withValues(alpha: 0.1), // More visible track in light mode
        circularTrackColor: isDark 
            ? colorScheme.surfaceContainerHighest 
            : colorScheme.primary.withValues(alpha: 0.1),
        refreshBackgroundColor: colorScheme.surface,
      ),
      
      // Optimized animation durations
      splashFactory: InkRipple.splashFactory,
      
      // Optimized text theme with minimal rebuilds
      textTheme: _createOptimizedTextTheme(colorScheme),
      
      // Card theme with optimized elevation and better light mode appearance
      cardTheme: CardThemeData(
        elevation: isDark ? 2 : 1, // Reduced elevation for light mode
        shadowColor: isDark 
            ? colorScheme.shadow.withOpacity(0.1)
            : colorScheme.shadow.withOpacity(0.05), // Lighter shadows in light mode
        surfaceTintColor: colorScheme.surfaceTint,
        color: isDark ? null : const Color(0xFFFFFFFF), // Pure white cards in light mode
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark 
              ? BorderSide.none 
              : BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 0.5,
                ), // Subtle border for light mode
        ),
      ),
      
      // Optimized app bar theme with better light mode contrast
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: isDark ? 1 : 0.5, // Minimal elevation for light mode
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFAFAFA),
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      
      // Optimized floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Optimized navigation themes
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      
      // Optimized button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
      ),
      
      // Optimized input decoration theme with better light mode contrast
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? colorScheme.surfaceContainerHighest 
            : const Color(0xFFF8F9FA), // Lighter fill for light mode
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark 
              ? BorderSide.none 
              : BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ), // Subtle border for light mode
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark 
              ? BorderSide.none 
              : BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 16,
        ),
      ),
      
      // Optimized divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      
      // Optimized expansion tile theme
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: colorScheme.surface,
        collapsedBackgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Optimized list tile theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
  
  /// Create optimized text theme that minimizes rebuilds
  static TextTheme _createOptimizedTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      
      // Titles
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      
      // Body text
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
        height: 1.3,
      ),
      
      // Labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        height: 1.3,
      ),
    );
  }
  
  /// Animation durations optimized for 60fps
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  /// Optimized curves for smooth animations
  static const Curve fastCurve = Curves.easeOutCubic;
  static const Curve normalCurve = Curves.easeInOutCubic;
  static const Curve slowCurve = Curves.easeInOut;
  
  /// Page transition duration
  static const Duration pageTransitionDuration = Duration(milliseconds: 250);
  
  /// Ripple animation settings
  static const Duration rippleDuration = Duration(milliseconds: 300);
  static const double rippleRadius = 28.0;
  
  /// Progress indicator settings
  static const Duration progressIndicatorDuration = Duration(milliseconds: 1500);
  static const Curve progressIndicatorCurve = Curves.easeInOutCubic;
}

/// Extension for performance-optimized theme usage
extension ThemeDataExtensions on ThemeData {
  /// Get optimized animation duration
  Duration getOptimizedDuration(Duration baseDuration) {
    // Adjust duration based on theme brightness and device performance
    final isReduced = false; // Could be tied to accessibility settings
    return isReduced ? 
      Duration(milliseconds: baseDuration.inMilliseconds ~/ 2) : 
      baseDuration;
  }
  
  /// Get optimized curve for animations
  Curve getOptimizedCurve() => PerformanceThemeConfig.normalCurve;
}

