// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\providers\achievement_provider.dart

// lib/core/providers/achievement_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/achievement.dart';
import '../models/user_data.dart';
import '../services/notification_service.dart';
import '../services/daily_sync_service.dart';
import '../models/daily_checkin_data.dart'; // Import DailyCheckinData
import '../models/daily_step_data.dart'; // Import DailyStepData

class AchievementProvider with ChangeNotifier {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DailySyncService _dailySyncService = DailySyncService();
  
  // Flag to track if data is being loaded
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Track newly unlocked achievement for animation
  Achievement? _newlyUnlockedAchievement;
  Achievement? get newlyUnlockedAchievement => _newlyUnlockedAchievement;
  DateTime? _achievementUnlockTime;
  
  // Check if there's a recent achievement unlock to show popup
  bool get hasNewAchievement {
    if (_achievementUnlockTime == null || _newlyUnlockedAchievement == null) return false;
    final timeDiff = DateTime.now().difference(_achievementUnlockTime!);
    return timeDiff.inSeconds < 5; // Show for 5 seconds
  }
  
  // Clear achievement notification
  void clearAchievementNotification() {
    _newlyUnlockedAchievement = null;
    _achievementUnlockTime = null;
    notifyListeners();
  }
  
  // BuildContext for notifications
  BuildContext? _context;
  
  // Throttling variables to reduce Firebase calls
  final Map<String, DateTime> _lastCheckTimeByCategory = {};
  static const Duration _checkCooldown = Duration(seconds: 30); // Reduced to 30 seconds for better responsiveness
  
