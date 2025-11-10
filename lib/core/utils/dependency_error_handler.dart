// lib/core/utils/dependency_error_handler.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A specialized handler for Flutter's '_dependents.isEmpty' assertion error
class DependencyErrorHandler {
  static final DependencyErrorHandler _instance = DependencyErrorHandler._internal();
  factory DependencyErrorHandler() => _instance;
  DependencyErrorHandler._internal();

  final Set<String> _activeWidgets = {};
  final Map<String, Timer> _cleanupTimers = {};
  bool _isHandlingError = false;

  /// Register a widget that might have dependency issues
  void registerWidget(String widgetId) {
    _activeWidgets.add(widgetId);
    debugPrint('DependencyErrorHandler: Registered widget $widgetId');
  }

  /// Unregister a widget when it's properly disposed
  void unregisterWidget(String widgetId) {
    _activeWidgets.remove(widgetId);
    _cleanupTimers[widgetId]?.cancel();
    _cleanupTimers.remove(widgetId);
    debugPrint('DependencyErrorHandler: Unregistered widget $widgetId');
  }

  /// Handle a dependency error
  void handleDependencyError(Object error, StackTrace? stackTrace) {
    if (_isHandlingError) {
      debugPrint('DependencyErrorHandler: Already handling error, skipping');
      return;
    }

    _isHandlingError = true;
    debugPrint('DependencyErrorHandler: Handling dependency error: $error');

    // Schedule cleanup on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performEmergencyCleanup();
      
      // Reset handling flag after a delay
      Timer(const Duration(seconds: 2), () {
        _isHandlingError = false;
      });
    });
  }

  /// Perform emergency cleanup of potentially problematic widgets
  void _performEmergencyCleanup() {
    debugPrint('DependencyErrorHandler: Performing emergency cleanup for ${_activeWidgets.length} widgets');
    
    // Create cleanup timers for all active widgets
    for (final widgetId in _activeWidgets.toList()) {
      _cleanupTimers[widgetId] = Timer(const Duration(milliseconds: 100), () {
        _activeWidgets.remove(widgetId);
        debugPrint('DependencyErrorHandler: Emergency cleanup completed for $widgetId');
      });
    }
  }

  /// Check if a specific error is a dependency error
  static bool isDependencyError(Object error) {
    final errorString = error.toString();
    return errorString.contains('_dependents.isEmpty') ||
           errorString.contains('setState() called after dispose()') ||
           errorString.contains('Looking up a deactivated widget') ||
           errorString.contains('Tried to use a disposed') ||
           errorString.contains('Bad state: Cannot add new events after calling close');
  }

  /// Get current status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'active_widgets': _activeWidgets.length,
      'cleanup_timers': _cleanupTimers.length,
      'is_handling_error': _isHandlingError,
      'widget_ids': _activeWidgets.toList(),
    };
  }

  /// Force cleanup all resources
  void forceCleanup() {
    debugPrint('DependencyErrorHandler: Force cleanup initiated');
    
    for (final timer in _cleanupTimers.values) {
      timer.cancel();
    }
    
    _cleanupTimers.clear();
    _activeWidgets.clear();
    _isHandlingError = false;
    
    debugPrint('DependencyErrorHandler: Force cleanup completed');
  }
}

/// A mixin for widgets that might experience dependency issues
mixin DependencyErrorMixin<T extends StatefulWidget> on State<T> {
  late final String _widgetId;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _widgetId = '${widget.runtimeType}_${hashCode}_${DateTime.now().millisecondsSinceEpoch}';
    DependencyErrorHandler().registerWidget(_widgetId);
  }

  @override
  void dispose() {
    _isDisposed = true;
    DependencyErrorHandler().unregisterWidget(_widgetId);
    super.dispose();
  }

  /// Safe setState that checks if widget is disposed
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      try {
        setState(fn);
      } catch (e) {
        if (DependencyErrorHandler.isDependencyError(e)) {
          debugPrint('DependencyErrorMixin: Caught dependency error in setState: $e');
          DependencyErrorHandler().handleDependencyError(e, StackTrace.current);
        } else {
          rethrow;
        }
      }
    }
  }

  /// Check if widget is safely mounted and not disposed
  bool get isSafelyMounted => !_isDisposed && mounted;

  /// Get widget ID for debugging
  String get widgetId => _widgetId;
}

/// A safe wrapper for Provider operations that handles dependency errors
class SafeDependencyProvider {
  static T? safeRead<T>(BuildContext context) {
    try {
      if (context.mounted) {
        return Provider.of<T>(context, listen: false);
      }
    } catch (e) {
      if (DependencyErrorHandler.isDependencyError(e)) {
        debugPrint('SafeDependencyProvider: Dependency error in read: $e');
        DependencyErrorHandler().handleDependencyError(e, StackTrace.current);
      } else {
        debugPrint('SafeDependencyProvider: Error reading provider $T: $e');
      }
    }
    return null;
  }

  static T? safeWatch<T>(BuildContext context) {
    try {
      if (context.mounted) {
        return Provider.of<T>(context, listen: true);
      }
    } catch (e) {
      if (DependencyErrorHandler.isDependencyError(e)) {
        debugPrint('SafeDependencyProvider: Dependency error in watch: $e');
        DependencyErrorHandler().handleDependencyError(e, StackTrace.current);
      } else {
        debugPrint('SafeDependencyProvider: Error watching provider $T: $e');
      }
    }
    return null;
  }
}

/// A widget that automatically handles dependency errors
class DependencyErrorWrapper extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const DependencyErrorWrapper({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<DependencyErrorWrapper> createState() => _DependencyErrorWrapperState();
}

class _DependencyErrorWrapperState extends State<DependencyErrorWrapper>
    with DependencyErrorMixin {
  Object? _lastError;

  @override
  Widget build(BuildContext context) {
    if (_lastError != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _lastError!);
    }

    return ErrorCatchingWidget(
      onError: (error, stackTrace) {
        if (DependencyErrorHandler.isDependencyError(error)) {
          debugPrint('DependencyErrorWrapper: Caught dependency error: $error');
          DependencyErrorHandler().handleDependencyError(error, stackTrace);
          
          if (isSafelyMounted) {
            safeSetState(() {
              _lastError = error;
            });
          }
        }
      },
      child: widget.child,
    );
  }
}

/// A widget that catches errors in its child
class ErrorCatchingWidget extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorCatchingWidget({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  State<ErrorCatchingWidget> createState() => _ErrorCatchingWidgetState();
}

class _ErrorCatchingWidgetState extends State<ErrorCatchingWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    
    // Set up error handling for this widget's context
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError?.call(details.exception, details.stack);
      originalOnError?.call(details);
    };
  }
}