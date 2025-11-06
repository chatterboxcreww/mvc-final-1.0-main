// lib/core/theme/dynamic_color_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Helper class for Android 12+ dynamic color support
class DynamicColorHelper {
  DynamicColorHelper._();

  static const MethodChannel _channel = MethodChannel('com.healthtrkd.app/dynamic_colors');

  /// Check if dynamic colors are supported on this device
  static Future<bool> isDynamicColorSupported() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('isDynamicColorSupported');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking dynamic color support: $e');
      return false;
    }
  }

  /// Get the system's dynamic primary color (Android 12+)
  static Future<Color?> getDynamicPrimaryColor() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final colorValue = await _channel.invokeMethod<int>('getDynamicPrimaryColor');
      if (colorValue != null) {
        return Color(colorValue);
      }
    } catch (e) {
      debugPrint('Error getting dynamic primary color: $e');
    }
    return null;
  }

  /// Initialize dynamic colors for the app
  /// Returns the dynamic primary color if available, null otherwise
  static Future<Color?> initializeDynamicColors() async {
    final isSupported = await isDynamicColorSupported();
    if (!isSupported) return null;
    
    return await getDynamicPrimaryColor();
  }
}
