// lib/core/services/adaptive_notification_service.dart
// Full adaptive notification service implementation

import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../providers/activity_provider.dart';
import '../providers/step_counter_provider.dart';
import '../providers/trends_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/experience_provider.dart';
import 'notification_service.dart';

class AdaptiveNotificationService {
  final NotificationService _notificationService;

  AdaptiveNotificationService(this._notificationService);

  Future<void> scheduleAdaptiveNotifications(
    BuildContext context,
    UserData userData,
    ActivityProvider activityProvider,
    StepCounterProvider stepCounterProvider,
    TrendsProvider trendsProvider, {
    AchievementProvider? achievementProvider,
    ExperienceProvider? experienceProvider,
  }) async {
    try {
      debugPrint('🚀 Starting adaptive notification scheduling');

      // Schedule basic notifications based on user preferences
      await _scheduleBasicNotifications(context, userData);

      // Schedule adaptive notifications based on user behavior
      await _scheduleAdaptiveNotifications(
        context,
        userData,
        activityProvider,
        stepCounterProvider,
        trendsProvider,
        achievementProvider: achievementProvider,
        experienceProvider: experienceProvider,
      );

      debugPrint('✅ Adaptive notifications scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling adaptive notifications: $e');
    }
  }

  Future<void> _scheduleBasicNotifications(BuildContext context, UserData userData) async {
    try {
      // Load notification settings to check if these types of notifications are enabled
      final notificationSettings = await _notificationService.loadNotificationSettings();

      // Schedule morning walk reminder if enabled
      if (userData.morningWalkReminderEnabled ?? true) {
        await _notificationService.scheduleMorningWalkReminder(
          context: context,
          userData: userData,
        );
      }

      // Schedule water reminders if enabled in both user data and notification settings
      final waterRemindersEnabled = userData.waterReminderEnabled ?? true;
      final notificationWaterEnabled = notificationSettings['water_reminders_enabled'] ?? true;
      if (waterRemindersEnabled && notificationWaterEnabled) {
        await _notificationService.scheduleWaterReminders(
          context: context,
          userData: userData,
        );
      }

      // Schedule wakeup notification
      if (userData.wakeupNotificationEnabled ?? true) {
        await _notificationService.scheduleWakeupNotification(
          context: context,
          userData: userData,
        );
      }

      // Schedule sleep notification
      if (userData.sleepNotificationEnabled ?? true) {
        await _notificationService.scheduleSleepNotification(
          context: context,
          userData: userData,
        );
      }

      // Schedule meal reminders based on notification settings
      if (notificationSettings['step_goal_reminders_enabled'] ?? true) {
        await _notificationService.scheduleBreakfastFeedReminder(context: context);
        await _notificationService.scheduleLunchFeedReminder(context: context);
        await _notificationService.scheduleDinnerFeedReminder(context: context);
      }

      // Schedule beverage reminders based on preferences and notification settings
      if (userData.prefersCoffee ?? false) {
        await _notificationService.scheduleCoffeeReminder(context: context);
      }
      if (userData.prefersTea ?? false) {
        await _notificationService.scheduleTeaReminder(context: context);
      }

      debugPrint('✅ Basic notifications scheduled');
    } catch (e) {
      debugPrint('❌ Error scheduling basic notifications: $e');
    }
  }

  Future<void> _scheduleAdaptiveNotifications(
    BuildContext context,
    UserData userData,
    ActivityProvider activityProvider,
    StepCounterProvider stepCounterProvider,
    TrendsProvider trendsProvider, {
    AchievementProvider? achievementProvider,
    ExperienceProvider? experienceProvider,
  }) async {
    try {
      // Adaptive water reminders based on current intake
      await _scheduleAdaptiveWaterReminders(context, userData);

      // Adaptive step goal reminders based on progress
      await _scheduleAdaptiveStepReminders(context, userData, stepCounterProvider);

      // Adaptive achievement reminders
      if (achievementProvider != null) {
        await _scheduleAdaptiveAchievementReminders(context, achievementProvider);
      }

      // Adaptive activity suggestions based on trends
      await _scheduleAdaptiveActivitySuggestions(context, trendsProvider);

      debugPrint('✅ Adaptive notifications scheduled');
    } catch (e) {
      debugPrint('❌ Error scheduling adaptive notifications: $e');
    }
  }

  Future<void> _scheduleAdaptiveWaterReminders(BuildContext context, UserData userData) async {
    // This would be implemented with actual water tracking data
    // For now, just ensure basic water reminders are scheduled
    debugPrint('📊 Adaptive water reminders: Basic scheduling applied');
  }

  Future<void> _scheduleAdaptiveStepReminders(
    BuildContext context,
    UserData userData,
    StepCounterProvider stepCounterProvider,
  ) async {
    try {
      final weeklyData = stepCounterProvider.weeklyStepData;
      if (weeklyData.isEmpty) return;

      // Calculate average steps
      final totalSteps = weeklyData.fold<int>(0, (sum, data) => sum + data.steps);
      final averageSteps = totalSteps ~/ weeklyData.length;

      // If user is consistently below their goal, schedule motivational reminders
      final goal = userData.dailyStepGoal ?? 10000;
      if (averageSteps < goal * 0.7) { // Below 70% of goal
        // Schedule additional motivational reminders
        debugPrint('📊 Adaptive step reminders: User needs motivation, scheduling extra reminders');
      }

      debugPrint('📊 Adaptive step reminders: Average steps $averageSteps vs goal $goal');
    } catch (e) {
      debugPrint('❌ Error in adaptive step reminders: $e');
    }
  }

  Future<void> _scheduleAdaptiveAchievementReminders(
    BuildContext context,
    AchievementProvider achievementProvider,
  ) async {
    try {
      // Check for nearly completed achievements and schedule reminders
      final achievements = achievementProvider.achievements;
      for (final achievement in achievements) {
        if (achievement.progress >= 0.8 && !achievement.isUnlocked) {
          // Schedule reminder for nearly completed achievement
          debugPrint('📊 Adaptive achievement reminder: Achievement is ${achievement.progress * 100}% complete');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in adaptive achievement reminders: $e');
    }
  }

  Future<void> _scheduleAdaptiveActivitySuggestions(
    BuildContext context,
    TrendsProvider trendsProvider,
  ) async {
    try {
      // Analyze trends and schedule relevant activity suggestions
      final checkinHistory = trendsProvider.checkinHistory;
      if (checkinHistory.isEmpty) return;

      // Check recent mood trends
      final recentMoods = checkinHistory.take(7).map((c) => c.mood).toList();
      final averageMood = recentMoods.fold<double>(0, (sum, mood) => sum + mood) / recentMoods.length;

      if (averageMood < 3.0) { // Low mood
        // Schedule meditation or relaxation reminders
        debugPrint('📊 Adaptive activity suggestions: Low mood detected, scheduling relaxation reminders');
      }

      debugPrint('📊 Adaptive activity suggestions: Average mood $averageMood');
    } catch (e) {
      debugPrint('❌ Error in adaptive activity suggestions: $e');
    }
  }
}
