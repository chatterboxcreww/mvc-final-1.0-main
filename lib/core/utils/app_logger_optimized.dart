// lib/core/utils/app_logger_optimized.dart

import 'package:flutter/foundation.dart';

/// Optimized logging utility for production-ready apps
/// Automatically disabled in release mode for better performance
class AppLogger {
  static const bool _enableLogging = kDebugMode;
  
  // Log levels
  static const String _debug = '🔍 DEBUG';
  static const String _info = 'ℹ️ INFO';
  static const String _warning = '⚠️ WARNING';
  static const String _error = '❌ ERROR';
  static const String _success = '✅ SUCCESS';
  
  /// Log debug message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (_enableLogging) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_debug $tagPrefix$message');
    }
  }
  
  /// Log info message (only in debug mode)
  static void info(String message, {String? tag}) {
    if (_enableLogging) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_info $tagPrefix$message');
    }
  }
  
  /// Log warning message (only in debug mode)
  static void warning(String message, {String? tag}) {
    if (_enableLogging) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_warning $tagPrefix$message');
    }
  }
  
  /// Log error message (always logged, even in release)
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    debugPrint('$_error $tagPrefix$message');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null && _enableLogging) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Log success message (only in debug mode)
  static void success(String message, {String? tag}) {
    if (_enableLogging) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_success $tagPrefix$message');
    }
  }
  
  /// Log network request (only in debug mode)
  static void network(String method, String url, {int? statusCode, String? tag}) {
    if (_enableLogging) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      final status = statusCode != null ? ' [$statusCode]' : '';
      debugPrint('🌐 NETWORK $tagPrefix$method $url$status');
    }
  }
  
  /// Log Firebase operation (only in debug mode)
  static void firebase(String operation, {String? collection, String? tag}) {
    if (_enableLogging) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      final collectionInfo = collection != null ? ' ($collection)' : '';
      debugPrint('🔥 FIREBASE $tagPrefix$operation$collectionInfo');
    }
  }
  
  /// Log performance metric (only in debug mode)
  static void performance(String operation, Duration duration, {String? tag}) {
    if (_enableLogging) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚡ PERFORMANCE $tagPrefix$operation took ${duration.inMilliseconds}ms');
    }
  }
}
