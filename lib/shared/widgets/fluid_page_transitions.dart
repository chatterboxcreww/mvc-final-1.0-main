// lib/shared/widgets/fluid_page_transitions.dart
import 'package:flutter/material.dart';

class FluidPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Duration reverseDuration;

  FluidPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
    this.reverseDuration = const Duration(milliseconds: 400),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          settings: settings,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final slideTween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );
    final fadeTween = Tween(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: curve),
    );
    final scaleTween = Tween(begin: 0.95, end: 1.0).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: child,
        ),
      ),
    );
  }
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          settings: settings,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }
}

class SlideFromRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideFromRightPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

// Custom page transition extension
extension NavigatorExtensions on NavigatorState {
  Future<T?> pushFluid<T extends Object?>(Widget page) {
    return push<T>(FluidPageRoute(page: page));
  }

  Future<T?> pushFade<T extends Object?>(Widget page) {
    return push<T>(FadePageRoute(page: page));
  }

  Future<T?> pushSlideRight<T extends Object?>(Widget page) {
    return push<T>(SlideFromRightPageRoute(page: page));
  }
}
