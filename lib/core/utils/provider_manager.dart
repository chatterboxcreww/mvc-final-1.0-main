// lib/core/utils/provider_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A safe provider manager that handles async operations properly
class SafeProviderManager {
  static final Map<String, StreamSubscription> _activeSubscriptions = {};
  static final Map<String, Timer> _debounceTimers = {};

  /// Safely execute an async operation with a provider
  static Future<T?> safeAsyncOperation<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? operationId,
    Duration? timeout,
  }) async {
    if (!context.mounted) return null;

    try {
      final future = operation();
      if (timeout != null) {
        return await future.timeout(timeout);
      }
      return await future;
    } catch (e) {
      debugPrint('SafeProviderManager: Async operation failed: $e');
      return null;
    }
  }

  /// Safely listen to a stream with automatic cleanup
  static StreamSubscription<T>? safeStreamListen<T>(
    BuildContext context,
    Stream<T> stream,
    void Function(T) onData, {
    String? subscriptionId,
    void Function(Object)? onError,
  }) {
    if (!context.mounted) return null;

    // Cancel existing subscription with same ID
    if (subscriptionId != null) {
      _activeSubscriptions[subscriptionId]?.cancel();
    }

    final subscription = stream.listen(
      (data) {
        if (context.mounted) {
          onData(data);
        }
      },
      onError: (error) {
        debugPrint('SafeProviderManager: Stream error: $error');
        onError?.call(error);
      },
    );

    if (subscriptionId != null) {
      _activeSubscriptions[subscriptionId] = subscription;
    }

    return subscription;
  }

  /// Debounced provider update to prevent rapid state changes
  static void debouncedUpdate(
    String operationId,
    VoidCallback operation, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimers[operationId]?.cancel();
    _debounceTimers[operationId] = Timer(delay, operation);
  }

  /// Clean up all active subscriptions and timers
  static void cleanup() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  /// Cancel a specific subscription
  static void cancelSubscription(String subscriptionId) {
    _activeSubscriptions[subscriptionId]?.cancel();
    _activeSubscriptions.remove(subscriptionId);
  }

  /// Cancel a specific debounce timer
  static void cancelDebounce(String operationId) {
    _debounceTimers[operationId]?.cancel();
    _debounceTimers.remove(operationId);
  }
}

/// A mixin for widgets that use providers safely
mixin SafeProviderMixin<T extends StatefulWidget> on State<T> {
  final List<String> _subscriptionIds = [];
  final List<String> _debounceIds = [];

  /// Safely read from a provider
  R? safeRead<R>() {
    try {
      if (mounted) {
        return context.read<R>();
      }
    } catch (e) {
      debugPrint('SafeProviderMixin: Error reading provider $R: $e');
    }
    return null;
  }

  /// Safely watch a provider
  R? safeWatch<R>() {
    try {
      if (mounted) {
        return context.watch<R>();
      }
    } catch (e) {
      debugPrint('SafeProviderMixin: Error watching provider $R: $e');
    }
    return null;
  }

  /// Add a managed subscription
  void addManagedSubscription(String id, StreamSubscription subscription) {
    _subscriptionIds.add(id);
    SafeProviderManager._activeSubscriptions[id] = subscription;
  }

  /// Add a managed debounce operation
  void addManagedDebounce(String id) {
    _debounceIds.add(id);
  }

  @override
  void dispose() {
    // Clean up managed subscriptions
    for (final id in _subscriptionIds) {
      SafeProviderManager.cancelSubscription(id);
    }

    // Clean up managed debounce timers
    for (final id in _debounceIds) {
      SafeProviderManager.cancelDebounce(id);
    }

    super.dispose();
  }
}

/// A safe consumer widget that handles provider errors gracefully
class SafeConsumer<T extends ChangeNotifier> extends StatefulWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const SafeConsumer({
    super.key,
    required this.builder,
    this.child,
    this.errorBuilder,
  });

  @override
  State<SafeConsumer<T>> createState() => _SafeConsumerState<T>();
}

class _SafeConsumerState<T extends ChangeNotifier> extends State<SafeConsumer<T>>
    with SafeProviderMixin {
  
  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<T>(
        builder: (context, value, child) {
          if (!mounted) {
            return const SizedBox.shrink();
          }
          return widget.builder(context, value, child);
        },
        child: widget.child,
      );
    } catch (error) {
      return widget.errorBuilder?.call(context, error) ??
          Center(child: Text('Provider Error: $error'));
    }
  }
}