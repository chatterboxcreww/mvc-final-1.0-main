// lib/core/theme/colors.dart
import 'package:flutter/material.dart';

/// Material 3 color schemes for the Health-TRKD app
class AppColors {
  AppColors._();

  /// Light color scheme using Material 3 design tokens
  static ColorScheme lightColorScheme({Color? dynamicPrimary}) {
    final seedColor = dynamicPrimary ?? const Color(0xFF2196F3);
    
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ).copyWith(
      // Primary colors - Health-focused blue
      primary: const Color(0xFF1976D2),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFD8E6FF),
      onPrimaryContainer: const Color(0xFF001B3D),
      
      // Secondary colors - Success/Health green
      secondary: const Color(0xFF4CAF50),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFC1F7E3),
      onSecondaryContainer: const Color(0xFF00382A),
      
      // Tertiary colors - Energy/Warning orange
      tertiary: const Color(0xFFFF9800),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFFFE0B2),
      onTertiaryContainer: const Color(0xFF2D1600),
      
      // Error colors
      error: const Color(0xFFD32F2F),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      
      // Surface colors
      surface: const Color(0xFFFCFCFC),
      onSurface: const Color(0xFF1A1C1E),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF6F6F6),
      surfaceContainer: const Color(0xFFF0F4FF),
      surfaceContainerHigh: const Color(0xFFEAEEF8),
      surfaceContainerHighest: const Color(0xFFE4E8F2),
      onSurfaceVariant: const Color(0xFF42474F),
      
      // Outline colors
      outline: const Color(0xFFD0D8E0),
      outlineVariant: const Color(0xFFE8ECF4),
      
      // Shadow and other colors
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFF2F3033),
      onInverseSurface: const Color(0xFFF1F0F4),
      inversePrimary: const Color(0xFFADC6FF),
    );
  }

  /// Dark color scheme using Material 3 design tokens
  static ColorScheme darkColorScheme({Color? dynamicPrimary}) {
    final seedColor = dynamicPrimary ?? const Color(0xFF4361EE);
    
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      // Primary colors - Vibrant blue for dark mode
      primary: const Color(0xFF4361EE),
      onPrimary: const Color(0xFF00344D),
      primaryContainer: const Color(0xFF004B6F),
      onPrimaryContainer: const Color(0xFFBEECFF),
      
      // Secondary colors - Vibrant pink/magenta
      secondary: const Color(0xFFF72585),
      onSecondary: const Color(0xFF3F0022),
      secondaryContainer: const Color(0xFF5C0035),
      onSecondaryContainer: const Color(0xFFFFD9E6),
      
      // Tertiary colors - Purple accent
      tertiary: const Color(0xFF7209B7),
      onTertiary: const Color(0xFF3A0059),
      tertiaryContainer: const Color(0xFF560A8A),
      onTertiaryContainer: const Color(0xFFF3CCFF),
      
      // Error colors
      error: const Color(0xFFFF5D8F),
      onError: const Color(0xFF4F0018),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      
      // Surface colors
      surface: const Color(0xFF121824),
      onSurface: const Color(0xFFE9EEFF),
      surfaceContainerLowest: const Color(0xFF0D1117),
      surfaceContainerLow: const Color(0xFF1A2130),
      surfaceContainer: const Color(0xFF1E2838),
      surfaceContainerHigh: const Color(0xFF232A3A),
      surfaceContainerHighest: const Color(0xFF2D3545),
      onSurfaceVariant: const Color(0xFFCFD5E8),
      
      // Outline colors
      outline: const Color(0xFF4A5573),
      outlineVariant: const Color(0xFF3A4258),
      
      // Shadow and other colors
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFFE3E2E6),
      onInverseSurface: const Color(0xFF1A1C1E),
      inversePrimary: const Color(0xFF1976D2),
    );
  }

  /// Health-specific semantic colors
  static const Color waterBlue = Color(0xFF2196F3);
  static const Color stepsGreen = Color(0xFF4CAF50);
  static const Color sleepPurple = Color(0xFF9C27B0);
  static const Color foodOrange = Color(0xFFFF9800);
  static const Color meditationIndigo = Color(0xFF3F51B5);
  static const Color energyYellow = Color(0xFFFFC107);
  static const Color heartRed = Color(0xFFE91E63);
  
  /// Achievement tier colors
  static const Color bronzeTier = Color(0xFFCD7F32);
  static const Color silverTier = Color(0xFFC0C0C0);
  static const Color goldTier = Color(0xFFFFD700);
  static const Color platinumTier = Color(0xFFE5E4E2);
  static const Color diamondTier = Color(0xFFB9F2FF);
}
