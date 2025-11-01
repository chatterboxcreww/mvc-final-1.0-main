// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\custom_water_glass.dart

// lib/features/home/widgets/custom_water_glass.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/utils/performance_optimizer.dart';

/// A class representing a bubble particle in the water glass
class BubbleParticle {
  Offset position;
  Offset velocity;
  double size;
  int lifespan;
  int age = 0;
  double opacity = 0.7;

  BubbleParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.lifespan,
  });

  void update() {
    position = position + velocity;
    age++;
    
    // Fade out as the particle ages
    if (age > lifespan * 0.7) {
      opacity = opacity * 0.95;
    }
    
    // Slow down as it rises
    velocity = velocity * 0.98;
    
    // Add some wobble
    velocity = velocity + Offset(
      (Random().nextDouble() - 0.5) * 0.1,
      0,
    );
  }

  bool get isExpired => age >= lifespan;
}

/// A widget that displays an animated water glass using CustomPainter
class CustomWaterGlass extends StatefulWidget {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onAddBubbles;

  const CustomWaterGlass({
    super.key,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    this.onAddBubbles,
  });

  @override
  State<CustomWaterGlass> createState() => CustomWaterGlassState();
}

class CustomWaterGlassState extends State<CustomWaterGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<BubbleParticle> _bubbles = [];
  final Random _random = Random();
  
  // Wave animation values
  double _wavePhase = 0.0;
  
  // Track the last progress value to detect changes
  double _lastProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller for the wave animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    // Optimize animation listener to use AnimatedBuilder pattern
    _lastProgress = widget.progress;
  }

  @override
  void didUpdateWidget(CustomWaterGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if progress has changed
    if (widget.progress != _lastProgress) {
      // Add bubbles when water level changes
      if (widget.progress > _lastProgress) {
        addBubbleBurst();
      }
      _lastProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _updateBubbles() {
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      _bubbles[i].update();
      if (_bubbles[i].isExpired) {
        _bubbles.removeAt(i);
      }
    }
    
    // Optimized bubble generation with performance considerations
    final maxBubbles = PerformanceOptimizer.getOptimizedParticleCount(15);
    if (_random.nextDouble() < 0.03 && _bubbles.length < maxBubbles && widget.progress > 0.05) {
      _addBubble();
    }
  }

  void _addBubble() {
    final glassWidth = 100.0;
    final waterHeight = 150 * widget.progress;
    
    _bubbles.add(BubbleParticle(
      position: Offset(
        20 + _random.nextDouble() * (glassWidth - 40), // x position within glass
        150 - _random.nextDouble() * min(20, waterHeight), // y position near bottom of water
      ),
      velocity: Offset(
        (_random.nextDouble() - 0.5) * 0.8, // slight horizontal movement
        -1.5 - _random.nextDouble() * 2, // upward movement
      ),
      size: 2 + _random.nextDouble() * 4,
      lifespan: 60 + _random.nextInt(60), // frames of life
    ));
  }
  
  /// Adds a burst of bubbles to the water glass with performance optimization
  void addBubbleBurst() {
    final burstCount = PerformanceOptimizer.getOptimizedParticleCount(8);
    for (int i = 0; i < burstCount; i++) {
      _addBubble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 100,
        height: 150,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Update wave phase for animation
            _wavePhase = _animationController.value * 2 * pi;
            
            // Update bubbles only when needed
            _updateBubbles();
            
            return CustomPaint(
              painter: WaterGlassPainter(
                progress: widget.progress,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
                wavePhase: _wavePhase,
                bubbles: _bubbles,
                isDarkMode: Theme.of(context).brightness == Brightness.dark,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for the water glass and its contents
class WaterGlassPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double wavePhase;
  final List<BubbleParticle> bubbles;
  final bool isDarkMode;
  
  // Wave parameters
  final double _waveAmplitude = 3.0;
  final double _waveFrequency = 0.05;
  
  WaterGlassPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.wavePhase,
    required this.bubbles,
    required this.isDarkMode,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Draw glass container
    _drawGlass(canvas, size);
    
    // Calculate water height based on progress
    final waterHeight = height * progress;
    
    if (waterHeight > 0) {
      // Create a clip path for the water
      final clipPath = Path()
        ..moveTo(0, 0)
        ..lineTo(width, 0)
        ..lineTo(width * 0.8, height)
        ..lineTo(width * 0.2, height)
        ..close();
      
      canvas.save();
      canvas.clipPath(clipPath);
      
      // Draw water with wave effect
      _drawWater(canvas, size, waterHeight);
      
      // Draw bubbles
      _drawBubbles(canvas, size, waterHeight);
      
      canvas.restore();
    }
  }
  
  void _drawGlass(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Glass outline path
    final glassPath = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width * 0.8, height)
      ..lineTo(width * 0.2, height)
      ..close();
    
    // Glass fill paint
    final glassPaint = Paint()
      ..color = isDarkMode 
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    // Glass stroke paint
    final glassStrokePaint = Paint()
      ..color = isDarkMode 
          ? Colors.white.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw glass
    canvas.drawPath(glassPath, glassPaint);
    canvas.drawPath(glassPath, glassStrokePaint);
    
    // Add glass highlight
    final highlightPath = Path()
      ..moveTo(width * 0.1, height * 0.05)
      ..lineTo(width * 0.3, height * 0.05)
      ..lineTo(width * 0.25, height * 0.3)
      ..lineTo(width * 0.08, height * 0.3)
      ..close();
    
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  void _drawWater(Canvas canvas, Size size, double waterHeight) {
    final width = size.width;
    final height = size.height;
    
    // Calculate the bottom position of the water
    final waterBottom = height;
    final waterTop = waterBottom - waterHeight;
    
    // Create water gradient
    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.7),
        primaryColor,
      ],
    );
    
    final waterPaint = Paint()
      ..shader = waterGradient.createShader(
        Rect.fromLTWH(0, waterTop, width, waterHeight),
      );
    
    // Create wave path
    final wavePath = Path();
    
    // Start at the left edge of the water
    wavePath.moveTo(0, waterBottom);
    
    // Draw the wave
    for (double x = 0; x <= width + 10; x += 1) {
      final waveY = waterTop + _waveAmplitude * 
          sin((x * _waveFrequency) + wavePhase);
      wavePath.lineTo(x, waveY);
    }
    
    // Complete the path
    wavePath.lineTo(width, waterBottom);
    wavePath.lineTo(0, waterBottom);
    wavePath.close();
    
    // Draw the water
    canvas.drawPath(wavePath, waterPaint);
    
    // Add a second wave with different phase for more realistic effect
    final secondWavePath = Path();
    secondWavePath.moveTo(0, waterBottom);
    
    for (double x = 0; x <= width + 10; x += 1) {
      final waveY = waterTop + (_waveAmplitude * 0.5) * 
          sin((x * _waveFrequency * 1.5) + wavePhase + pi / 2);
      secondWavePath.lineTo(x, waveY);
    }
    
    secondWavePath.lineTo(width, waterBottom);
    secondWavePath.lineTo(0, waterBottom);
    secondWavePath.close();
    
    final secondWavePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3);
    
    canvas.drawPath(secondWavePath, secondWavePaint);
  }
  
  void _drawBubbles(Canvas canvas, Size size, double waterHeight) {
    final waterBottom = size.height;
    final waterTop = waterBottom - waterHeight;
    
    for (final bubble in bubbles) {
      // Only draw bubbles that are below the water level
      if (bubble.position.dy >= waterTop) {
        final bubblePaint = Paint()
          ..color = Colors.white.withValues(alpha: bubble.opacity)
          ..style = PaintingStyle.fill;
        
        // Draw bubble
        canvas.drawCircle(
          bubble.position,
          bubble.size / 2,
          bubblePaint,
        );
        
        // Add highlight to bubble
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: bubble.opacity * 0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(
            bubble.position.dx - bubble.size * 0.2,
            bubble.position.dy - bubble.size * 0.2,
          ),
          bubble.size * 0.3,
          highlightPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant WaterGlassPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
