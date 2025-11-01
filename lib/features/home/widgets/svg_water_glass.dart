// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\svg_water_glass.dart

// lib/features/home/widgets/svg_water_glass.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// A widget that displays an animated water glass using SVG assets
class SvgWaterGlass extends StatefulWidget {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onAddBubbles;

  const SvgWaterGlass({
    super.key,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    this.onAddBubbles,
  });

  @override
  State<SvgWaterGlass> createState() => SvgWaterGlassState();
}

class SvgWaterGlassState extends State<SvgWaterGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final List<BubbleParticle> _bubbles = [];
  final Random _random = Random();
  
  // Wave animation values
  double _waveOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller for the wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _waveController.addListener(() {
      setState(() {
        // Update wave offset for animation
        _waveOffset = _waveController.value * 20;
        
        // Update bubbles
        _updateBubbles();
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }
  
  void _updateBubbles() {
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      _bubbles[i].update();
      if (_bubbles[i].isExpired) {
        _bubbles.removeAt(i);
      }
    }
    
    // Add new bubbles occasionally
    if (_random.nextDouble() < 0.1 && _bubbles.length < 15) {
      _addBubble();
    }
  }

  void _addBubble() {
    _bubbles.add(BubbleParticle(
      position: Offset(
        20 + _random.nextDouble() * 60, // x position within glass
        100 + _random.nextDouble() * 50, // y position near bottom of glass
      ),
      velocity: Offset(
        (_random.nextDouble() - 0.5) * 0.8, // slight horizontal movement
        -1.5 - _random.nextDouble() * 2, // upward movement
      ),
      size: 2 + _random.nextDouble() * 4,
      lifespan: 60 + _random.nextInt(60), // frames of life
    ));
  }
  
  /// Adds a burst of bubbles to the water glass
  void addBubbleBurst() {
    for (int i = 0; i < 5; i++) {
      _addBubble();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate water height based on progress
    final waterHeight = 150 * widget.progress;
    
    return SizedBox(
      width: 100,
      height: 150,
      child: Stack(
        children: [
          // Glass container
          SvgPicture.asset(
            'assets/svg/glass.svg',
            width: 100,
            height: 150,
            colorFilter: ColorFilter.mode(
              Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey.withValues(alpha: 0.4),
              BlendMode.srcIn,
            ),
          ),
          
          // Water with clipping
          ClipPath(
            clipper: GlassClipper(),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: waterHeight,
                width: 100,
                child: Stack(
                  children: [
                    // Animated water with wave effect
                    Positioned(
                      bottom: 0,
                      left: -_waveOffset,
                      child: SizedBox(
                        width: 120, // Wider to allow for animation
                        height: waterHeight,
                        child: SvgPicture.asset(
                          'assets/svg/water.svg',
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            widget.primaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    
                    // Bubbles
                    ..._bubbles.map((bubble) {
                      // Only show bubbles below the water level
                      if (150 - bubble.position.dy <= waterHeight) {
                        return Positioned(
                          left: bubble.position.dx - bubble.size / 2,
                          top: bubble.position.dy - bubble.size / 2,
                          width: bubble.size,
                          height: bubble.size,
                          child: Opacity(
                            opacity: bubble.opacity,
                            child: SvgPicture.asset(
                              'assets/svg/bubble.svg',
                              colorFilter: ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper for the glass shape
class GlassClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height)
      ..lineTo(size.width * 0.2, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
