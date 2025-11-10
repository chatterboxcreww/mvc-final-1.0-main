// lib/core/utils/widget_lifecycle_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dependency_error_handler.dart';

/// A mixin to help manage widget lifecycle and prevent memory leaks
mixin WidgetLifecycleManager<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = [];
  final List<AnimationController> _animationControllers = [];
  final List<VoidCallback> _listeners = [];
  late final String _lifecycleId;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _lifecycleId = '${widget.runtimeType}_${hashCode}_${DateTime.now().millisecondsSinceEpoch}';
    DependencyErrorHandler().registerWidget(_lifecycleId);
  }

  /// Add a stream subscription to be automatically disposed
  void addSubscription(StreamSubscription subscription) {
    if (!_isDisposed) {
      _subscriptions.add(subscription);
    }
  }

  /// Add an animation controller to be automatically disposed
  void addAnimationController(AnimationController controller) {
    if (!_isDisposed) {
      _animationControllers.add(controller);
    }
  }

  /// Add a listener to be automatically removed
  void addListener(VoidCallback listener) {
    if (!_isDisposed) {
      _listeners.add(listener);
    }
  }

  /// Safe context check for async operations
  bool get isMountedAndActive => !_isDisposed && mounted && ModalRoute.of(context)?.isCurrent == true;

  /// Safe setState that checks if widget is still mounted and handles dependency errors
  void safeSetState(VoidCallback fn) {
    if (_isDisposed) {
      debugPrint('WidgetLifecycleManager: Attempted setState on disposed widget $_lifecycleId');
      return;
    }

    if (mounted) {
      try {
        setState(fn);
      } catch (e) {
        if (DependencyErrorHandler.isDependencyError(e)) {
          debugPrint('WidgetLifecycleManager: Dependency error in setState: $e');
          DependencyErrorHandler().handleDependencyError(e, StackTrace.current);
        } else {
          rethrow;
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    try {
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();

      // Dispose all animation controllers
      for (final controller in _animationControllers) {
        try {
          controller.dispose();
        } catch (e) {
          debugPrint('WidgetLifecycleManager: Error disposing animation controller: $e');
        }
      }
      _animationControllers.clear();

      // Remove all listeners
      _listeners.clear();

      // Unregister from dependency error handler
      DependencyErrorHandler().unregisterWidget(_lifecycleId);
    } catch (e) {
      debugPrint('WidgetLifecycleManager: Error during dispose: $e');
    }

    super.dispose();
  }
}

/// A safe wrapper for Provider operations
class SafeProviderWrapper {
  static T? safeRead<T>(BuildContext context) {
    try {
      if (context.mounted) {
        return context.read<T>();
      }
    } catch (e) {
      debugPrint('SafeProviderWrapper: Error reading provider $T: $e');
    }
    return null;
  }

  static T? safeWatch<T>(BuildContext context) {
    try {
      if (context.mounted) {
        return context.watch<T>();
      }
    } catch (e) {
      debugPrint('SafeProviderWrapper: Error watching provider $T: $e');
    }
    return null;
  }
}

/// A widget that safely handles async operations
class SafeAsyncBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  const SafeAsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<SafeAsyncBuilder<T>> createState() => _SafeAsyncBuilderState<T>();
}

class _SafeAsyncBuilderState<T> extends State<SafeAsyncBuilder<T>>
    with WidgetLifecycleManager {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (!isMountedAndActive) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData) {
          return widget.builder(context, snapshot.data as T);
        }

        return widget.loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator());
      },
    );
  }
}