  // List of all achievements
  final List<Achievement> _achievements = [
    // Water intake achievements
    Achievement(
        id: 'water_1',
        name: 'Hydration Beginner',
        description: 'Drink 100 litres of water.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 100),
    Achievement(
        id: 'water_2',
        name: 'Hydration Enthusiast',
        description: 'Drink 500 litres of water.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 500),
    Achievement(
        id: 'water_3',
        name: 'Hydration Master',
        description: 'Drink 1000 litres of water.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 1000),
    Achievement(
        id: 'water_4',
        name: 'Hydration Champion',
        description: 'Drink 5000 litres of water.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 5000),
    Achievement(
        id: 'water_daily_1',
        name: 'Well Hydrated',
        description: 'Drink 8 glasses of water in a day.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 8),
    Achievement(
        id: 'water_daily_2',
        name: 'Super Hydrated',
        description: 'Drink 12 glasses of water in a day.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 12),
        
    // Water streak achievements
    Achievement(
        id: 'water_streak_7',
        name: '7-Day Hydration Streak',
        description: 'Drink 8 glasses of water for 7 days in a row.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 7),
    Achievement(
        id: 'water_streak_30',
        name: '30-Day Hydration Streak',
        description: 'Drink 8 glasses of water for 30 days in a row.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 30),
    Achievement(
        id: 'water_streak_90',
        name: '90-Day Hydration Streak',
        description: 'Drink 8 glasses of water for 90 days in a row.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 90),
        
    // Step count achievements
    Achievement(
        id: 'steps_1',
        name: 'First Steps',
        description: 'Walk 10,000 steps in a day.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 10000),
    Achievement(
        id: 'steps_2',
        name: 'Step Enthusiast',
        description: 'Walk 15,000 steps in a day.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 15000),
    Achievement(
        id: 'steps_3',
        name: 'Step Master',
        description: 'Walk 20,000 steps in a day.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 20000),
    Achievement(
        id: 'steps_total_1',
        name: 'Step Beginner',
        description: 'Walk a total of 100,000 steps.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 100000),
    Achievement(
        id: 'steps_total_2',
        name: 'Step Explorer',
        description: 'Walk a total of 500,000 steps.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 500000),
    Achievement(
        id: 'steps_total_3',
        name: 'Step Adventurer',
        description: 'Walk a total of 1,000,000 steps.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 1000000),
    Achievement(
        id: 'steps_total_4',
        name: 'Step Legend',
        description: 'Walk a total of 5,000,000 steps.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 5000000),
        
    // Step streak achievements
    Achievement(
        id: 'steps_streak_7',
        name: '7-Day Step Streak',
        description: 'Meet your daily step goal for 7 days in a row.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 7),
    Achievement(
        id: 'steps_streak_30',
        name: '30-Day Step Streak',
        description: 'Meet your daily step goal for 30 days in a row.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 30),
    Achievement(
        id: 'steps_streak_90',
        name: '90-Day Step Streak',
        description: 'Meet your daily step goal for 90 days in a row.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 90),
        
    // Sleep achievements
    // Achievement(
    //     id: 'sleep_1',
    //     name: 'Sleep Beginner',
    //     description: 'Get 7-9 hours of sleep for 7 days.',
    //     icon: 'assets/icons/sleep.svg',
    //     category: AchievementCategory.sleep,
    //     targetValue: 7),
    // Achievement(
    //     id: 'sleep_2',
    //     name: 'Sleep Regular',
    //     description: 'Get 7-9 hours of sleep for 30 days.',
    //     icon: 'assets/icons/sleep.svg',
    //     category: AchievementCategory.sleep,
    //     targetValue: 30),
    // Achievement(
    //     id: 'sleep_3',
    //     name: 'Sleep Master',
    //     description: 'Get 7-9 hours of sleep for 90 days.',
    //     icon: 'assets/icons/sleep.svg',
    //     category: AchievementCategory.sleep,
    //     targetValue: 90),
    // Achievement(
    //     id: 'sleep_streak_7',
    //     name: '7-Day Sleep Streak',
    //     description: 'Maintain a consistent sleep schedule for 7 days.',
    //     icon: 'assets/icons/sleep.svg',
    //     category: AchievementCategory.sleep,
    //     targetValue: 7),
    // Achievement(
    //     id: 'sleep_streak_30',
    //     name: '30-Day Sleep Streak',
    //     description: 'Maintain a consistent sleep schedule for 30 days.',
    //     icon: 'assets/icons/sleep.svg',
    //     category: AchievementCategory.sleep,
    //     targetValue: 30),
    //
    //
    //
    // Meditation achievements
    Achievement(
        id: 'meditation_1',
        name: 'Meditation Beginner',
        description: 'Meditate for 10 minutes.',
        icon: 'assets/icons/meditation.svg',
        category: AchievementCategory.meditation,
        targetValue: 10),
    Achievement(
        id: 'meditation_2',
        name: 'Meditation Enthusiast',
        description: 'Meditate for a total of 1 hour.',
        icon: 'assets/icons/meditation.svg',
        category: AchievementCategory.meditation,
        targetValue: 60),
    Achievement(
        id: 'meditation_3',
        name: 'Meditation Master',
        description: 'Meditate for a total of 10 hours.',
        icon: 'assets/icons/meditation.svg',
        category: AchievementCategory.meditation,
        targetValue: 600),
    Achievement(
        id: 'meditation_streak_7',
        name: '7-Day Meditation Streak',
        description: 'Meditate for 7 days in a row.',
        icon: 'assets/icons/meditation.svg',
        category: AchievementCategory.meditation,
        targetValue: 7),
    Achievement(
        id: 'meditation_streak_30',
        name: '30-Day Meditation Streak',
        description: 'Meditate for 30 days in a row.',
        icon: 'assets/icons/meditation.svg',
        category: AchievementCategory.meditation,
        targetValue: 30),
        
    // Level achievements
    Achievement(
        id: 'level_5',
        name: 'Level 5',
        description: 'Reach level 5.',
        icon: 'assets/icons/level.svg',
        category: AchievementCategory.level,
        targetValue: 5),
    Achievement(
        id: 'level_10',
        name: 'Level 10',
        description: 'Reach level 10.',
        icon: 'assets/icons/level.svg',
        category: AchievementCategory.level,
        targetValue: 10),
    Achievement(
        id: 'level_25',
        name: 'Level 25',
        description: 'Reach level 25.',
        icon: 'assets/icons/level.svg',
        category: AchievementCategory.level,
        targetValue: 25),
    Achievement(
        id: 'level_50',
        name: 'Level 50',
        description: 'Reach level 50.',
        icon: 'assets/icons/level.svg',
        category: AchievementCategory.level,
        targetValue: 50),
    Achievement(
        id: 'level_100',
        name: 'Level 100',
        description: 'Reach level 100.',
        icon: 'assets/icons/level.svg',
        category: AchievementCategory.level,
        targetValue: 100),
        
    // Combination achievements
    Achievement(
        id: 'combo_1',
        name: 'Health Enthusiast',
        description: 'Unlock 10 achievements.',
        icon: 'assets/icons/trophy.svg',
        category: AchievementCategory.combo,
        targetValue: 10),
    Achievement(
        id: 'combo_2',
        name: 'Health Expert',
        description: 'Unlock 25 achievements.',
        icon: 'assets/icons/trophy.svg',
        category: AchievementCategory.combo,
        targetValue: 25),
    Achievement(
        id: 'combo_3',
        name: 'Health Master',
        description: 'Unlock 50 achievements.',
        icon: 'assets/icons/trophy.svg',
        category: AchievementCategory.combo,
        targetValue: 50),
    Achievement(
        id: 'perfect_day',
        name: 'Perfect Day',
        description: 'Meet all your daily goals in a single day.',
        icon: 'assets/icons/trophy.svg',
        category: AchievementCategory.combo,
        targetValue: 1),
    Achievement(
        id: 'perfect_week',
        name: 'Perfect Week',
        description: 'Have 7 perfect days in a row.',
        icon: 'assets/icons/trophy.svg',
        category: AchievementCategory.combo,
        targetValue: 7),
    Achievement(
        id: 'perfect_month',
        name: 'Perfect Month',
        description: 'Have 30 perfect days in a row.',
        icon: 'assets/icons/trophy.svg',
        category: AchievementCategory.combo,
        targetValue: 30),
        
    // Social achievements
    Achievement(
        id: 'social_1',
        name: 'Social Butterfly',
        description: 'Leave 10 comments on food items.',
        icon: 'assets/icons/social.svg',
        category: AchievementCategory.social,
        targetValue: 10),
    Achievement(
        id: 'social_2',
        name: 'Community Contributor',
        description: 'Leave 50 comments on food items.',
        icon: 'assets/icons/social.svg',
        category: AchievementCategory.social,
        targetValue: 50),
    Achievement(
        id: 'social_3',
        name: 'Engagement Expert',
        description: 'Receive 10 likes on your comments.',
        icon: 'assets/icons/social.svg',
        category: AchievementCategory.social,
        targetValue: 10),
        
    // App usage achievements
    Achievement(
        id: 'app_usage_1',
        name: 'Health Enthusiast',
        description: 'Use the app for 7 consecutive days.',
        icon: 'assets/icons/app.svg',
        category: AchievementCategory.app,
        targetValue: 7),
    Achievement(
        id: 'app_usage_2',
        name: 'Health Devotee',
        description: 'Use the app for 30 consecutive days.',
        icon: 'assets/icons/app.svg',
        category: AchievementCategory.app,
        targetValue: 30),
    Achievement(
        id: 'app_usage_3',
        name: 'Health Lifestyle',
        description: 'Use the app for 100 consecutive days.',
        icon: 'assets/icons/app.svg',
        category: AchievementCategory.app,
        targetValue: 100),
    Achievement(
        id: 'app_usage_4',
        name: 'Health Transformation',
        description: 'Use the app for 365 consecutive days.',
        icon: 'assets/icons/app.svg',
        category: AchievementCategory.app,
        targetValue: 365),
        
    // Feature exploration achievements
    Achievement(
        id: 'explorer_1',
        name: 'Feature Explorer',
        description: 'Use all main features of the app at least once.',
        icon: 'assets/icons/explore.svg',
        category: AchievementCategory.explorer,
        targetValue: 1),
    Achievement(
        id: 'explorer_2',
        name: 'Customization Expert',
        description: 'Customize your profile, theme, and notifications.',
        icon: 'assets/icons/explore.svg',
        category: AchievementCategory.explorer,
        targetValue: 1),
    Achievement(
        id: 'explorer_3',
        name: 'Data Analyst',
        description: 'View all your health trends and statistics.',
        icon: 'assets/icons/explore.svg',
        category: AchievementCategory.explorer,
        targetValue: 1),
        
    // Time-based achievements
    Achievement(
        id: 'time_1',
        name: 'Early Bird',
        description: 'Log activity before 7 AM for 5 days.',
        icon: 'assets/icons/time.svg',
        category: AchievementCategory.time,
        targetValue: 5),
    Achievement(
        id: 'time_2',
        name: 'Night Owl',
        description: 'Log activity after 10 PM for 5 days.',
        icon: 'assets/icons/time.svg',
        category: AchievementCategory.time,
        targetValue: 5),
    Achievement(
        id: 'time_3',
        name: 'Weekend Warrior',
        description: 'Meet all your goals on weekends for 4 consecutive weekends.',
        icon: 'assets/icons/time.svg',
        category: AchievementCategory.time,
        targetValue: 4),
        
    // Seasonal achievements
    Achievement(
        id: 'seasonal_1',
        name: 'New Year, New Me',
        description: 'Be active on New Year\'s Day.',
        icon: 'assets/icons/seasonal.svg',
        category: AchievementCategory.seasonal,
        targetValue: 1),
    Achievement(
        id: 'seasonal_2',
        name: 'Summer Fitness',
        description: 'Meet all your goals for 7 consecutive days in summer.',
        icon: 'assets/icons/seasonal.svg',
        category: AchievementCategory.seasonal,
        targetValue: 1),
    Achievement(
        id: 'seasonal_3',
        name: 'Holiday Health',
        description: 'Maintain your health goals during holiday season.',
        icon: 'assets/icons/seasonal.svg',
        category: AchievementCategory.seasonal,
        targetValue: 1),
        
    // Challenge achievements
    Achievement(
        id: 'challenge_1',
        name: 'Challenge Accepted',
        description: 'Complete your first health challenge.',
        icon: 'assets/icons/challenge.svg',
        category: AchievementCategory.challenge,
        targetValue: 1),
    Achievement(
        id: 'challenge_2',
        name: 'Challenge Master',
        description: 'Complete 5 health challenges.',
        icon: 'assets/icons/challenge.svg',
        category: AchievementCategory.challenge,
        targetValue: 5),
    Achievement(
        id: 'challenge_3',
        name: 'Challenge Champion',
        description: 'Complete 10 health challenges.',
        icon: 'assets/icons/challenge.svg',
        category: AchievementCategory.challenge,
        targetValue: 10),
  ];

  // Constructor to initialize from Firebase
  AchievementProvider() {
    _initFromFirebase();
  }
  
  // Set the BuildContext for notifications
  void setContext(BuildContext context) {
    _context = context;
  }

  List<Achievement> get achievements => _achievements;
  
  List<Achievement> get unlockedAchievements =>
      _achievements.where((achievement) => achievement.isUnlocked).toList();
      
  List<Achievement> get allAchievements => _achievements;
  
  // Initialize achievements from Firebase
  Future<void> _initFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .doc('progress') // Changed from 'unlocked' to 'progress'
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final progressData = data['progress'] as Map<String, dynamic>? ?? {};

        // Update local achievements with progress from Firebase
        for (int i = 0; i < _achievements.length; i++) {
          final achievement = _achievements[i];
          if (progressData.containsKey(achievement.id)) {
            final achievementProgress = progressData[achievement.id];
            _achievements[i] = achievement.copyWith(
              isUnlocked: achievementProgress['isUnlocked'] ?? false,
              unlockedAt: achievementProgress['unlockedAt'] != null
                  ? DateTime.parse(achievementProgress['unlockedAt'])
                  : null,
              currentValue: achievementProgress['currentValue'] ?? 0,
              progress: (achievementProgress['currentValue'] ?? 0) /
                  (achievement.targetValue > 0 ? achievement.targetValue : 1),
            );
          }
        }
        print('Loaded achievement progress from Firebase');
      } else {
        // If no data exists, save the default values
        await _saveToLocalStorage();
        print('No achievement progress found, initialized with defaults');
      }
    } catch (e) {
      print('Error loading achievements from Firebase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Throttling variables for Firebase saves
  DateTime? _lastSaveTime;
  static const Duration _saveCooldown = Duration(minutes: 2); // Save only every 2 minutes

  // Save achievements to local storage (daily sync approach)
  Future<void> _saveToLocalStorage() async {
    try {
      await _dailySyncService.saveLocalAchievements(_achievements);
      debugPrint('AchievementProvider: Achievements saved to local storage');
    } catch (e) {
      debugPrint('AchievementProvider: Error saving achievements to local storage: $e');
    }
  }

  // Keep the Firebase save method for sleep time sync
  Future<void> saveToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Throttle Firebase saves to reduce database load
    final now = DateTime.now();
    if (_lastSaveTime != null && now.difference(_lastSaveTime!) < _saveCooldown) {
      debugPrint('Firebase save throttled - skipping (last save was ${now.difference(_lastSaveTime!).inMinutes} minutes ago)');
      return;
    }
    
    _lastSaveTime = now;

    try {
      final progressData = <String, dynamic>{};
      for (var achievement in _achievements) {
        progressData[achievement.id] = {
          'isUnlocked': achievement.isUnlocked,
          'unlockedAt': achievement.unlockedAt?.toIso8601String(),
          'currentValue': achievement.currentValue,
        };
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .doc('progress') // Changed from 'unlocked' to 'progress'
          .set({
        'progress': progressData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // FIX: Use merge to prevent overwriting

      print('Saved achievement progress to Firebase (throttled saves every 2 minutes)');
    } catch (e) {
      print('Error saving achievements to Firebase: $e');
    }
  }

  Future<void> checkAchievements(UserData userData,
      List<DailyStepData> weeklyStepData, List<DailyCheckinData> checkinHistory,
      [int? totalCommentCount]) async {
    
    // Improved throttling: check per category instead of global
    final now = DateTime.now();
    print('Performing achievement check with per-category throttling (30 second cooldown)');
    
    // Water achievements (with category-based throttling)
    if (_shouldCheckCategory('water', now)) {
      final totalWater = checkinHistory
          .map((e) => e.waterIntake)
          .fold(0, (currentSum, b) => currentSum + b);

      final totalWaterInLiters = totalWater * 0.24; // Assuming 1 glass is 0.24 liters

      // Total water achievements
      await updateAchievementProgress('water_1', totalWaterInLiters.toInt(), 100);
      await updateAchievementProgress('water_2', totalWaterInLiters.toInt(), 500);
      await updateAchievementProgress('water_3', totalWaterInLiters.toInt(), 1000);
      await updateAchievementProgress('water_4', totalWaterInLiters.toInt(), 5000);

      // Daily water achievements
      final todayWater = _getTodayWaterIntake(checkinHistory);
      await updateAchievementProgress('water_daily_1', todayWater, 8);
      await updateAchievementProgress('water_daily_2', todayWater, 12);

      // Water streak achievements
      final waterStreak = _getWaterStreak(checkinHistory);
      await updateAchievementProgress('water_streak_7', waterStreak, 7);
      await updateAchievementProgress('water_streak_30', waterStreak, 30);
      await updateAchievementProgress('water_streak_90', waterStreak, 90);
      
      _lastCheckTimeByCategory['water'] = now;
    }

    // Step achievements (with category-based throttling)
    if (_shouldCheckCategory('steps', now)) {
      final todaySteps = _getTodaySteps(weeklyStepData);
      await updateAchievementProgress('steps_1', todaySteps, 10000);
      await updateAchievementProgress('steps_2', todaySteps, 15000);
      await updateAchievementProgress('steps_3', todaySteps, 20000);

      // Total steps achievements
      final totalSteps = _getTotalSteps(weeklyStepData);
      await updateAchievementProgress('steps_total_1', totalSteps, 100000);
      await updateAchievementProgress('steps_total_2', totalSteps, 500000);
      await updateAchievementProgress('steps_total_3', totalSteps, 1000000);
      await updateAchievementProgress('steps_total_4', totalSteps, 5000000);

      // Step streak achievements
      final stepStreak = _getStepStreak(weeklyStepData);
      await updateAchievementProgress('steps_streak_7', stepStreak, 7);
      await updateAchievementProgress('steps_streak_30', stepStreak, 30);
      await updateAchievementProgress('steps_streak_90', stepStreak, 90);
      
      _lastCheckTimeByCategory['steps'] = now;
    }

    // Sleep achievements
    final sleepDays = _getConsistentSleepDays(checkinHistory);
    await updateAchievementProgress('sleep_1', sleepDays, 7);
    await updateAchievementProgress('sleep_2', sleepDays, 30);
    await updateAchievementProgress('sleep_3', sleepDays, 90);

    // Sleep streak achievements
    final sleepStreak = _getSleepStreak(checkinHistory);
    await updateAchievementProgress('sleep_streak_7', sleepStreak, 7);
    await updateAchievementProgress('sleep_streak_30', sleepStreak, 30);

    // Meditation achievements
    final meditationMinutes = _getTotalMeditationMinutes(checkinHistory);
    await updateAchievementProgress('meditation_1', meditationMinutes, 10);
    await updateAchievementProgress('meditation_2', meditationMinutes, 60);
    await updateAchievementProgress('meditation_3', meditationMinutes, 600);

    // Meditation streak achievements
    final meditationStreak = _getMeditationStreak(checkinHistory);
    await updateAchievementProgress('meditation_streak_7', meditationStreak, 7);
    await updateAchievementProgress('meditation_streak_30', meditationStreak, 30);

    // Level achievements
    await updateAchievementProgress('level_5', userData.level, 5);
    await updateAchievementProgress('level_10', userData.level, 10);
    await updateAchievementProgress('level_25', userData.level, 25);
    await updateAchievementProgress('level_50', userData.level, 50);
    await updateAchievementProgress('level_100', userData.level, 100);

    // Combination achievements
    final unlockedCount = unlockedAchievements.length;
    await updateAchievementProgress('combo_1', unlockedCount, 10);
    await updateAchievementProgress('combo_2', unlockedCount, 25);
    await updateAchievementProgress('combo_3', unlockedCount, 50);

    // Perfect day/week/month achievements
    if (_hasPerfectDay(checkinHistory)) {
      await _unlockAchievement('perfect_day');
    }

    final perfectDayStreak = _getPerfectDayStreak(checkinHistory);
    await updateAchievementProgress('perfect_week', perfectDayStreak, 7);
    await updateAchievementProgress('perfect_month', perfectDayStreak, 30);

    // Social achievements
    if (totalCommentCount != null) {
      await updateAchievementProgress('social_1', totalCommentCount, 10);
      await updateAchievementProgress('social_2', totalCommentCount, 50);

      // Assuming likes received is not directly available from raw data
      // You might need to fetch this separately or pass it as a parameter
      final likesReceived = 0; // Placeholder
      await updateAchievementProgress('social_3', likesReceived, 10);
    }

    // App usage achievements
    final appUsageStreak = _getAppUsageStreak(checkinHistory);
    await updateAchievementProgress('app_usage_1', appUsageStreak, 7);
    await updateAchievementProgress('app_usage_2', appUsageStreak, 30);
    await updateAchievementProgress('app_usage_3', appUsageStreak, 100);
    await updateAchievementProgress('app_usage_4', appUsageStreak, 365);

    // Feature exploration achievements
    if (_hasUsedAllFeatures(checkinHistory)) {
      await _unlockAchievement('explorer_1');
    }
    if (_hasCustomizedProfile()) {
      await _unlockAchievement('explorer_2');
    }
    if (_hasViewedAllTrends()) {
      await _unlockAchievement('explorer_3');
    }

    // Time-based achievements
    final earlyMorningDays = _getEarlyMorningActivityDays(checkinHistory);
    await updateAchievementProgress('time_1', earlyMorningDays, 5);

    final lateNightDays = _getLateNightActivityDays(checkinHistory);
    await updateAchievementProgress('time_2', lateNightDays, 5);

    final weekendWarriorCount = _getWeekendWarriorCount(checkinHistory);
    await updateAchievementProgress('time_3', weekendWarriorCount, 4);

    // Seasonal achievements
    if (_wasActiveOnNewYear(checkinHistory)) {
      await _unlockAchievement('seasonal_1');
    }
    if (_maintainedSummerGoals(checkinHistory)) {
      await _unlockAchievement('seasonal_2');
    }
    if (_maintainedHolidayGoals(checkinHistory)) {
      await _unlockAchievement('seasonal_3');
    }

    // Challenge achievements
    final challengesCompleted = _getCompletedChallengesCount();
    await updateAchievementProgress('challenge_1', challengesCompleted, 1);
    await updateAchievementProgress('challenge_2', challengesCompleted, 5);
    await updateAchievementProgress('challenge_3', challengesCompleted, 10);

    notifyListeners();

    // No immediate sync - wait for app lifecycle to trigger sync
    // await _saveToFirebase();
  }

  /// Check if we should check achievements for a specific category (throttling)
  bool _shouldCheckCategory(String category, DateTime now) {
    final lastCheck = _lastCheckTimeByCategory[category];
    if (lastCheck == null) return true;
    return now.difference(lastCheck) >= _checkCooldown;
  }

  // Helper methods to extract data from raw inputs
  int _getTodayWaterIntake(List<DailyCheckinData> checkinHistory) {
    final today = DateUtils.dateOnly(DateTime.now());
    final todayData = checkinHistory.firstWhere(
          (d) => DateUtils.isSameDay(d.date, today),
      orElse: () => DailyCheckinData(date: today, weight: 0),
    );
    return todayData.waterIntake;
  }

  int _getWaterStreak(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return 0;
    // Create a mutable copy before sorting
    final sortedHistory = List<DailyCheckinData>.from(checkinHistory);
    sortedHistory.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime today = DateUtils.dateOnly(DateTime.now());
    DateTime currentDate = today;
    for (int i = 0; i < 90; i++) {
      final dayData = sortedHistory.firstWhere(
            (d) => DateUtils.isSameDay(d.date, currentDate),
        orElse: () => DailyCheckinData(date: currentDate, weight: 0),
      );
      if (dayData.waterIntake >= 8) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _getTodaySteps(List<DailyStepData> weeklyStepData) {
    final today = DateUtils.dateOnly(DateTime.now());
    final todayData = weeklyStepData.firstWhere(
          (d) => DateUtils.isSameDay(d.date, today),
      orElse: () => DailyStepData(date: today, steps: 0, goal: 10000),
    );
    return todayData.steps;
  }

  int _getTotalSteps(List<DailyStepData> weeklyStepData) {
    return weeklyStepData.fold(0, (sum, data) => sum + data.steps);
  }

  int _getStepStreak(List<DailyStepData> weeklyStepData) {
    if (weeklyStepData.isEmpty) return 0;
    // Create a mutable copy before sorting
    final sortedData = List<DailyStepData>.from(weeklyStepData);
    sortedData.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime today = DateUtils.dateOnly(DateTime.now());
    DateTime currentDate = today;
    for (int i = 0; i < 90; i++) {
      final dayData = sortedData.firstWhere(
            (d) => DateUtils.isSameDay(d.date, currentDate),
        orElse: () => DailyStepData(date: currentDate, steps: 0, goal: 10000),
      );
      if (dayData.steps >= dayData.goal) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _getConsistentSleepDays(List<DailyCheckinData> checkinHistory) {
    return checkinHistory.where((data) => data.sleepHours >= 7 && data.sleepHours <= 9).length;
  }

  int _getSleepStreak(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return 0;
    // Create a copy of the list to avoid modifying unmodifiable list
    final sortedHistory = List<DailyCheckinData>.from(checkinHistory);
    sortedHistory.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime today = DateUtils.dateOnly(DateTime.now());
    DateTime currentDate = today;
    for (int i = 0; i < 90; i++) {
      final dayData = sortedHistory.firstWhere(
            (d) => DateUtils.isSameDay(d.date, currentDate),
        orElse: () => DailyCheckinData(date: currentDate, weight: 0),
      );
      if (dayData.sleepHours >= 7 && dayData.sleepHours <= 9) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _getTotalMeditationMinutes(List<DailyCheckinData> checkinHistory) {
    return checkinHistory.fold(0, (currentSum, data) => currentSum + data.meditationMinutes);
  }

  int _getMeditationStreak(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return 0;
    checkinHistory.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime today = DateUtils.dateOnly(DateTime.now());
    DateTime currentDate = today;
    for (int i = 0; i < 90; i++) {
      final dayData = checkinHistory.firstWhere(
            (d) => DateUtils.isSameDay(d.date, currentDate),
        orElse: () => DailyCheckinData(date: currentDate, weight: 0),
      );
      if (dayData.meditationMinutes > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool _hasPerfectDay(List<DailyCheckinData> checkinHistory) {
    final today = DateUtils.dateOnly(DateTime.now());
    final todayData = checkinHistory.firstWhere(
          (d) => DateUtils.isSameDay(d.date, today),
      orElse: () => DailyCheckinData(date: today, weight: 0),
    );
    return todayData.waterIntake >= 8 &&
        todayData.sleepHours >= 7 &&
        todayData.sleepHours <= 9 &&
        todayData.mealCount >= 3 &&
        todayData.meditationMinutes > 0;
  }

  int _getPerfectDayStreak(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return 0;
    checkinHistory.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime today = DateUtils.dateOnly(DateTime.now());
    DateTime currentDate = today;
    for (int i = 0; i < 90; i++) {
      final dayData = checkinHistory.firstWhere(
            (d) => DateUtils.isSameDay(d.date, currentDate),
        orElse: () => DailyCheckinData(date: currentDate, weight: 0),
      );
      if (dayData.waterIntake >= 8 &&
          dayData.sleepHours >= 7 &&
          dayData.sleepHours <= 9 &&
          dayData.mealCount >= 3 &&
          dayData.meditationMinutes > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _getAppUsageStreak(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return 0;
    checkinHistory.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime today = DateUtils.dateOnly(DateTime.now());
    DateTime currentDate = today;
    for (int i = 0; i < 365; i++) {
      final dayData = checkinHistory.firstWhere(
            (d) => DateUtils.isSameDay(d.date, currentDate),
        orElse: () => DailyCheckinData(date: currentDate, weight: 0),
      );
      if (dayData.mood != 3 ||
          dayData.waterIntake > 0 ||
          dayData.mealCount > 0 ||
          dayData.meditationMinutes > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool _hasUsedAllFeatures(List<DailyCheckinData> checkinHistory) {
    return checkinHistory.any((d) => d.waterIntake > 0) &&
        checkinHistory.any((d) => d.mealCount > 0) &&
        checkinHistory.any((d) => d.sleepHours > 0) &&
        checkinHistory.any((d) => d.meditationMinutes > 0);
  }

  bool _hasCustomizedProfile() {
    // This would need to be implemented with the UserDataProvider
    // to check if user has customized their profile
    return false; // Placeholder
  }

  bool _hasViewedAllTrends() {
    // This would need to be implemented with some tracking mechanism
    // to check if user has viewed all health trends
    return false; // Placeholder
  }

  int _getEarlyMorningActivityDays(List<DailyCheckinData> checkinHistory) {
    return checkinHistory.where((data) => data.date.hour < 7).length;
  }

  int _getLateNightActivityDays(List<DailyCheckinData> checkinHistory) {
    return checkinHistory.where((data) => data.date.hour >= 22).length;
  }

  int _getWeekendWarriorCount(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return 0;
    final weekendGroups = <String, List<DailyCheckinData>>{};
    for (var data in checkinHistory) {
      if (data.date.weekday == DateTime.saturday ||
          data.date.weekday == DateTime.sunday) {
        final weekNumber = '${data.date.year}-${(data.date.day / 7).floor()}';
        if (!weekendGroups.containsKey(weekNumber)) {
          weekendGroups[weekNumber] = [];
        }
        weekendGroups[weekNumber]!.add(data);
      }
    }
    int perfectWeekends = 0;
    for (var weekend in weekendGroups.values) {
      bool isPerfect = weekend.every((data) =>
          data.waterIntake >= 8 &&
          data.sleepHours >= 7 &&
          data.sleepHours <= 9 &&
          data.mealCount >= 3 &&
          data.meditationMinutes > 0);
      if (isPerfect) perfectWeekends++;
    }
    return perfectWeekends;
  }

  bool _wasActiveOnNewYear(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return false;
    return checkinHistory.any((data) =>
        data.date.month == 1 &&
        data.date.day == 1 &&
        (data.waterIntake > 0 ||
            data.mealCount > 0 ||
            data.meditationMinutes > 0));
  }

  bool _maintainedSummerGoals(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return false;
    final summerDays = checkinHistory.where((data) => data.date.month >= 6 && data.date.month <= 8).toList();
    if (summerDays.isEmpty) return false;
    summerDays.sort((a, b) => a.date.compareTo(b.date));
    int streak = 0;
    DateTime? lastDate;
    for (var data in summerDays) {
      if (lastDate != null && data.date.difference(lastDate).inDays != 1) {
        streak = 0;
      }
      if (data.waterIntake >= 8 &&
          data.sleepHours >= 7 &&
          data.sleepHours <= 9 &&
          data.mealCount >= 3 &&
          data.meditationMinutes > 0) {
        streak++;
        if (streak >= 7) return true;
      } else {
        streak = 0;
      }
      lastDate = data.date;
    }
    return false;
  }

  bool _maintainedHolidayGoals(List<DailyCheckinData> checkinHistory) {
    if (checkinHistory.isEmpty) return false;
    final holidayDays = checkinHistory.where((data) => data.date.month == 12).toList();
    if (holidayDays.isEmpty) return false;
    int goalDays = 0;
    for (var data in holidayDays) {
      if (data.waterIntake >= 6 && data.sleepHours >= 6 && data.mealCount >= 2) {
        goalDays++;
      }
    }
    return goalDays >= (holidayDays.length * 0.75);
  }

  int _getCompletedChallengesCount() {
    // This would need to be implemented with a ChallengeProvider
    // to track completed challenges
    return 0; // Placeholder
  }
    
    // Method specifically for checking level achievements
    void checkLevelAchievements(int level) {
      // Check for level-based achievements
      final levelAchievements = _achievements.where((achievement) =>
      achievement.category == AchievementCategory.level &&
          !achievement.isUnlocked &&
          achievement.targetValue <= level
      ).toList();

      for (final achievement in levelAchievements) {
        achievement.currentValue = level;
        if (achievement.currentValue >= achievement.targetValue) {
          _unlockAchievement(achievement.id);
        }
      }

      notifyListeners();
    }

    // Method to acknowledge that the achievement animation has been shown (legacy method)
    void acknowledgeAchievementAnimation() {
      clearAchievementNotification();
    }
  
    // Update achievement progress
    Future<void> updateAchievementProgress(String id, int currentValue, int targetValue) async {
      final index = _achievements.indexWhere((a) => a.id == id);
      if (index != -1) {
        final achievement = _achievements[index];
        if (!achievement.isUnlocked) {
          // Calculate progress (capped at 1.0)
          final progress = (currentValue / targetValue).clamp(0.0, 1.0);
          
          // Update the achievement with new progress
          _achievements[index] = achievement.copyWith(
            progress: progress,
            currentValue: currentValue,
            targetValue: targetValue,
          );
          
          // If progress is 100%, unlock the achievement
          if (progress >= 1.0) {
            await _unlockAchievement(id);
          } else {
            // Otherwise just notify listeners - no immediate Firebase sync
            notifyListeners();
            // await _saveToFirebase();
          }
        }
      }
    }

    Future<void> _unlockAchievement(String id) async {
      final achievement = _achievements.firstWhere((a) => a.id == id);
      if (!achievement.isUnlocked) {
        final index = _achievements.indexOf(achievement);
        final unlockedAchievement = Achievement(
          id: achievement.id,
          name: achievement.name,
          description: achievement.description,
          icon: achievement.icon,
          category: achievement.category,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: 1.0,
          currentValue: achievement.targetValue,
          targetValue: achievement.targetValue,
        );
        
        // Update the achievement in the list
        _achievements[index] = unlockedAchievement;
        
        // Set as newly unlocked achievement for animation
        _newlyUnlockedAchievement = unlockedAchievement;
        _achievementUnlockTime = DateTime.now();
        
        // Notify listeners immediately for UI feedback
        notifyListeners();
        
        // No immediate Firebase sync - wait for app lifecycle
        // await _saveToFirebase();
        
        print('Achievement unlocked: ${achievement.name}');
        
        // Notifications disabled
        // Achievement unlocked silently
      }
  }
}
