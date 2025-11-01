// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\xp_progress_painter.dart

// lib/features/home/widgets/xp_progress_painter.dart
import 'package:flutter/material.dart';

class XpProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  XpProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, paint);

    paint.color = progressColor;
    final progressRrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(progressRrect, paint);
  }

  @override
  bool shouldRepaint(covariant XpProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.progressColor != progressColor;
  }
}
