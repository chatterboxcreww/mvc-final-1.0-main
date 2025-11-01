// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\shared\widgets\fluid_page_route.dart

// lib/shared/widgets/fluid_page_route.dart
import 'package:flutter/material.dart';

class FluidPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FluidPageRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return ClipPath(
              clipper: WaveClipper(animation.value),
              child: child,
            );
          },
        );
}

class WaveClipper extends CustomClipper<Path> {
  final double progress;

  WaveClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
