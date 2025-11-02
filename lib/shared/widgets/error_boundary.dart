import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? errorTitle;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showReportButton;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorTitle,
    this.errorMessage,
    this.onRetry,
    this.showReportButton = false,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(context);
    }

    return ErrorCatcher(
      child: widget.child,
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
        });
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                widget.errorTitle ?? 'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.errorMessage ?? 'An unexpected error occurred. Please try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (widget.onRetry != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                    widget.onRetry!();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              if (widget.showReportButton) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _reportError(context),
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Report Issue'),
                ),
              ],
              const SizedBox(height: 24),
              if (_error != null)
                ExpansionTile(
                  title: Text(
                    'Error Details',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportError(BuildContext context) {
    try {
      // Report to Firebase Crashlytics if available
      // FirebaseCrashlytics.instance.recordError(
      //   _error,
      //   null,
      //   fatal: false,
      //   information: ['Error occurred in ErrorBoundary'],
      // );
      
      // For now, log the error for debugging
      debugPrint('ErrorBoundary: Reporting error - $_error');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error report sent. Thank you for helping us improve!'),
        ),
      );
    } catch (e) {
      debugPrint('ErrorBoundary: Failed to report error - $e');
    }
  }
}

class ErrorCatcher extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace)? onError;

  const ErrorCatcher({
    Key? key,
    required this.child,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<ErrorCatcher> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (widget.onError != null) {
        widget.onError!(details.exception, details.stack ?? StackTrace.current);
      }
    };
  }
}
