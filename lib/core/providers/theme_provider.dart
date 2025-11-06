// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';

/// Theme mode options for the app
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

/// Provider for managing app theme with Material 3 support
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color? _dynamicPrimaryColor;
  final StorageService _storageService = StorageService();

  ThemeMode get themeMode => _themeMode;
  Color? get dynamicPrimaryColor => _dynamicPrimaryColor;

  ThemeProvider() {
    _loadThemeMode();
  }

  /// Load saved theme mode from storage
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

  /// Set theme mode and persist to storage
  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode.toThemeMode();
    _storageService.saveThemeMode(mode.toString().split('.').last);
    notifyListeners();
  }

  /// Set dynamic primary color (for Android 12+ dynamic colors)
  void setDynamicPrimaryColor(Color? color) {
    _dynamicPrimaryColor = color;
    notifyListeners();
  }

  /// Get Material 3 light theme
  ThemeData get lightTheme => AppTheme.light(dynamicPrimary: _dynamicPrimaryColor);

  /// Get Material 3 dark theme
  ThemeData get darkTheme => AppTheme.dark(dynamicPrimary: _dynamicPrimaryColor);
}
