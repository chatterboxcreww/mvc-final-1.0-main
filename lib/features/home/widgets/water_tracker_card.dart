// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\water_tracker_card.dart

// lib/features/home/widgets/water_tracker_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/trends_provider.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/providers/experience_provider.dart';
import '../../../core/providers/achievement_provider.dart';
import '../../../core/utils/performance_optimizer.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/services/daily_sync_service.dart';
import '../../../core/services/admin_analytics_service.dart';
import '../../../core/services/atomic_water_service.dart';
import 'custom_water_glass.dart';

class WaterTrackerCard extends StatefulWidget {
  const WaterTrackerCard({super.key});

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard> {
  final GlobalKey<CustomWaterGlassState> _waterGlassKey = GlobalKey<CustomWaterGlassState>();
  final AtomicWaterService _atomicWaterService = AtomicWaterService();
  int _currentWaterCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeWaterService();
  }

  /// Initialize atomic water service and load current count
  Future<void> _initializeWaterService() async {
    try {
      await _atomicWaterService.initialize();
      final count = await _atomicWaterService.getCurrentCount();
      if (mounted) {
        setState(() {
          _currentWaterCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error initializing water service: $e');
    }
  }

  /// Update water intake using atomic water service
  Future<void> _updateWaterIntake(int change) async {
    try {
      final userDataProvider = context.read<UserDataProvider>();
      final experienceProvider = context.read<ExperienceProvider>();
      final achievementProvider = context.read<AchievementProvider>();
      final stepProvider = context.read<StepCounterProvider>();
      final trendsProvider = context.read<TrendsProvider>();
      final adminAnalyticsService = Provider.of<AdminAnalyticsService>(context, listen: false);
      
      // Use atomic water service for thread-safe updates
      final newCount = await _atomicWaterService.updateWaterCount(change);
      
      // Update local state immediately for UI responsiveness
      if (mounted) {
        setState(() {
          _currentWaterCount = newCount;
        });
      }
      
      if (change > 0) {
        // Add bubble effect when water is added
        _waterGlassKey.currentState?.addBubbleBurst();
        
        // Only process XP gain when adding water, not when removing
        experienceProvider.addXpForWater(newCount, userDataProvider.userData);
        
        // Track water glass added for admin analytics
        adminAnalyticsService.trackFeatureUsage('water_glass_added');
      } else if (change < 0) {
        // Track water glass removed for admin analytics
        adminAnalyticsService.trackFeatureUsage('water_glass_removed');
      }
      
      // Update trends provider to keep analytics in sync
      final todayData = trendsProvider.getTodayCheckinData();
      todayData.waterIntake = newCount;
      trendsProvider.submitDailyCheckin(todayData, context: context);
      
      // Check achievements for water tracking updates
      achievementProvider.checkAchievements(
        userDataProvider.userData,
        stepProvider.weeklyStepData,
        trendsProvider.checkinHistory,
      );
    } catch (e) {
      debugPrint('Error updating water intake: $e');
      // Reload count from storage in case of error
      await _initializeWaterService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<TrendsProvider, UserDataProvider, ExperienceProvider, AchievementProvider, StepCounterProvider>(
      builder: (context, trendsProvider, userProvider, expProvider, achievementProvider, stepProvider, child) {
        final waterGoal = userProvider.userData.dailyWaterGoal ?? 8;
        // Use local state as single source of truth (synced with storage)
        final progress = _currentWaterCount / waterGoal;
        final progressClamped = progress.clamp(0.0, 1.0);
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Card(
          elevation: 8,
          color: colorScheme.surface,
          shadowColor: Color.fromRGBO(colorScheme.shadow.red, colorScheme.shadow.green, colorScheme.shadow.blue, 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Color.fromRGBO(colorScheme.outline.red, colorScheme.outline.green, colorScheme.outline.blue, 0.1),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop_rounded,
                          size: 28, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Water Intake",
                                style: textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                                "$_currentWaterCount / $waterGoal glasses",
                                style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  RepaintBoundary(
                    child: Row(
                      children: [
                        // Water glass animation
                        OptimizedRepaintBoundary(
                          debugLabel: 'WaterGlass',
                          child: CustomWaterGlass(
                            key: _waterGlassKey,
                            progress: progressClamped,
                            primaryColor: colorScheme.primary,
                            secondaryColor: colorScheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 20),
                        
                        // Controls and stats
                        Expanded(
                          child: Column(
                            children: [
                              // Water control buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: _currentWaterCount > 0
                                        ? () => _updateWaterIntake(-1)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    iconSize: 32,
                                    color: Colors.red[400],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '$_currentWaterCount',
                                        style: textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'glasses',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => _updateWaterIntake(1),
                                  icon: const Icon(Icons.add_circle_outline),
                                  iconSize: 32,
                                  color: colorScheme.primary.withOpacity(0.7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Progress bar
                            RepaintBoundary(
                              child: LinearProgressIndicator(
                                value: progressClamped,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0 ? colorScheme.secondary : colorScheme.primary,
                                ),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            Text(
                              '${(progressClamped * 100).toStringAsFixed(0)}% of daily goal',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            
                            if (progress >= 1.0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: colorScheme.secondary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: colorScheme.secondary, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Goal Achieved!',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),  // Closing RepaintBoundary
                  
                  const SizedBox(height: 12),
                  
                  // Hydration tip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                            color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tip: Drink water throughout the day for better hydration!',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

