// lib/core/utils/app_logger.dart

import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'TRKD_APP';
  
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      print('${tag ?? _tag}: $message');
    }
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('${tag ?? _tag} ERROR: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }
  
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('${tag ?? _tag} WARNING: $message');
    }
  }
  
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('${tag ?? _tag} INFO: $message');
    }
  }
  
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('${tag ?? _tag} DEBUG: $message');
    }
  }
}