// lib/core/utils/app_lifecycle_manager.dart
import 'package:flutter/material.dart';
import 'provider_manager.dart';
import 'stream_manager.dart';

/// A comprehensive app lifecycle manager
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  bool _isInitialized = false;
  AppLifecycleState _currentState = AppLifecycleState.resumed;

  /// Initialize the lifecycle manager
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      debugPrint('AppLifecycleManager: Initialized');
    }
  }

  /// Dispose the lifecycle manager
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _cleanup();
      _isInitialized = false;
      debugPrint('AppLifecycleManager: Disposed');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _currentState = state;
    
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }

  void _onAppPaused() {
    debugPrint('AppLifecycleManager: App paused - cleaning up resources');
    _cleanup();
  }

  void _onAppResumed() {
    debugPrint('AppLifecycleManager: App resumed');
    // Optionally reinitialize resources here
  }

  void _onAppDetached() {
    debugPrint('AppLifecycleManager: App detached - final cleanup');
    _cleanup();
  }

  void _onAppInactive() {
    debugPrint('AppLifecycleManager: App inactive');
  }

  void _onAppHidden() {
    debugPrint('AppLifecycleManager: App hidden');
  }

  void _cleanup() {
    try {
      SafeProviderManager.cleanup();
      StreamManager.closeAll();
      debugPrint('AppLifecycleManager: Cleanup completed');
    } catch (e) {
      debugPrint('AppLifecycleManager: Error during cleanup: $e');
    }
  }

  /// Get current app lifecycle state
  AppLifecycleState get currentState => _currentState;

  /// Check if app is in foreground
  bool get isInForeground => _currentState == AppLifecycleState.resumed;

  /// Get resource status
  Map<String, dynamic> getResourceStatus() {
    return {
      'lifecycle_state': _currentState.toString(),
      'is_initialized': _isInitialized,
      'stream_manager_status': StreamManager.getStatus(),
    };
  }
}

/// A widget that automatically manages app lifecycle
class LifecycleManagedApp extends StatefulWidget {
  final Widget child;

  const LifecycleManagedApp({
    super.key,
    required this.child,
  });

  @override
  State<LifecycleManagedApp> createState() => _LifecycleManagedAppState();
}

class _LifecycleManagedAppState extends State<LifecycleManagedApp> {
  final AppLifecycleManager _lifecycleManager = AppLifecycleManager();

  @override
  void initState() {
    super.initState();
    _lifecycleManager.initialize();
  }

  @override
  void dispose() {
    _lifecycleManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A debug widget to monitor resource usage
class ResourceMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const ResourceMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<ResourceMonitor> createState() => _ResourceMonitorState();
}

class _ResourceMonitorState extends State<ResourceMonitor> {
  final AppLifecycleManager _lifecycleManager = AppLifecycleManager();

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Resource Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                ...(_buildResourceInfo()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildResourceInfo() {
    final status = _lifecycleManager.getResourceStatus();
    return status.entries.map((entry) {
      return Text(
        '${entry.key}: ${entry.value}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      );
    }).toList();
  }
}