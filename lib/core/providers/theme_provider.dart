// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\providers\theme_provider.dart

// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/performance_theme_config.dart';

// This enum is simple and only used by the ThemeProvider, so it can live here.
enum AppThemeMode { light, dark, system }

extension AppThemeModeExtension on AppThemeMode {
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final StorageService _storageService = StorageService();

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final String? savedTheme = await _storageService.getThemeMode();
    if (savedTheme != null) {
      _themeMode = AppThemeMode.values
          .firstWhere(
            (e) => e.toString().split('.').last == savedTheme,
        orElse: () => AppThemeMode.system,
      )
          .toThemeMode();
      notifyListeners();
    }
  }

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode.toThemeMode();
    _storageService.saveThemeMode(mode.toString().split('.').last);
    notifyListeners();
  }

  /// Get performance-optimized light theme
  ThemeData get lightTheme => PerformanceThemeConfig.createOptimizedTheme(
    colorScheme: _createLightColorScheme(),
    isDark: false,
  );

  /// Get performance-optimized dark theme
  ThemeData get darkTheme => PerformanceThemeConfig.createOptimizedTheme(
    colorScheme: _createDarkColorScheme(),
    isDark: true,
  );

  /// Create optimized light color scheme for health tracking app
  ColorScheme _createLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3), // Health-focused blue
      brightness: Brightness.light,
    ).copyWith(
      // Custom colors for better light mode appearance
      primary: const Color(0xFF1976D2), // Deep blue for primary actions
      primaryContainer: const Color(0xFFE3F2FD), // Light blue container
      secondary: const Color(0xFF4CAF50), // Green for health/success
      secondaryContainer: const Color(0xFFE8F5E8), // Light green container
      tertiary: const Color(0xFFFF9800), // Orange for warnings/energy
      tertiaryContainer: const Color(0xFFFFF3E0), // Light orange container
      error: const Color(0xFFD32F2F), // Clear red for errors
      errorContainer: const Color(0xFFFFEBEE), // Light red container
      surface: const Color(0xFFFCFCFC), // Very light gray surface
      surfaceContainerHighest: const Color(0xFFF5F5F5), // Subtle gray for input fields
      outline: const Color(0xFFE0E0E0), // Light gray for borders
      outlineVariant: const Color(0xFFF0F0F0), // Even lighter gray
      shadow: const Color(0xFF000000).withOpacity(0.08), // Subtle shadows
    );
  }

  /// Create optimized dark color scheme for health tracking app
  ColorScheme _createDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3), // Same blue base for consistency
      brightness: Brightness.dark,
    ).copyWith(
      // Custom colors for better dark mode appearance
      primary: const Color(0xFF42A5F5), // Lighter blue for dark mode
      secondary: const Color(0xFF66BB6A), // Lighter green for dark mode
      tertiary: const Color(0xFFFFB74D), // Lighter orange for dark mode
    );
  }
}
