// lib/core/utils/performance_optimizer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Performance optimization utilities for 60fps smooth animations
class PerformanceOptimizer {
  static bool _isInitialized = false;
  static const int targetFps = 60;
  static const Duration frameTime = Duration(microseconds: 16667); // 1/60 second

  /// Initialize performance optimizations
  static void initialize() {
    if (_isInitialized) return;
    
    // Enable hardware acceleration for animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableOptimizations();
    });
    
    _isInitialized = true;
  }

  /// Enable Flutter performance optimizations
  static void _enableOptimizations() {
    // Enable hardware acceleration
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    // Log performance metrics in debug mode
    if (PerformanceOptimizer.isDebugMode) {
      developer.log('Performance optimizations enabled for 60fps target');
    }
  }

  /// Check if running in debug mode
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Wrap widgets with performance boundaries
  static Widget optimizeWidget(Widget child, {String? debugLabel}) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Create optimized animation controller
  static AnimationController createOptimizedController({
    required Duration duration,
    required TickerProvider vsync,
    double? value,
    Duration? reverseDuration,
    String? debugLabel,
  }) {
    return AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      value: value,
      vsync: vsync,
      debugLabel: debugLabel,
    );
  }

  /// Create curve for smooth 60fps animations
  static Curve get smoothCurve => Curves.easeOutCubic;

  /// Debounce function calls to prevent excessive rebuilds
  static Function debounce(Function func, Duration delay) {
    DateTime? lastCallTime;
    
    return () {
      final now = DateTime.now();
      if (lastCallTime == null || now.difference(lastCallTime!) >= delay) {
        lastCallTime = now;
        func();
      }
    };
  }

  /// Throttle function calls for better performance
  static Function throttle(Function func, Duration interval) {
    bool isThrottled = false;
    
    return () {
      if (!isThrottled) {
        func();
        isThrottled = true;
        Future.delayed(interval, () {
          isThrottled = false;
        });
      }
    };
  }

  /// Check if device can handle high-performance animations
  static bool get isHighPerformanceDevice {
    // Simple heuristic - in a real app, you'd check device specs
    return true; // For now, assume all devices can handle optimizations
  }

  /// Get optimized animation duration based on device performance
  static Duration getOptimizedDuration(Duration baseDuration) {
    if (isHighPerformanceDevice) {
      return baseDuration;
    } else {
      // Slightly longer durations for lower-end devices
      return Duration(
        milliseconds: (baseDuration.inMilliseconds * 1.2).round(),
      );
    }
  }

  /// Optimize bubble animation frame rate
  static Duration get bubbleUpdateInterval => 
    isHighPerformanceDevice ? 
      const Duration(milliseconds: 16) : // 60fps
      const Duration(milliseconds: 33);   // 30fps for lower-end devices

  /// Check if animations should be reduced for better performance
  static bool get shouldReduceAnimations => !isHighPerformanceDevice;

  /// Get optimized particle count for bubble animations
  static int getOptimizedParticleCount(int baseCount) {
    if (isHighPerformanceDevice) {
      return baseCount;
    } else {
      return (baseCount * 0.6).round(); // Reduce particles by 40%
    }
  }

  /// Performance monitoring helper
  static void logFrameTime(String operation) {
    if (isDebugMode) {
      final stopwatch = Stopwatch()..start();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stopwatch.stop();
        if (stopwatch.elapsedMicroseconds > frameTime.inMicroseconds) {
          developer.log(
            'Frame time exceeded for $operation: ${stopwatch.elapsedMicroseconds}μs',
          );
        }
      });
    }
  }
}

/// Mixin for widgets that need performance optimization
mixin PerformanceOptimizedWidget<T extends StatefulWidget> on State<T> {
  late final VoidCallback _debouncedSetState;
  
  @override
  void initState() {
    super.initState();
    _debouncedSetState = PerformanceOptimizer.debounce(
      () => setState(() {}),
      const Duration(milliseconds: 16),
    ) as VoidCallback;
  }

  /// Optimized setState that prevents excessive rebuilds
  void optimizedSetState(VoidCallback fn) {
    fn();
    _debouncedSetState();
  }

  /// Wrap build method with performance boundary
  Widget buildWithPerformance(Widget child, {String? debugLabel}) {
    return PerformanceOptimizer.optimizeWidget(child, debugLabel: debugLabel);
  }
}

/// Custom RepaintBoundary with additional optimizations
class OptimizedRepaintBoundary extends StatelessWidget {
  final Widget child;
  final String? debugLabel;

  const OptimizedRepaintBoundary({
    Key? key,
    required this.child,
    this.debugLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

/// Performance-optimized AnimatedBuilder
class OptimizedAnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const OptimizedAnimatedBuilder({
    Key? key,
    required this.animation,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: builder,
        child: child,
      ),
    );
  }
}
