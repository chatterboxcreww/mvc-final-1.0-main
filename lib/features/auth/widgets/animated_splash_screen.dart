// lib/features/auth/widgets/animated_splash_screen.dart
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedSplashScreen extends StatefulWidget {
  // The onEnd property is no longer needed.
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _circleExpandAnimation;
  late Animation<double> _circleRetractAnimation;
  late Animation<double> _overlayFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _shimmerController =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _scaleAnimation = CurvedAnimation(
        parent: _controller, curve: const Interval(0.0, 0.25, curve: Curves.easeOut));
    _overlayFadeAnimation = CurvedAnimation(
        parent: _controller, curve: const Interval(0.20, 0.45, curve: Curves.easeOut));
    _circleExpandAnimation = CurvedAnimation(
        parent: _controller, curve: const Interval(0.25, 0.60, curve: Curves.decelerate));
    _circleRetractAnimation = CurvedAnimation(
        parent: _controller, curve: const Interval(0.65, 0.90, curve: Curves.easeIn));

    // The status listener that triggered navigation is removed.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The build method itself does not need any changes.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double circleOffset =
                75.0 * (_circleExpandAnimation.value - _circleRetractAnimation.value);
            return SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildEmojiCircle(
                      offset: circleOffset,
                      angle: -math.pi / 2,
                      color: Colors.green.shade300,
                      emoji: '💪'),
                  _buildEmojiCircle(
                      offset: circleOffset,
                      angle: math.pi,
                      color: Colors.blue.shade300,
                      emoji: '🥗'),
                  _buildEmojiCircle(
                      offset: circleOffset,
                      angle: 0,
                      color: Colors.teal.shade300,
                      emoji: '❤️'),
                  _buildEmojiCircle(
                      offset: circleOffset,
                      angle: math.pi / 2,
                      color: Colors.pink.shade200,
                      emoji: '💧'),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: const Color(0xFF40E0D0),
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text('TRKD',
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                  color: Colors.black)),
                          Opacity(
                            opacity: 1.0 - _overlayFadeAnimation.value,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    return ShaderMask(
                                      blendMode: BlendMode.srcATop,
                                      shaderCallback: (bounds) {
                                        return LinearGradient(
                                          colors: const [
                                            Colors.lightBlueAccent,
                                            Colors.greenAccent,
                                            Colors.pinkAccent,
                                            Colors.lightBlueAccent
                                          ],
                                          stops: const [0.0, 0.3, 0.6, 1.0],
                                          transform: GradientRotation(
                                              _shimmerController.value *
                                                  2 *
                                                  math.pi),
                                        ).createShader(bounds);
                                      },
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                              BorderRadius.circular(16))),
                                    );
                                  }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmojiCircle(
      {required double offset,
        required double angle,
        required Color color,
        required String emoji}) {
    return Transform.translate(
      offset: Offset(offset * math.cos(angle), offset * math.sin(angle)),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
      ),
    );
  }
}