// lib/core/utils/error_handler.dart

import 'package:flutter/material.dart';
import '../logging/app_logger.dart';

/// Comprehensive error handling utility with logging and analytics
class ErrorHandler {
  static final Map<String, int> _errorCounts = {};
  static final List<ErrorReport> _recentErrors = [];
  static const int _maxRecentErrors = 50;

  /// Determine if an error is recoverable (network/temporary)
  static bool isRecoverableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('socket') ||
           errorString.contains('handshake') ||
           errorString.contains('certificate') ||
           errorString.contains('ssl') ||
           errorString.contains('tls');
  }

  /// Determine error severity
  static ErrorSeverity getErrorSeverity(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('fatal') || 
        errorString.contains('crash') ||
        errorString.contains('out of memory')) {
      return ErrorSeverity.fatal;
    }
    
    if (errorString.contains('authentication') ||
        errorString.contains('permission') ||
        errorString.contains('unauthorized')) {
      return ErrorSeverity.high;
    }
    
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('format')) {
      return ErrorSeverity.medium;
    }
    
    if (isRecoverableError(error)) {
      return ErrorSeverity.low;
    }
    
    return ErrorSeverity.medium;
  }

  /// Get user-friendly error message with context
  static String getUserFriendlyMessage(dynamic error, {String? context}) {
    final errorString = error.toString().toLowerCase();
    
    // Network-related errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue. Please check your internet and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again in a moment.';
    }
    
    if (errorString.contains('ssl') || errorString.contains('certificate')) {
      return 'Secure connection failed. Please check your network settings.';
    }
    
    // Authentication errors
    if (errorString.contains('authentication') || errorString.contains('auth')) {
      return 'Authentication failed. Please sign in again.';
    }
    
    if (errorString.contains('permission') || errorString.contains('unauthorized')) {
      return 'Permission denied. Please check your account permissions.';
    }
    
    // Data validation errors
    if (errorString.contains('validation')) {
      return 'Invalid data provided. Please check your input and try again.';
    }
    
    if (errorString.contains('format')) {
      return 'Data format error. Please check your input format.';
    }
    
    // Storage errors
    if (errorString.contains('storage') || errorString.contains('disk')) {
      return 'Storage error. Please check available space and try again.';
    }
    
    // Firebase-specific errors
    if (errorString.contains('firebase')) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    
    // Context-specific messages
    if (context != null) {
      switch (context.toLowerCase()) {
        case 'water_tracking':
          return 'Unable to update water intake. Your progress is saved locally.';
        case 'step_tracking':
          return 'Step tracking temporarily unavailable. Data will sync when connection is restored.';
        case 'achievements':
          return 'Achievement data temporarily unavailable. Progress is saved locally.';
        case 'sync':
          return 'Sync failed. Your data is safe and will sync when connection is restored.';
      }
    }
    
    // Default message for unknown errors
    return 'Something went wrong. Please try again, and contact support if the issue persists.';
  }

  /// Handle error with comprehensive logging and user notification
  static Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
    bool showToUser = true,
    BuildContext? buildContext,
    VoidCallback? onRetry,
  }) async {
    // Create error report
    final errorReport = ErrorReport(
      error: error,
      stackTrace: stackTrace,
      context: context,
      additionalData: additionalData,
      timestamp: DateTime.now(),
      severity: getErrorSeverity(error),
      isRecoverable: isRecoverableError(error),
    );

    // Log error
    await _logError(errorReport);
    
    // Track error frequency
    _trackErrorFrequency(error);
    
    // Store recent error
    _storeRecentError(errorReport);
    
    // Show to user if requested and context available
    if (showToUser && buildContext != null) {
      _showErrorToUser(buildContext, errorReport, onRetry: onRetry);
    }
    
    // Report to analytics/crash reporting service
    await _reportToAnalytics(errorReport);
  }

  /// Log error with comprehensive details
  static Future<void> _logError(ErrorReport errorReport) async {
    try {
      // Use the app logger if available
      final logger = AppLogger();
      
      final logData = {
        'error': errorReport.error.toString(),
        'context': errorReport.context,
        'severity': errorReport.severity.name,
        'isRecoverable': errorReport.isRecoverable,
        'timestamp': errorReport.timestamp.toIso8601String(),
        ...?errorReport.additionalData,
      };
      
      switch (errorReport.severity) {
        case ErrorSeverity.fatal:
          logger.fatal(
            'Fatal error: ${errorReport.error}',
            tag: errorReport.context ?? 'ERROR',
            data: logData,
            stackTrace: errorReport.stackTrace,
          );
          break;
        case ErrorSeverity.high:
          logger.error(
            'High severity error: ${errorReport.error}',
            tag: errorReport.context ?? 'ERROR',
            data: logData,
            stackTrace: errorReport.stackTrace,
          );
          break;
        case ErrorSeverity.medium:
          logger.warning(
            'Medium severity error: ${errorReport.error}',
            tag: errorReport.context ?? 'ERROR',
            data: logData,
            stackTrace: errorReport.stackTrace,
          );
          break;
        case ErrorSeverity.low:
          logger.info(
            'Low severity error: ${errorReport.error}',
            tag: errorReport.context ?? 'ERROR',
            data: logData,
          );
          break;
      }
    } catch (e) {
      // Fallback to debug print if logger fails
      debugPrint('ERROR [${errorReport.context ?? 'UNKNOWN'}]: ${errorReport.error}');
      if (errorReport.stackTrace != null) {
        debugPrint('STACK TRACE: ${errorReport.stackTrace}');
      }
    }
  }

  /// Track error frequency for pattern analysis
  static void _trackErrorFrequency(dynamic error) {
    final errorKey = error.runtimeType.toString();
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
  }

  /// Store recent error for debugging
  static void _storeRecentError(ErrorReport errorReport) {
    _recentErrors.add(errorReport);
    
    // Maintain list size
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
  }

  /// Show error to user with appropriate UI
  static void _showErrorToUser(
    BuildContext context,
    ErrorReport errorReport, {
    VoidCallback? onRetry,
  }) {
    final message = getUserFriendlyMessage(errorReport.error, context: errorReport.context);
    
    // Choose appropriate UI based on severity
    switch (errorReport.severity) {
      case ErrorSeverity.fatal:
      case ErrorSeverity.high:
        _showErrorDialog(context, errorReport, message, onRetry: onRetry);
        break;
      case ErrorSeverity.medium:
        _showErrorSnackBar(context, errorReport, message);
        break;
      case ErrorSeverity.low:
        // For low severity, just show a brief snackbar
        _showBriefErrorSnackBar(context, message);
        break;
    }
  }

  /// Show error dialog for high severity errors
  static void _showErrorDialog(
    BuildContext context,
    ErrorReport errorReport,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              errorReport.isRecoverable ? Icons.wifi_off : Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorReport.isRecoverable ? 'Connection Issue' : 'Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (kDebugMode && errorReport.context != null) ...[
              const SizedBox(height: 8),
              Text(
                'Context: ${errorReport.context}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null && errorReport.isRecoverable)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          if (errorReport.severity == ErrorSeverity.fatal)
            TextButton(
              onPressed: () {
                // Report error and potentially restart app
                Navigator.of(context).pop();
                _reportCriticalError(errorReport);
              },
              child: const Text('Report Issue'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar for medium severity errors
  static void _showErrorSnackBar(
    BuildContext context,
    ErrorReport errorReport,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              errorReport.isRecoverable ? Icons.wifi_off : Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: errorReport.isRecoverable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: () {
                  // Implement retry logic
                },
              )
            : null,
      ),
    );
  }

  /// Show brief error snackbar for low severity errors
  static void _showBriefErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Report to analytics service
  static Future<void> _reportToAnalytics(ErrorReport errorReport) async {
    try {
      // This would integrate with Firebase Crashlytics or similar service
      // For now, just log the intent
      debugPrint('Reporting error to analytics: ${errorReport.error}');
    } catch (e) {
      debugPrint('Failed to report error to analytics: $e');
    }
  }

  /// Report critical error
  static void _reportCriticalError(ErrorReport errorReport) {
    // This would typically send error report to support system
    debugPrint('Critical error reported: ${errorReport.error}');
  }

  /// Get error statistics
  static Map<String, dynamic> getErrorStats() {
    return {
      'totalErrors': _recentErrors.length,
      'errorCounts': Map.from(_errorCounts),
      'recentErrors': _recentErrors.map((e) => e.toJson()).toList(),
      'mostFrequentError': _getMostFrequentError(),
    };
  }

  /// Get most frequent error
  static String? _getMostFrequentError() {
    if (_errorCounts.isEmpty) return null;
    
    return _errorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Clear error history
  static void clearErrorHistory() {
    _errorCounts.clear();
    _recentErrors.clear();
  }

  /// Export error report
  static String exportErrorReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Error Report ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Errors: ${_recentErrors.length}');
    buffer.writeln();
    
    buffer.writeln('=== Error Frequency ===');
    for (final entry in _errorCounts.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    buffer.writeln();
    
    buffer.writeln('=== Recent Errors ===');
    for (final error in _recentErrors.reversed.take(10)) {
      buffer.writeln('${error.timestamp}: [${error.severity.name}] ${error.error}');
      if (error.context != null) {
        buffer.writeln('  Context: ${error.context}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  fatal,
}

/// Error report class
class ErrorReport {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final bool isRecoverable;

  ErrorReport({
    required this.error,
    this.stackTrace,
    this.context,
    this.additionalData,
    required this.timestamp,
    required this.severity,
    required this.isRecoverable,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error.toString(),
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'isRecoverable': isRecoverable,
      'additionalData': additionalData,
    };
  }
}

/// Error boundary widget
class ErrorBoundaryWidget extends StatelessWidget {
  final Widget child;
  final String errorTitle;
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.errorTitle = 'Something went wrong',
    this.errorMessage = 'An unexpected error occurred. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return child; // In a real implementation, this would catch errors
  }
}