// lib/features/home/widgets/xp_notification_overlay.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/experience_provider.dart';
import '../../../core/providers/achievement_provider.dart';
import '../../../shared/widgets/level_up_popup.dart';
import '../../../shared/widgets/achievement_popup.dart';

class XpNotificationOverlay extends StatefulWidget {
  const XpNotificationOverlay({super.key});

  @override
  State<XpNotificationOverlay> createState() => _XpNotificationOverlayState();
}

class _XpNotificationOverlayState extends State<XpNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showXpNotification() {
    _controller.forward().then((_) {
      // Auto-clear the notification after animation completes
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.read<ExperienceProvider>().clearXpNotification();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExperienceProvider, AchievementProvider>(
      builder: (context, expProvider, achievementProvider, child) {
        // Check for achievement popup first (highest priority)
        if (achievementProvider.hasNewAchievement && achievementProvider.newlyUnlockedAchievement != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final achievement = achievementProvider.newlyUnlockedAchievement!;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AchievementPopup(
                title: achievement.name,
                description: achievement.description,
                icon: Icons.emoji_events, // Default icon for now
                iconColor: Colors.amber,
                xpReward: 50, // Default XP reward
                onClose: () {
                  achievementProvider.clearAchievementNotification();
                },
              ),
            );
          });
        }
        
        // Check for level up popup second (high priority)
        else if (expProvider.hasNewLevelUp && expProvider.newlyAchievedLevel != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => LevelUpPopup(
                newLevel: expProvider.newlyAchievedLevel!,
                xpGained: 0, // We don't track XP gained per level up
                onClose: () {
                  expProvider.clearLevelUpNotification();
                },
              ),
            );
          });
        }
        
        // Handle XP notification (lowest priority)
        if (expProvider.hasRecentXpGain && expProvider.lastXpGainMessage != null) {
          // Start animation if not already running
          if (_controller.status == AnimationStatus.dismissed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showXpNotification();
            });
          }

          return Positioned(
            top: 100,
            right: 20,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value, 0),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade600,
                              Colors.orange.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              expProvider.lastXpGainMessage ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          // Reset animation when no notification to show
          if (_controller.status != AnimationStatus.dismissed) {
            _controller.reset();
          }
          return const SizedBox.shrink();
        }
      },
    );
  }
}
