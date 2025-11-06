// lib/shared/widgets/glass_background.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated glass-morphism background with floating orbs
class GlassBackground extends StatelessWidget {
  final Widget child;
  final Animation<double>? animation;
  final List<Color>? orbColors;

  const GlassBackground({
    super.key,
    required this.child,
    this.animation,
    this.orbColors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated background with orbs
        if (animation != null)
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: animation!,
                colorScheme: Theme.of(context).colorScheme,
                orbColors: orbColors,
              ),
            ),
          ),
        // Content
        child,
      ],
    );
  }
}

/// Custom painter for glass background with floating orbs
class GlassBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final ColorScheme colorScheme;
  final List<Color>? orbColors;

  GlassBackgroundPainter({
    required this.animation,
    required this.colorScheme,
    this.orbColors,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    // Base gradient background
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF0D1B2A),
              const Color(0xFF1B263B),
              const Color(0xFF415A77),
            ]
          : [
              const Color(0xFFF0F4FF),
              const Color(0xFFE8F0FE),
              const Color(0xFFD6E4FF),
            ],
      stops: const [0.0, 0.5, 1.0],
    );

    final backgroundPaint = Paint()
      ..shader = backgroundGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw floating orbs
    final orbs = _generateOrbs(size);
    
    for (final orb in orbs) {
      final progress = (animation.value + orb.offset) % 1.0;
      final y = size.height * 0.2 + (size.height * 0.6) * math.sin(progress * math.pi * 2);
      final x = orb.x + math.cos(progress * math.pi * 2) * 30;
      
      // Create orb gradient
      final orbGradient = RadialGradient(
        colors: [
          orb.color.withOpacity(isDark ? 0.3 : 0.2),
          orb.color.withOpacity(isDark ? 0.15 : 0.1),
          orb.color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      final orbPaint = Paint()
        ..shader = orbGradient.createShader(
          Rect.fromCircle(
            center: Offset(x, y),
            radius: orb.radius,
          ),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.radius * 0.3);

      canvas.drawCircle(
        Offset(x, y),
        orb.radius,
        orbPaint,
      );
    }
  }

  List<GlassOrb> _generateOrbs(Size size) {
    final orbs = <GlassOrb>[];
    final random = math.Random(42);
    
    final defaultColors = orbColors ?? [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
    ];

    for (int i = 0; i < 8; i++) {
      orbs.add(GlassOrb(
        x: random.nextDouble() * size.width,
        radius: 60 + random.nextDouble() * 120,
        color: defaultColors[i % defaultColors.length],
        offset: random.nextDouble(),
      ));
    }

    return orbs;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GlassOrb {
  final double x;
  final double radius;
  final Color color;
  final double offset;

  GlassOrb({
    required this.x,
    required this.radius,
    required this.color,
    required this.offset,
  });
}
