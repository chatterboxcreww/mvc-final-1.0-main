// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\step_tracker_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../../core/providers/step_counter_provider.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../profile/screens/step_history_screen.dart';

class StepTrackerCard extends StatefulWidget {
  const StepTrackerCard({super.key});

  @override
  State<StepTrackerCard> createState() => _StepTrackerCardState();
}

class _StepTrackerCardState extends State<StepTrackerCard>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _progressAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StepCounterProvider, UserDataProvider>(
      builder: (context, stepProvider, userProvider, child) {
        final stepGoal = userProvider.userData.dailyStepGoal ?? 10000;
        final progress = stepProvider.todaySteps / stepGoal;
        final progressClamped = progress.clamp(0.0, 1.0);
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return GlassCard(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const StepHistoryScreen(),
            ));
          },
          child: Semantics(
            label: 'Step tracker card. Current steps: ${stepProvider.todaySteps}, Goal: $stepGoal. Tap to view step history.',
            button: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(stepProvider, stepGoal, colorScheme, textTheme),
                const SizedBox(height: 20),
                _buildProgressSection(progressClamped, progress, colorScheme),
                const SizedBox(height: 20),
                _buildStatsRow(stepProvider, context),
                const SizedBox(height: 16),
                _buildStatusIndicator(progress, stepProvider, colorScheme, textTheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(StepCounterProvider stepProvider, int stepGoal,
      ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: stepProvider.pedestrianStatus == 'walking'
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(colorScheme.primary.red, colorScheme.primary.green, colorScheme.primary.blue, 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Steps Today",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusDot(stepProvider),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "${NumberFormat('#,###').format(stepProvider.todaySteps)} / ${NumberFormat('#,###').format(stepGoal)}",
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildStatusDot(StepCounterProvider stepProvider) {
    Color dotColor;
    switch (stepProvider.pedestrianStatus) {
      case 'walking':
        dotColor = Colors.green;
        break;
      case 'stopped':
        dotColor = Colors.orange;
        break;
      default:
        dotColor = Colors.grey;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildProgressSection(double progressClamped, double progress,
      ColorScheme colorScheme) {
    return RepaintBoundary(
      child: Column(
        children: [
          // Circular Progress Indicator
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return RepaintBoundary(
                        child: CircularProgressIndicator(
                          value: progressClamped * _progressAnimation.value,
                          strokeWidth: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(progress),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(progressClamped * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(progress),
                      ),
                    ),
                    Text(
                      'of goal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Linear Progress Bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressClamped * _progressAnimation.value,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                    minHeight: 8,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(StepCounterProvider stepProvider, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(
          context,
          NumberFormat('#,###').format(stepProvider.caloriesBurned.toInt()),
          'Calories',
          Icons.local_fire_department_rounded,
          Colors.orange,
        ),
        _buildStatColumn(
          context,
          (stepProvider.distanceMeters / 1000).toStringAsFixed(1),
          'km',
          Icons.straighten_rounded,
          Colors.blue,
        ),
        _buildStatColumn(
          context,
          '${stepProvider.streak}',
          'Streak',
          Icons.emoji_events_rounded,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        borderRadius: 12,
        opacity: 0.05,
        gradientColors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(double progress, StepCounterProvider stepProvider,
      ColorScheme colorScheme, TextTheme textTheme) {
    if (progress >= 1.0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Achieved! 🎉',
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'You\'ve exceeded your daily step target!',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (progress >= 0.8) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Almost there! Just ${NumberFormat('#,###').format((stepProvider.todaySteps * (1 / progress) - stepProvider.todaySteps).round())} more steps to go!',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Color.fromRGBO(colorScheme.primaryContainer.red, colorScheme.primaryContainer.green, colorScheme.primaryContainer.blue, 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color.fromRGBO(colorScheme.primary.red, colorScheme.primary.green, colorScheme.primary.blue, 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_walk, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stepProvider.pedestrianStatus == 'walking'
                    ? 'Keep walking! You\'re making great progress! 👍'
                    : 'Ready for a walk? Every step counts! 🚶‍♀️',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.8) return Colors.lightGreen;
    if (progress >= 0.5) return Theme.of(context).colorScheme.primary;
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }
}

