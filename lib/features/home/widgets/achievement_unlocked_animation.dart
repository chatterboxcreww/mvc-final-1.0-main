// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\achievement_unlocked_animation.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/models/achievement.dart';
import '../../../core/providers/achievement_provider.dart';

class AchievementUnlockedAnimation extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onAnimationComplete;

  const AchievementUnlockedAnimation({
    super.key,
    required this.achievement,
    required this.onAnimationComplete,
  });

  @override
  State<AchievementUnlockedAnimation> createState() => _AchievementUnlockedAnimationState();
}

class _AchievementUnlockedAnimationState extends State<AchievementUnlockedAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Scale animation: starts small, grows big, then shrinks slightly
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Opacity animation: fades in quickly, stays visible, then fades out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);
    
    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    // Start animations
    _controller.forward();
    _confettiController.play();
    
    // Call onAnimationComplete when the animation is done
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
    
    // Add a listener to ensure animation values are clamped
    _controller.addListener(() {
      // This ensures any animation value is properly clamped between 0.0 and 1.0
      if (_controller.value < 0.0 || _controller.value > 1.0) {
        _controller.value = _controller.value.clamp(0.0, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Determine background color based on achievement category
    Color backgroundColor;
    switch (widget.achievement.category) {
      case AchievementCategory.water:
        backgroundColor = Colors.blue.shade700;
        break;
      case AchievementCategory.steps:
        backgroundColor = Colors.green.shade700;
        break;
      case AchievementCategory.sleep:
        backgroundColor = Colors.indigo.shade700;
        break;

      case AchievementCategory.meditation:
        backgroundColor = Colors.purple.shade700;
        break;
      case AchievementCategory.level:
        backgroundColor = colorScheme.primary;
        break;
      default:
        backgroundColor = colorScheme.primary;
    }

    return Stack(
      children: [
        // Darkened background
        Container(
          color: Colors.black54,
        ),
        
        // Confetti effect
        Center(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
        
        // Achievement unlocked content
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ACHIEVEMENT UNLOCKED!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            widget.achievement.icon,
                            width: 60,
                            height: 60,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.achievement.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.achievement.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Congratulations!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AchievementUnlockedAnimationWrapper extends StatelessWidget {
  const AchievementUnlockedAnimationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final achievementProvider = Provider.of<AchievementProvider>(context);
    
    // Only show the animation if there's a newly unlocked achievement
    if (achievementProvider.newlyUnlockedAchievement == null) {
      return const SizedBox.shrink();
    }
    
    return AchievementUnlockedAnimation(
      achievement: achievementProvider.newlyUnlockedAchievement!,
      onAnimationComplete: () {
        // Acknowledge that the achievement animation has been shown
        achievementProvider.acknowledgeAchievementAnimation();
      },
    );
  }
}
