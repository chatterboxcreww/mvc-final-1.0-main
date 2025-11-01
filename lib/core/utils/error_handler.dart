// lib/core/utils/error_handler.dart

import 'package:flutter/material.dart';

/// Centralized error handling utility
class ErrorHandler {
  /// Determine if an error is recoverable (network/temporary)
  static bool isRecoverableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('socket') ||
           errorString.contains('handshake');
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue. Please check your internet and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check your account permissions.';
    }
    
    if (errorString.contains('authentication') || errorString.contains('auth')) {
      return 'Authentication failed. Please sign in again.';
    }
    
    if (errorString.contains('validation')) {
      return 'Invalid data provided. Please check your input.';
    }
    
    // Default message for unknown errors
    return 'An unexpected error occurred. Please try again.';
  }

  /// Show error dialog
  static void showErrorDialog(BuildContext context, dynamic error, {VoidCallback? onRetry}) {
    final message = getUserFriendlyMessage(error);
    final isRecoverable = isRecoverableError(error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isRecoverable ? Icons.wifi_off : Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(isRecoverable ? 'Connection Issue' : 'Error'),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null && isRecoverable)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Log error with context
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    print('ERROR [$context]: $error');
    if (stackTrace != null) {
      print('STACK TRACE: $stackTrace');
    }
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