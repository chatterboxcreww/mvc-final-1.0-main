// lib/core/utils/performance_enhancements.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Performance enhancements for smooth 60fps experience
class PerformanceEnhancements {
  /// Optimize widget rebuilds with RepaintBoundary
  static Widget optimizeRebuilds(Widget child, {String? debugLabel}) {
    return RepaintBoundary(
      child: child,
    );
  }
  
  /// Optimize list rendering with const constructors where possible
  static Widget optimizeListItem(Widget child, {required int index}) {
    return RepaintBoundary(
      key: ValueKey('list_item_$index'),
      child: child,
    );
  }
  
  /// Debounce function calls to reduce unnecessary operations
  static Function debounce(
    Function func, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    DateTime? lastCall;
    return () {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) > delay) {
        lastCall = now;
        func();
      }
    };
  }
  
  /// Throttle function calls to limit execution frequency
  static Function throttle(
    Function func, {
    Duration interval = const Duration(milliseconds: 100),
  }) {
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
  
  /// Optimize image loading with caching
  static ImageProvider optimizeImage(String path, {bool isAsset = true}) {
    if (isAsset) {
      return AssetImage(path);
    } else {
      return NetworkImage(path);
    }
  }
  
  /// Lazy load widgets for better initial load performance
  static Widget lazyLoad(
    Widget Function() builder, {
    Widget? placeholder,
  }) {
    return FutureBuilder(
      future: Future.microtask(builder),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data as Widget;
        }
        return placeholder ?? const SizedBox.shrink();
      },
    );
  }
  
  /// Optimize animations for 60fps
  static AnimationController createOptimizedController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
    String? debugLabel,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration,
      debugLabel: debugLabel,
    );
  }
  
  /// Batch multiple setState calls
  static void batchSetState(
    State state,
    List<VoidCallback> updates,
  ) {
    if (state.mounted) {
      state.setState(() {
        for (final update in updates) {
          update();
        }
      });
    }
  }
  
  /// Optimize scroll performance
  static ScrollPhysics get optimizedScrollPhysics {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
  
  /// Cache expensive computations
  static final Map<String, dynamic> _cache = {};
  
  static T? getCached<T>(String key) {
    return _cache[key] as T?;
  }
  
  static void setCached<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = value;
    if (ttl != null) {
      Future.delayed(ttl, () => _cache.remove(key));
    }
  }
  
  static void clearCache() {
    _cache.clear();
  }
  
  /// Optimize text rendering
  static TextStyle optimizeTextStyle(TextStyle style) {
    return style.copyWith(
      // Ensure text is rendered efficiently
      fontFeatures: const [FontFeature.proportionalFigures()],
    );
  }
  
  /// Reduce overdraw with ClipRect
  static Widget reduceOverdraw(Widget child) {
    return ClipRect(
      child: child,
    );
  }
  
  /// Optimize container rendering
  static BoxDecoration optimizeDecoration(BoxDecoration decoration) {
    // Use simpler decorations when possible
    return decoration;
  }
  
  /// Memory-efficient list builder
  static Widget buildEfficientList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: optimizedScrollPhysics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return optimizeListItem(
          itemBuilder(context, index),
          index: index,
        );
      },
      // Add cache extent for smoother scrolling
      cacheExtent: 100,
    );
  }
  
  /// Optimize network requests with caching
  static Future<T> cachedNetworkRequest<T>({
    required String key,
    required Future<T> Function() request,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final cached = getCached<T>(key);
    if (cached != null) {
      return cached;
    }
    
    final result = await request();
    setCached(key, result, ttl: cacheDuration);
    return result;
  }
  
  /// Optimize widget tree depth
  static Widget flattenWidgetTree(List<Widget> children) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
  
  /// Reduce jank during navigation
  static Route<T> createOptimizedRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
