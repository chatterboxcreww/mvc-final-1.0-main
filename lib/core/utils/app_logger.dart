// lib/core/utils/app_logger.dart
import 'package:flutter/foundation.dart';

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Centralized logging utility for the Health-TRKD app
/// Provides different log levels and conditional logging based on build mode
class AppLogger {
  static const String _tag = 'HealthTRKD';
  
  /// Enable/disable logging based on build mode
  static bool get _isLoggingEnabled => kDebugMode;
  
  /// Debug level logging - only in debug builds
  static void debug(String message, {String? tag}) {
    if (_isLoggingEnabled) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] DEBUG: $message');
    }
  }
  
  /// Info level logging - only in debug builds
  static void info(String message, {String? tag}) {
    if (_isLoggingEnabled) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] INFO: $message');
    }
  }
  
  /// Warning level logging - always enabled
  static void warning(String message, {String? tag}) {
    debugPrint('[$_tag${tag != null ? ':$tag' : ''}] WARNING: $message');
  }
  
  /// Error level logging - always enabled
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ERROR: $message');
    if (error != null) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ERROR DETAILS: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] STACK TRACE: $stackTrace');
    }
  }
  
  /// Log user actions for analytics (only in debug mode)
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    if (_isLoggingEnabled) {
      final params = parameters != null ? ' - Params: $parameters' : '';
      debugPrint('[$_tag:USER_ACTION] $action$params');
    }
  }
  
  /// Log performance metrics (only in debug mode)
  static void performance(String operation, Duration duration, {String? tag}) {
    if (_isLoggingEnabled) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
    }
  }
}