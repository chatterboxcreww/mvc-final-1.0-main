// lib/core/utils/stream_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// A comprehensive stream management utility
class StreamManager {
  static final Map<String, StreamController> _controllers = {};
  static final Map<String, StreamSubscription> _subscriptions = {};
  static final Map<String, Timer> _timers = {};

  /// Create a managed stream controller
  static StreamController<T> createController<T>(String id, {bool broadcast = false}) {
    // Close existing controller if it exists
    closeController(id);
    
    final controller = broadcast 
        ? StreamController<T>.broadcast()
        : StreamController<T>();
    
    _controllers[id] = controller;
    return controller;
  }

  /// Get an existing stream controller
  static StreamController<T>? getController<T>(String id) {
    return _controllers[id] as StreamController<T>?;
  }

  /// Create a managed subscription
  static StreamSubscription<T> createSubscription<T>(
    String id,
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    // Cancel existing subscription if it exists
    cancelSubscription(id);
    
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
    );
    
    _subscriptions[id] = subscription;
    return subscription;
  }

  /// Create a managed timer
  static Timer createTimer(String id, Duration duration, void Function() callback) {
    // Cancel existing timer if it exists
    cancelTimer(id);
    
    final timer = Timer(duration, callback);
    _timers[id] = timer;
    return timer;
  }

  /// Create a managed periodic timer
  static Timer createPeriodicTimer(
    String id, 
    Duration period, 
    void Function(Timer) callback
  ) {
    // Cancel existing timer if it exists
    cancelTimer(id);
    
    final timer = Timer.periodic(period, callback);
    _timers[id] = timer;
    return timer;
  }

  /// Close a specific stream controller
  static void closeController(String id) {
    final controller = _controllers[id];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _controllers.remove(id);
  }

  /// Cancel a specific subscription
  static void cancelSubscription(String id) {
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
  }

  /// Cancel a specific timer
  static void cancelTimer(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  /// Close all managed resources
  static void closeAll() {
    // Close all controllers
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();

    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Get status of all managed resources
  static Map<String, dynamic> getStatus() {
    return {
      'controllers': _controllers.length,
      'subscriptions': _subscriptions.length,
      'timers': _timers.length,
      'active_controllers': _controllers.values.where((c) => !c.isClosed).length,
      'active_timers': _timers.values.where((t) => t.isActive).length,
    };
  }
}

/// A mixin for widgets that need stream management
mixin StreamManagerMixin<T extends StatefulWidget> on State<T> {
  final Set<String> _managedIds = {};

  /// Create a managed stream controller with automatic cleanup
  StreamController<R> createManagedController<R>(String id, {bool broadcast = false}) {
    final fullId = '${widget.runtimeType}_${id}_${hashCode}';
    _managedIds.add(fullId);
    return StreamManager.createController<R>(fullId, broadcast: broadcast);
  }

  /// Create a managed subscription with automatic cleanup
  StreamSubscription<R> createManagedSubscription<R>(
    String id,
    Stream<R> stream,
    void Function(R) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    final fullId = '${widget.runtimeType}_${id}_${hashCode}';
    _managedIds.add(fullId);
    return StreamManager.createSubscription<R>(
      fullId,
      stream,
      onData,
      onError: onError,
      onDone: onDone,
    );
  }

  /// Create a managed timer with automatic cleanup
  Timer createManagedTimer(String id, Duration duration, void Function() callback) {
    final fullId = '${widget.runtimeType}_${id}_${hashCode}';
    _managedIds.add(fullId);
    return StreamManager.createTimer(fullId, duration, callback);
  }

  /// Create a managed periodic timer with automatic cleanup
  Timer createManagedPeriodicTimer(
    String id, 
    Duration period, 
    void Function(Timer) callback
  ) {
    final fullId = '${widget.runtimeType}_${id}_${hashCode}';
    _managedIds.add(fullId);
    return StreamManager.createPeriodicTimer(fullId, period, callback);
  }

  @override
  void dispose() {
    // Clean up all managed resources
    for (final id in _managedIds) {
      StreamManager.closeController(id);
      StreamManager.cancelSubscription(id);
      StreamManager.cancelTimer(id);
    }
    _managedIds.clear();
    super.dispose();
  }
}

/// A safe stream builder that handles errors and disposal properly
class SafeStreamBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot) builder;
  final T? initialData;

  const SafeStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.initialData,
  });

  @override
  State<SafeStreamBuilder<T>> createState() => _SafeStreamBuilderState<T>();
}

class _SafeStreamBuilderState<T> extends State<SafeStreamBuilder<T>>
    with StreamManagerMixin {
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: widget.stream,
      initialData: widget.initialData,
      builder: (context, snapshot) {
        if (!mounted) {
          return const SizedBox.shrink();
        }
        
        // Handle errors gracefully
        if (snapshot.hasError) {
          debugPrint('SafeStreamBuilder error: ${snapshot.error}');
          return Center(
            child: Text('Stream Error: ${snapshot.error}'),
          );
        }
        
        return widget.builder(context, snapshot);
      },
    );
  }
}