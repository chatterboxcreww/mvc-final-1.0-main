// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\shared\widgets\animated_list_item.dart

import 'package:flutter/material.dart';
import '../../core/utils/performance_optimizer.dart';

class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = PerformanceOptimizer.createOptimizedController(
      duration: PerformanceOptimizer.getOptimizedDuration(widget.duration),
      vsync: this,
      debugLabel: 'AnimatedListItem',
    );

    // Create smooth fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PerformanceOptimizer.smoothCurve,
    ));

    // Create slide animation with subtle offset
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Create scale animation for smooth appearance
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation with staggered delay
    _startAnimation();
  }

  void _startAnimation() {
    final totalDelay = widget.delay * widget.index;
    Future.delayed(totalDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Enhanced version with custom animation types
class CustomAnimatedListItem extends StatefulWidget {
  const CustomAnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 450),
    this.animationType = AnimationType.slideUp,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final AnimationType animationType;

  @override
  State<CustomAnimatedListItem> createState() => _CustomAnimatedListItemState();
}

enum AnimationType {
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  fadeIn,
  scaleIn,
  rotateIn,
}

class _CustomAnimatedListItemState extends State<CustomAnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    switch (widget.animationType) {
      case AnimationType.slideUp:
        _offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_animation);
        break;
      case AnimationType.slideDown:
        _offsetAnimation = Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(_animation);
        break;
      case AnimationType.slideLeft:
        _offsetAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(_animation);
        break;
      case AnimationType.slideRight:
        _offsetAnimation = Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(_animation);
        break;
      case AnimationType.rotateIn:
        _rotationAnimation = Tween<double>(
          begin: 0.1,
          end: 0.0,
        ).animate(_animation);
        break;
      default:
        _offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation);
    }
  }

  void _startAnimation() {
    final totalDelay = widget.delay * widget.index;
    Future.delayed(totalDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget animatedChild = widget.child;

        switch (widget.animationType) {
          case AnimationType.fadeIn:
            animatedChild = FadeTransition(
              opacity: _animation,
              child: widget.child,
            );
            break;
          case AnimationType.scaleIn:
            animatedChild = ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(_animation),
              child: FadeTransition(
                opacity: _animation,
                child: widget.child,
              ),
            );
            break;
          case AnimationType.rotateIn:
            animatedChild = Transform.rotate(
              angle: _rotationAnimation.value,
              child: FadeTransition(
                opacity: _animation,
                child: widget.child,
              ),
            );
            break;
          default:
            animatedChild = FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: _offsetAnimation,
                child: widget.child,
              ),
            );
        }

        return animatedChild;
      },
    );
  }
}

