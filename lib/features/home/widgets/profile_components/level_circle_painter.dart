// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\level_circle_painter.dart

// lib/features/home/widgets/profile_components/level_circle_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';

class LevelCirclePainter extends CustomPainter {
  final int level;
  final Color primaryColor;
  final Color backgroundColor;
  final double strokeWidth;
  final int xp;
  final int xpForNextLevel;
  
  // Cache paint objects for better performance
  late final Paint _backgroundPaint;
  late final Paint _progressPaint;
  late final TextPainter _textPainter;

  LevelCirclePainter({
    required this.level,
    required this.primaryColor,
    required this.backgroundColor,
    this.strokeWidth = 5.0,
    this.xp = 0,
    this.xpForNextLevel = 100,
  }) {
    // Initialize cached paint objects
    _backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
      
    _progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [primaryColor.withOpacity(0.5), primaryColor],
        startAngle: -pi / 2,
        endAngle: -pi / 2 + (2 * pi),
        stops: [0.0, xpForNextLevel > 0 ? xp / xpForNextLevel : 0.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    // Pre-create text painter
    _textPainter = TextPainter(
      text: TextSpan(
        text: level.toString(),
        style: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Draw background circle using cached paint
    canvas.drawCircle(center, radius, _backgroundPaint);
    
    // Update shader for progress paint with correct bounds
    _progressPaint.shader = SweepGradient(
      colors: [primaryColor.withOpacity(0.5), primaryColor],
      startAngle: -pi / 2,
      endAngle: -pi / 2 + (2 * pi),
      stops: [0.0, xpForNextLevel > 0 ? xp / xpForNextLevel : 0.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    // Calculate progress percentage toward next level
    final progressPercentage = xpForNextLevel > 0 ? xp / xpForNextLevel : 0.0;
    final sweepAngle = progressPercentage * 2 * pi;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      _progressPaint,
    );
    
    // Draw level text in the center using cached text painter
    _textPainter.paint(
      canvas,
      Offset(
        center.dx - _textPainter.width / 2,
        center.dy - _textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(LevelCirclePainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.xp != xp ||
        oldDelegate.xpForNextLevel != xpForNextLevel;
  }
}
