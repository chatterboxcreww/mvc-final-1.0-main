// lib/core/theme/animations.dart
import 'package:flutter/material.dart';

/// Material 3 motion and animation constants
class AppAnimations {
  AppAnimations._();

  // Material 3 standard durations
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);
  
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);
  
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);
  
  static const Duration extraLong1 = Duration(milliseconds: 700);
  static const Duration extraLong2 = Duration(milliseconds: 800);
  static const Duration extraLong3 = Duration(milliseconds: 900);
  static const Duration extraLong4 = Duration(milliseconds: 1000);

  // Material 3 standard easing curves
  static const Curve emphasized = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  
  static const Curve standard = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0, 1.0);
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);

  // Common animation configurations
  static const Duration pageTransition = medium2;
  static const Curve pageTransitionCurve = emphasized;
  
  static const Duration dialogTransition = medium2;
  static const Curve dialogTransitionCurve = emphasizedDecelerate;
  
  static const Duration bottomSheetTransition = medium4;
  static const Curve bottomSheetTransitionCurve = emphasizedDecelerate;
  
  static const Duration fadeTransition = short4;
  static const Curve fadeTransitionCurve = standard;
  
  static const Duration scaleTransition = medium2;
  static const Curve scaleTransitionCurve = emphasized;
  
  static const Duration slideTransition = medium3;
  static const Curve slideTransitionCurve = emphasized;

  // Ripple and splash
  static const Duration ripple = medium2;
  static const Duration splash = short4;

  // Progress indicators
  static const Duration progressIndicator = long4;
  static const Curve progressIndicatorCurve = standard;

  // Snackbar
  static const Duration snackbarShow = short4;
  static const Duration snackbarHide = short3;
  static const Curve snackbarCurve = standardDecelerate;
}

/// Extension for easy animation usage
extension AnimatedWidgetExtensions on Widget {
  /// Fade in animation
  Widget fadeIn({
    Duration duration = AppAnimations.fadeTransition,
    Curve curve = AppAnimations.fadeTransitionCurve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: this,
    );
  }

  /// Scale in animation
  Widget scaleIn({
    Duration duration = AppAnimations.scaleTransition,
    Curve curve = AppAnimations.scaleTransitionCurve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: this,
    );
  }

  /// Slide in from bottom animation
  Widget slideInFromBottom({
    Duration duration = AppAnimations.slideTransition,
    Curve curve = AppAnimations.slideTransitionCurve,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.1), end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value * 50,
          child: child,
        );
      },
      child: this,
    );
  }
}
