// lib/core/services/daily_sync_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

import '../models/user_data.dart';
import '../models/daily_checkin_data.dart';
import '../models/daily_step_data.dart';
import '../models/achievement.dart';
import '../models/activity.dart';

/// Service responsible for managing daily sync operations between local storage and Firebase
/// Data is stored locally throughout the day and synced to Firebase at sleep time
/// Data is read from Firebase at wake up time and stored locally
class DailySyncService {
  static final DailySyncService _instance = DailySyncService._internal();
  factory DailySyncService() => _instance;
  DailySyncService._internal();

  // Keys for local storage
  static const String _userDataKey = 'daily_user_data';
  static const String _checkinDataKey = 'daily_checkin_data';
  static const String _stepDataKey = 'daily_step_data';
  static const String _achievementsKey = 'daily_achievements';
  static const String _activitiesKey = 'daily_activities';
  static const String _experienceDataKey = 'daily_experience_data';
  static const String _waterGlassCountKey = 'daily_water_glass_count';
  static const String _lastWaterResetDateKey = 'last_water_reset_date';
  static const String _lastStepResetDateKey = 'last_step_reset_date'; // Add this key
  static const String _lastWaterExpAwardDateKey = 'last_water_exp_award_date';
  static const String _lastSyncDateKey = 'last_sync_date';
  static const String _sleepSyncCompleteKey = 'sleep_sync_complete';
  static const String _wakeupSyncCompleteKey = 'wakeup_sync_complete';
  static const String _dailyDataVersionKey = 'daily_data_version';

  // Background task names
  static const String sleepSyncTaskName = 'daily_sleep_sync';
  static const String wakeupSyncTaskName = 'daily_wakeup_sync';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();
  
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _realTimeSyncEnabled = true; // Enable real-time sync for data safety

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    
    // Check if it's a new day and perform initial sync if needed
    await _checkAndPerformDailyReset();
    
    // Ensure step data persistence on app startup
    await _ensureStepDataPersistence();
    
    // Schedule daily sync tasks
    await _scheduleDailySyncTasks();
    
    debugPrint('DailySyncService initialized with real-time sync: $_realTimeSyncEnabled');
  }

  /// Enable or disable real-time sync
  void setRealTimeSyncEnabled(bool enabled) {
    _realTimeSyncEnabled = enabled;
    debugPrint('Real-time sync ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if real-time sync is enabled
  bool get isRealTimeSyncEnabled => _realTimeSyncEnabled;

  /// Check if it's a new day and perform reset if necessary
  Future<void> _checkAndPerformDailyReset() async {
    final lastSyncDate = _prefs?.getString(_lastSyncDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    
    if (lastSyncDate != today) {
      debugPrint('New day detected, performing daily reset');
      await _performDailyReset();
      await _prefs?.setString(_lastSyncDateKey, today);
    }
  }

  /// Perform daily reset - clear local data and prepare for new day
  Future<void> _performDailyReset() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    
    // Clear previous day's local data (but preserve certain persistent data)
    await prefs.remove(_checkinDataKey);
    await prefs.remove(_activitiesKey);
    await prefs.remove(_experienceDataKey);
    
    // CRITICAL FIX: Preserve step data for current day - don't reset steps during app refresh
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existingStepData = await getLocalStepData();
    final todaysSteps = existingStepData.where((step) => 
        step.date.toIso8601String().split('T')[0] == today).toList();
    
    // FIXED: Never clear step data during app restarts - only during actual new day
    // Check if this is a genuine new day (midnight passed) vs app restart
    final lastResetDate = prefs.getString(_lastStepResetDateKey) ?? '';
    final isActualNewDay = lastResetDate != today;
    
    if (isActualNewDay && todaysSteps.isEmpty) {
      // This is a genuine new day and we have no step data for today
      await prefs.remove(_stepDataKey);
      await prefs.setString(_lastStepResetDateKey, today);
      debugPrint('Step data cleared for genuine new day');
    } else {
      // Keep existing step data - either same day or we have today's data
      if (todaysSteps.isNotEmpty) {
        await saveLocalStepData(existingStepData);
        debugPrint('Preserved step data including today\'s ${todaysSteps.first.steps} steps');
      } else {
        debugPrint('No step data to preserve for today, but not clearing existing historical data');
      }
    }
    
    // Reset water glass count for new day only (NOT during app refresh)
    final lastWaterResetDate = prefs.getString(_lastWaterResetDateKey);
    if (lastWaterResetDate != today) {
      await prefs.setInt(_waterGlassCountKey, 0);
      await prefs.setString(_lastWaterResetDateKey, today);
      debugPrint('Water glass count reset to 0 for new day');
    } else {
      debugPrint('Same day - preserving water glass count');
    }
    
    await prefs.setString(_sleepSyncCompleteKey, 'false');
    await prefs.setString(_wakeupSyncCompleteKey, 'false');
    
    // Increment data version for cache invalidation
    final currentVersion = prefs.getInt(_dailyDataVersionKey) ?? 0;
    await prefs.setInt(_dailyDataVersionKey, currentVersion + 1);
    
    debugPrint('Daily reset completed - water glass count reset to 0, step data preserved');
  }

  /// Schedule background tasks for sleep and wakeup sync
  Future<void> _scheduleDailySyncTasks() async {
    try {
      // Cancel existing tasks
      await Workmanager().cancelByUniqueName(sleepSyncTaskName);
      await Workmanager().cancelByUniqueName(wakeupSyncTaskName);
      
      // Schedule sleep sync task (runs periodically to check if it's sleep time)
      await Workmanager().registerPeriodicTask(
        sleepSyncTaskName,
        sleepSyncTaskName,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(minutes: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
      );
      
      // Schedule wakeup sync task (runs periodically to check if it's wakeup time)
      await Workmanager().registerPeriodicTask(
        wakeupSyncTaskName,
        wakeupSyncTaskName,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
      );
      
      debugPrint('Daily sync tasks scheduled');
    } catch (e) {
      debugPrint('Error scheduling daily sync tasks: $e');
    }
  }

  /// Ensure step data persistence on app startup
  Future<void> _ensureStepDataPersistence() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existingStepData = await getLocalStepData();
      
      // Check if we have step data for today
      final todaysSteps = existingStepData.where((step) => 
          step.date.toIso8601String().split('T')[0] == today).toList();
      
      if (todaysSteps.isEmpty) {
        // Try to sync today's step data from Firebase if available
        await _syncTodaysStepDataFromFirebase();
        debugPrint('Attempted to sync today\'s step data from Firebase');
      } else {
        debugPrint('Today\'s step data already available: ${todaysSteps.length} entries');
      }
    } catch (e) {
      debugPrint('Error ensuring step data persistence: $e');
    }
  }

  /// Sync today's step data from Firebase
  Future<void> _syncTodaysStepDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(today)
          .get();
          
      if (doc.exists) {
        final stepData = DailyStepData.fromJson(doc.data()!);
        final existingStepData = await getLocalStepData();
        
        // Remove any existing data for today and add the Firebase data
        existingStepData.removeWhere((data) => 
            data.date.toIso8601String().split('T')[0] == today);
        existingStepData.add(stepData);
        
        await saveLocalStepData(existingStepData);
        debugPrint('Today\'s step data synced from Firebase: ${stepData.steps} steps');
      }
    } catch (e) {
      debugPrint('Error syncing today\'s step data from Firebase: $e');
    }
  }

  /// Check if it's sleep time and perform sync to Firebase
  Future<bool> performSleepTimeSync() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final prefs = _prefs ?? await SharedPreferences.getInstance();
      
      // Check if sleep sync already completed today
      final sleepSyncComplete = prefs.getString(_sleepSyncCompleteKey) == 'true';
      if (sleepSyncComplete) return true;

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection for sleep sync');
        return false;
      }

      // Check if it's sleep time (this should be called by background task at appropriate time)
      if (!await _isSleepTime()) return false;

      debugPrint('Performing sleep time sync to Firebase');

      // Sync all local data to Firebase
      await _syncUserDataToFirebase();
      await _syncCheckinDataToFirebase();
      await _syncStepDataToFirebase();
      await _syncAchievementsToFirebase();
      await _syncActivitiesToFirebase();
      await _syncExperienceDataToFirebase();
      await _syncWaterGlassCountToFirebase();

      // Mark sleep sync as complete
      await prefs.setString(_sleepSyncCompleteKey, 'true');
      
      debugPrint('Sleep time sync completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error during sleep time sync: $e');
      return false;
    }
  }

  /// Check if it's wakeup time and sync from Firebase to local storage
  Future<bool> performWakeupTimeSync() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final prefs = _prefs ?? await SharedPreferences.getInstance();
      
      // Check if wakeup sync already completed today
      final wakeupSyncComplete = prefs.getString(_wakeupSyncCompleteKey) == 'true';
      if (wakeupSyncComplete) return true;

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection for wakeup sync');
        return false;
      }

      // Check if it's wakeup time
      if (!await _isWakeupTime()) return false;

      debugPrint('Performing wakeup time sync from Firebase');

      // Sync data from Firebase to local storage
      await _syncUserDataFromFirebase();
      await _syncCheckinDataFromFirebase();
      await _syncStepDataFromFirebase();
      await _syncAchievementsFromFirebase();
      await _syncActivitiesFromFirebase();
      await _syncExperienceDataFromFirebase();
      await _syncWaterGlassCountFromFirebase();

      // Mark wakeup sync as complete
      await prefs.setString(_wakeupSyncCompleteKey, 'true');
      
      debugPrint('Wakeup time sync completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error during wakeup time sync: $e');
      return false;
    }
  }

  /// Check if current time is sleep time based on user's sleep schedule
  Future<bool> _isSleepTime() async {
    try {
      final userData = await getLocalUserData();
      if (userData?.sleepTime == null) return false;

      final now = DateTime.now();
      final sleepHour = userData!.sleepTime!.hour;
      final sleepMinute = userData.sleepTime!.minute;
      
      // Check if current time is within 30 minutes of sleep time
      final sleepDateTime = DateTime(now.year, now.month, now.day, sleepHour, sleepMinute);
      final timeDifference = now.difference(sleepDateTime).abs();
      
      return timeDifference.inMinutes <= 30;
    } catch (e) {
      debugPrint('Error checking sleep time: $e');
      return false;
    }
  }

  /// Check if current time is wakeup time based on user's schedule
  Future<bool> _isWakeupTime() async {
    try {
      final userData = await getLocalUserData();
      if (userData?.wakeupTime == null) return false;

      final now = DateTime.now();
      final wakeupHour = userData!.wakeupTime!.hour;
      final wakeupMinute = userData.wakeupTime!.minute;
      
      // Check if current time is within 30 minutes of wakeup time
      final wakeupDateTime = DateTime(now.year, now.month, now.day, wakeupHour, wakeupMinute);
      final timeDifference = now.difference(wakeupDateTime).abs();
      
      return timeDifference.inMinutes <= 30;
    } catch (e) {
      debugPrint('Error checking wakeup time: $e');
      return false;
    }
  }

  // Local Storage Methods

  /// Save user data to local storage
  Future<void> saveLocalUserData(UserData userData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final userDataJson = jsonEncode(userData.toJson());
      await prefs.setString(_userDataKey, userDataJson);
      debugPrint('User data saved to local storage');
      
      // Immediate sync to Firebase if real-time sync is enabled
      if (_realTimeSyncEnabled) {
        await _syncUserDataToFirebaseImmediate(userData);
      }
    } catch (e) {
      debugPrint('Error saving user data to local storage: $e');
    }
  }

  /// Get user data from local storage
  Future<UserData?> getLocalUserData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_userDataKey);
      if (userDataJson != null) {
        final userData = UserData.fromJson(jsonDecode(userDataJson));
        return userData;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data from local storage: $e');
      return null;
    }
  }

  /// Save checkin data to local storage
  Future<void> saveLocalCheckinData(DailyCheckinData checkinData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final checkinDataJson = jsonEncode(checkinData.toJson());
      await prefs.setString(_checkinDataKey, checkinDataJson);
      debugPrint('Checkin data saved to local storage');
      
      // Immediate sync to Firebase if real-time sync is enabled
      if (_realTimeSyncEnabled) {
        await _syncCheckinDataToFirebaseImmediate(checkinData);
      }
    } catch (e) {
      debugPrint('Error saving checkin data to local storage: $e');
    }
  }

  /// Get checkin data from local storage
  Future<DailyCheckinData?> getLocalCheckinData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final checkinDataJson = prefs.getString(_checkinDataKey);
      if (checkinDataJson != null) {
        return DailyCheckinData.fromJson(jsonDecode(checkinDataJson));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting checkin data from local storage: $e');
      return null;
    }
  }

  /// Save step data to local storage
  Future<void> saveLocalStepData(List<DailyStepData> stepData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final stepDataJson = jsonEncode(stepData.map((data) => data.toJson()).toList());
      await prefs.setString(_stepDataKey, stepDataJson);
      debugPrint('Step data saved to local storage');
      
      // Immediate sync to Firebase if real-time sync is enabled
      if (_realTimeSyncEnabled) {
        await _syncStepDataToFirebaseImmediate(stepData);
      }
    } catch (e) {
      debugPrint('Error saving step data to local storage: $e');
    }
  }

  /// Get step data from local storage
  Future<List<DailyStepData>> getLocalStepData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final stepDataJson = prefs.getString(_stepDataKey);
      if (stepDataJson != null) {
        final List<dynamic> jsonList = jsonDecode(stepDataJson);
        return jsonList.map((json) => DailyStepData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting step data from local storage: $e');
      return [];
    }
  }

  /// Save achievements to local storage
  Future<void> saveLocalAchievements(List<Achievement> achievements) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final achievementsJson = jsonEncode(achievements.map((achievement) => achievement.toJson()).toList());
      await prefs.setString(_achievementsKey, achievementsJson);
      debugPrint('Achievements saved to local storage');
      
      // Immediate sync to Firebase if real-time sync is enabled
      if (_realTimeSyncEnabled) {
        await _syncAchievementsToFirebaseImmediate(achievements);
      }
    } catch (e) {
      debugPrint('Error saving achievements to local storage: $e');
    }
  }

  /// Get achievements from local storage
  Future<List<Achievement>> getLocalAchievements() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      if (achievementsJson != null) {
        final List<dynamic> jsonList = jsonDecode(achievementsJson);
        return jsonList.map((json) => Achievement.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting achievements from local storage: $e');
      return [];
    }
  }

  /// Save activities to local storage
  Future<void> saveLocalActivities(List<Activity> activities) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(activities.map((activity) => activity.toJson()).toList());
      await prefs.setString(_activitiesKey, activitiesJson);
      debugPrint('Activities saved to local storage');
      
      // Immediate sync to Firebase if real-time sync is enabled
      if (_realTimeSyncEnabled) {
        await _syncActivitiesToFirebaseImmediate(activities);
      }
    } catch (e) {
      debugPrint('Error saving activities to local storage: $e');
    }
  }

  /// Get activities from local storage
  Future<List<Activity>> getLocalActivities() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString(_activitiesKey);
      if (activitiesJson != null) {
        final List<dynamic> jsonList = jsonDecode(activitiesJson);
        return jsonList.map((json) => Activity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting activities from local storage: $e');
      return [];
    }
  }

  /// Save experience data to local storage
  Future<void> saveLocalExperienceData(Map<String, dynamic> experienceData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final experienceDataJson = jsonEncode(experienceData);
      await prefs.setString(_experienceDataKey, experienceDataJson);
      debugPrint('Experience data saved to local storage');
      
      // Immediate sync to Firebase if real-time sync is enabled
      if (_realTimeSyncEnabled) {
        await _syncExperienceDataToFirebaseImmediate(experienceData);
      }
    } catch (e) {
      debugPrint('Error saving experience data to local storage: $e');
    }
  }

  /// Get experience data from local storage
  Future<Map<String, dynamic>> getLocalExperienceData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final experienceDataJson = prefs.getString(_experienceDataKey);
      if (experienceDataJson != null) {
        return Map<String, dynamic>.from(jsonDecode(experienceDataJson));
      }
      return {};
    } catch (e) {
      debugPrint('Error getting experience data from local storage: $e');
      return {};
    }
  }

  // Water Glass Count Methods

  /// Save water glass count to local storage
  Future<void> saveWaterGlassCount(int count) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setInt(_waterGlassCountKey, count);
      debugPrint('Water glass count saved: $count');
      
      // Immediate sync to Firebase if real-time sync is enabled
      if (_realTimeSyncEnabled) {
        await _syncWaterGlassCountToFirebaseImmediate(count);
      }
    } catch (e) {
      debugPrint('Error saving water glass count: $e');
    }
  }

  /// Get water glass count from local storage
  Future<int> getWaterGlassCount() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      return prefs.getInt(_waterGlassCountKey) ?? 0;
    } catch (e) {
      debugPrint('Error getting water glass count: $e');
      return 0;
    }
  }

  /// Increment water glass count
  Future<int> incrementWaterGlassCount() async {
    try {
      final currentCount = await getWaterGlassCount();
      final newCount = currentCount + 1;
      await saveWaterGlassCount(newCount);
      
      // Check for 9-glass milestone and award experience
      if (newCount == 9) {
        await _awardWaterMilestoneExperience();
      }
      
      debugPrint('Water glass count incremented to: $newCount');
      return newCount;
    } catch (e) {
      debugPrint('Error incrementing water glass count: $e');
      return await getWaterGlassCount();
    }
  }

  /// Award experience points for reaching 9 glasses milestone
  Future<void> _awardWaterMilestoneExperience() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      
      // Check if experience was already awarded today
      final lastExpAwardDate = prefs.getString(_lastWaterExpAwardDateKey);
      if (lastExpAwardDate == today) {
        debugPrint('Water milestone experience already awarded today');
        return;
      }
      
      // Award experience points (e.g., 50 XP for 9 glasses)
      const int waterMilestoneExp = 50;
      final experienceData = await getLocalExperienceData();
      final currentExp = experienceData['totalExp'] as int? ?? 0;
      final newExp = currentExp + waterMilestoneExp;
      
      experienceData['totalExp'] = newExp;
      experienceData['waterMilestoneExp'] = (experienceData['waterMilestoneExp'] as int? ?? 0) + waterMilestoneExp;
      experienceData['lastWaterMilestone'] = DateTime.now().toIso8601String();
      
      await saveLocalExperienceData(experienceData);
      await prefs.setString(_lastWaterExpAwardDateKey, today);
      
      debugPrint('🎉 Water milestone reached! Awarded $waterMilestoneExp XP for drinking 9 glasses. Total XP: $newExp');
    } catch (e) {
      debugPrint('Error awarding water milestone experience: $e');
    }
  }

  /// Decrement water glass count (with minimum of 0)
  Future<int> decrementWaterGlassCount() async {
    try {
      final currentCount = await getWaterGlassCount();
      final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();
      await saveWaterGlassCount(newCount);
      debugPrint('Water glass count decremented to: $newCount');
      return newCount;
    } catch (e) {
      debugPrint('Error decrementing water glass count: $e');
      return await getWaterGlassCount();
    }
  }

  // Step Data Convenience Methods

  /// Get today's step count
  Future<int> getTodaysStepCount() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final stepData = await getLocalStepData();
      
      final todaysData = stepData.where((data) => 
          data.date.toIso8601String().split('T')[0] == today).firstOrNull;
      
      return todaysData?.steps ?? 0;
    } catch (e) {
      debugPrint('Error getting today\'s step count: $e');
      return 0;
    }
  }

  /// Update today's step count with persistence
  Future<void> updateTodaysStepCount(int steps, {int? goal}) async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      
      final stepData = await getLocalStepData();
      
      // Get existing goal or use default/provided goal
      int stepGoal = goal ?? 10000; // Default goal
      final existingTodayData = stepData.where((data) => 
          data.date.toIso8601String().split('T')[0] == todayStr).firstOrNull;
      if (existingTodayData != null && goal == null) {
        stepGoal = existingTodayData.goal; // Preserve existing goal if not specified
      }
      
      // Remove existing data for today
      stepData.removeWhere((data) => 
          data.date.toIso8601String().split('T')[0] == todayStr);
      
      // Add new data for today
      final newStepData = DailyStepData(
        date: today,
        steps: steps,
        goal: stepGoal,
        distanceMeters: (steps * 0.762), // Approximate distance in meters
        caloriesBurned: (steps * 0.04), // Approximate calories burned
      );
      
      stepData.add(newStepData);
      await saveLocalStepData(stepData);
      
      debugPrint('Today\'s step count updated to: $steps (goal: $stepGoal)');
    } catch (e) {
      debugPrint('Error updating today\'s step count: $e');
    }
  }

  /// Add steps to today's count (incremental)
  Future<int> addStepsToToday(int additionalSteps) async {
    try {
      final currentSteps = await getTodaysStepCount();
      final newSteps = currentSteps + additionalSteps;
      await updateTodaysStepCount(newSteps);
      debugPrint('Added $additionalSteps steps, total: $newSteps');
      return newSteps;
    } catch (e) {
      debugPrint('Error adding steps to today: $e');
      return await getTodaysStepCount();
    }
  }

  /// Get step data for the last N days
  Future<List<DailyStepData>> getRecentStepData(int days) async {
    try {
      final allStepData = await getLocalStepData();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      return allStepData.where((data) => 
          data.date.isAfter(cutoffDate) || 
          data.date.toIso8601String().split('T')[0] == DateTime.now().toIso8601String().split('T')[0]
      ).toList()..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error getting recent step data: $e');
      return [];
    }
  }

  /// Set today's step goal
  Future<void> setTodaysStepGoal(int goal) async {
    try {
      final currentSteps = await getTodaysStepCount();
      await updateTodaysStepCount(currentSteps, goal: goal);
      debugPrint('Today\'s step goal set to: $goal');
    } catch (e) {
      debugPrint('Error setting today\'s step goal: $e');
    }
  }

  /// Get today's step goal
  Future<int> getTodaysStepGoal() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final stepData = await getLocalStepData();
      
      final todaysData = stepData.where((data) => 
          data.date.toIso8601String().split('T')[0] == today).firstOrNull;
      
      return todaysData?.goal ?? 10000; // Default goal
    } catch (e) {
      debugPrint('Error getting today\'s step goal: $e');
      return 10000;
    }
  }

  // Water Milestone and Experience Methods

  /// Check if water milestone (9 glasses) has been reached today
  Future<bool> hasReachedWaterMilestoneToday() async {
    try {
      final waterCount = await getWaterGlassCount();
      return waterCount >= 9;
    } catch (e) {
      debugPrint('Error checking water milestone: $e');
      return false;
    }
  }

  /// Check if water milestone experience has been awarded today
  Future<bool> hasWaterMilestoneExpBeenAwarded() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final lastExpAwardDate = prefs.getString(_lastWaterExpAwardDateKey);
      return lastExpAwardDate == today;
    } catch (e) {
      debugPrint('Error checking water milestone exp award: $e');
      return false;
    }
  }

  /// Get water milestone status
  Future<Map<String, dynamic>> getWaterMilestoneStatus() async {
    try {
      final waterCount = await getWaterGlassCount();
      final milestoneReached = waterCount >= 9;
      final expAwarded = await hasWaterMilestoneExpBeenAwarded();
      
      return {
        'currentCount': waterCount,
        'milestoneTarget': 9,
        'milestoneReached': milestoneReached,
        'experienceAwarded': expAwarded,
        'remainingForMilestone': milestoneReached ? 0 : (9 - waterCount),
        'experiencePoints': 50, // XP awarded for milestone
      };
    } catch (e) {
      debugPrint('Error getting water milestone status: $e');
      return {
        'currentCount': 0,
        'milestoneTarget': 9,
        'milestoneReached': false,
        'experienceAwarded': false,
        'remainingForMilestone': 9,
        'experiencePoints': 50,
      };
    }
  }

  // Firebase Sync Methods

  // Immediate Firebase Sync Methods (for real-time data safety)

  /// Check connectivity before immediate sync
  Future<bool> _canSyncToFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking sync capability: $e');
      return false;
    }
  }

  /// Immediate sync user data to Firebase
  Future<void> _syncUserDataToFirebaseImmediate(UserData userData) async {
    if (!await _canSyncToFirebase()) return;
    
    try {
      final user = _auth.currentUser!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData.toJson(), SetOptions(merge: true));
      debugPrint('User data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate user data sync: $e');
    }
  }

  /// Immediate sync checkin data to Firebase
  Future<void> _syncCheckinDataToFirebaseImmediate(DailyCheckinData checkinData) async {
    if (!await _canSyncToFirebase()) return;
    
    try {
      final user = _auth.currentUser!;
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('checkins')
          .doc(today)
          .set(checkinData.toJson(), SetOptions(merge: true));
      debugPrint('Checkin data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate checkin data sync: $e');
    }
  }

  /// Immediate sync step data to Firebase
  Future<void> _syncStepDataToFirebaseImmediate(List<DailyStepData> stepData) async {
    if (!await _canSyncToFirebase()) return;
    
    try {
      final user = _auth.currentUser!;
      final batch = _firestore.batch();
      for (final data in stepData) {
        final dateStr = data.date.toIso8601String().split('T')[0];
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('steps')
            .doc(dateStr);
        batch.set(docRef, data.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Step data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate step data sync: $e');
    }
  }

  /// Immediate sync achievements to Firebase
  Future<void> _syncAchievementsToFirebaseImmediate(List<Achievement> achievements) async {
    if (!await _canSyncToFirebase()) return;
    
    try {
      final user = _auth.currentUser!;
      final batch = _firestore.batch();
      for (final achievement in achievements) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('achievements')
            .doc(achievement.id);
        batch.set(docRef, achievement.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Achievements synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate achievements sync: $e');
    }
  }

  /// Immediate sync activities to Firebase
  Future<void> _syncActivitiesToFirebaseImmediate(List<Activity> activities) async {
    if (!await _canSyncToFirebase()) return;
    
    try {
      final user = _auth.currentUser!;
      final batch = _firestore.batch();
      for (final activity in activities) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .doc(activity.id);
        batch.set(docRef, activity.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Activities synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate activities sync: $e');
    }
  }

  /// Immediate sync experience data to Firebase
  Future<void> _syncExperienceDataToFirebaseImmediate(Map<String, dynamic> experienceData) async {
    if (!await _canSyncToFirebase()) return;
    
    try {
      final user = _auth.currentUser!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('experience')
          .doc('data')
          .set(experienceData, SetOptions(merge: true));
      debugPrint('Experience data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate experience data sync: $e');
    }
  }

  /// Immediate sync water glass count to Firebase
  Future<void> _syncWaterGlassCountToFirebaseImmediate(int count) async {
    if (!await _canSyncToFirebase()) return;
    
    try {
      final user = _auth.currentUser!;
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_progress')
          .doc(today)
          .set({
            'waterGlassCount': count,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      debugPrint('Water glass count synced to Firebase immediately: $count');
    } catch (e) {
      debugPrint('Error in immediate water glass count sync: $e');
    }
  }

  // Scheduled Firebase Sync Methods (for sleep/wake sync)

  /// Sync user data to Firebase
  Future<void> _syncUserDataToFirebase() async {
    try {
      final userData = await getLocalUserData();
      if (userData != null) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userData.toJson(), SetOptions(merge: true));
          debugPrint('User data synced to Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing user data to Firebase: $e');
    }
  }

  /// Sync user data from Firebase
  Future<void> _syncUserDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userData = UserData.fromJson(doc.data()!);
          await saveLocalUserData(userData);
          debugPrint('User data synced from Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing user data from Firebase: $e');
    }
  }

  /// Sync checkin data to Firebase
  Future<void> _syncCheckinDataToFirebase() async {
    try {
      final checkinData = await getLocalCheckinData();
      if (checkinData != null) {
        final user = _auth.currentUser;
        if (user != null) {
          final today = DateTime.now().toIso8601String().split('T')[0];
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('checkins')
              .doc(today)
              .set(checkinData.toJson(), SetOptions(merge: true));
          debugPrint('Checkin data synced to Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing checkin data to Firebase: $e');
    }
  }

  /// Sync checkin data from Firebase
  Future<void> _syncCheckinDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('checkins')
            .doc(today)
            .get();
        if (doc.exists) {
          final checkinData = DailyCheckinData.fromJson(doc.data()!);
          await saveLocalCheckinData(checkinData);
          debugPrint('Checkin data synced from Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing checkin data from Firebase: $e');
    }
  }

  /// Sync step data to Firebase
  Future<void> _syncStepDataToFirebase() async {
    try {
      final stepData = await getLocalStepData();
      if (stepData.isNotEmpty) {
        final user = _auth.currentUser;
        if (user != null) {
          final batch = _firestore.batch();
          for (final data in stepData) {
            final dateStr = data.date.toIso8601String().split('T')[0];
            final docRef = _firestore
                .collection('users')
                .doc(user.uid)
                .collection('steps')
                .doc(dateStr);
            batch.set(docRef, data.toJson(), SetOptions(merge: true));
          }
          await batch.commit();
          debugPrint('Step data synced to Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing step data to Firebase: $e');
    }
  }

  /// Sync step data from Firebase
  Future<void> _syncStepDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));
        
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('steps')
            .where('date', isGreaterThanOrEqualTo: startDate)
            .get();

        final stepData = query.docs
            .map((doc) => DailyStepData.fromJson(doc.data()))
            .toList();
            
        await saveLocalStepData(stepData);
        debugPrint('Step data synced from Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing step data from Firebase: $e');
    }
  }

  /// Sync achievements to Firebase
  Future<void> _syncAchievementsToFirebase() async {
    try {
      final achievements = await getLocalAchievements();
      if (achievements.isNotEmpty) {
        final user = _auth.currentUser;
        if (user != null) {
          final batch = _firestore.batch();
          for (final achievement in achievements) {
            final docRef = _firestore
                .collection('users')
                .doc(user.uid)
                .collection('achievements')
                .doc(achievement.id);
            batch.set(docRef, achievement.toJson(), SetOptions(merge: true));
          }
          await batch.commit();
          debugPrint('Achievements synced to Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing achievements to Firebase: $e');
    }
  }

  /// Sync achievements from Firebase
  Future<void> _syncAchievementsFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('achievements')
            .get();

        final achievements = query.docs
            .map((doc) => Achievement.fromJson(doc.data()))
            .toList();
            
        await saveLocalAchievements(achievements);
        debugPrint('Achievements synced from Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing achievements from Firebase: $e');
    }
  }

  /// Sync activities to Firebase
  Future<void> _syncActivitiesToFirebase() async {
    try {
      final activities = await getLocalActivities();
      if (activities.isNotEmpty) {
        final user = _auth.currentUser;
        if (user != null) {
          final batch = _firestore.batch();
          for (final activity in activities) {
            final docRef = _firestore
                .collection('users')
                .doc(user.uid)
                .collection('activities')
                .doc(activity.id);
            batch.set(docRef, activity.toJson(), SetOptions(merge: true));
          }
          await batch.commit();
          debugPrint('Activities synced to Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing activities to Firebase: $e');
    }
  }

  /// Sync activities from Firebase
  Future<void> _syncActivitiesFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));
        
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .get();

        final activities = query.docs
            .map((doc) => Activity.fromJson(doc.data()))
            .toList();
            
        await saveLocalActivities(activities);
        debugPrint('Activities synced from Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing activities from Firebase: $e');
    }
  }

  /// Sync experience data to Firebase
  Future<void> _syncExperienceDataToFirebase() async {
    try {
      final experienceData = await getLocalExperienceData();
      if (experienceData.isNotEmpty) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('experience')
              .doc('data')
              .set(experienceData, SetOptions(merge: true));
          debugPrint('Experience data synced to Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing experience data to Firebase: $e');
    }
  }

  /// Sync experience data from Firebase
  Future<void> _syncExperienceDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('experience')
            .doc('data')
            .get();
        if (doc.exists) {
          final experienceData = Map<String, dynamic>.from(doc.data()!);
          await saveLocalExperienceData(experienceData);
          debugPrint('Experience data synced from Firebase');
        }
      }
    } catch (e) {
      debugPrint('Error syncing experience data from Firebase: $e');
    }
  }

  /// Sync water glass count to Firebase
  Future<void> _syncWaterGlassCountToFirebase() async {
    try {
      final waterCount = await getWaterGlassCount();
      final user = _auth.currentUser;
      if (user != null && waterCount > 0) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_progress')
            .doc(today)
            .set({
              'waterGlassCount': waterCount,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        debugPrint('Water glass count synced to Firebase: $waterCount');
      }
    } catch (e) {
      debugPrint('Error syncing water glass count to Firebase: $e');
    }
  }

  /// Sync water glass count from Firebase
  Future<void> _syncWaterGlassCountFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_progress')
            .doc(today)
            .get();
        if (doc.exists && doc.data()!.containsKey('waterGlassCount')) {
          final waterCount = doc.data()!['waterGlassCount'] as int? ?? 0;
          await saveWaterGlassCount(waterCount);
          debugPrint('Water glass count synced from Firebase: $waterCount');
        }
      }
    } catch (e) {
      debugPrint('Error syncing water glass count from Firebase: $e');
    }
  }

  /// Force sync all data to Firebase (emergency use)
  Future<void> forceSyncToFirebase() async {
    debugPrint('Performing force sync to Firebase');
    await _syncUserDataToFirebase();
    await _syncCheckinDataToFirebase();
    await _syncStepDataToFirebase();
    await _syncAchievementsToFirebase();
    await _syncActivitiesToFirebase();
    await _syncExperienceDataToFirebase();
    await _syncWaterGlassCountToFirebase();
    debugPrint('Force sync to Firebase completed');
  }

  /// Force sync all data from Firebase (emergency use)
  Future<void> forceSyncFromFirebase() async {
    debugPrint('Performing force sync from Firebase');
    await _syncUserDataFromFirebase();
    await _syncCheckinDataFromFirebase();
    await _syncStepDataFromFirebase();
    await _syncAchievementsFromFirebase();
    await _syncActivitiesFromFirebase();
    await _syncExperienceDataFromFirebase();
    await _syncWaterGlassCountFromFirebase();
    debugPrint('Force sync from Firebase completed');
  }

  /// Check if local data is available
  Future<bool> hasLocalData() async {
    final userData = await getLocalUserData();
    return userData != null;
  }

  /// Get data version for cache invalidation
  Future<int> getDataVersion() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_dailyDataVersionKey) ?? 0;
  }

  /// Add single activity and sync immediately (convenience method)
  Future<void> addActivityWithSync(Activity activity) async {
    try {
      final activities = await getLocalActivities();
      activities.add(activity);
      await saveLocalActivities(activities);
      debugPrint('Activity added and synced: ${activity.id}');
    } catch (e) {
      debugPrint('Error adding activity with sync: $e');
    }
  }

  /// Add single achievement and sync immediately (convenience method)
  Future<void> addAchievementWithSync(Achievement achievement) async {
    try {
      final achievements = await getLocalAchievements();
      achievements.add(achievement);
      await saveLocalAchievements(achievements);
      debugPrint('Achievement added and synced: ${achievement.id}');
    } catch (e) {
      debugPrint('Error adding achievement with sync: $e');
    }
  }

  /// Update step data for specific date and sync immediately (convenience method)
  Future<void> updateStepDataWithSync(DailyStepData stepData) async {
    try {
      final allStepData = await getLocalStepData();
      final dateStr = stepData.date.toIso8601String().split('T')[0];
      
      // Remove existing data for the same date and add updated data
      allStepData.removeWhere((data) => 
          data.date.toIso8601String().split('T')[0] == dateStr);
      allStepData.add(stepData);
      
      await saveLocalStepData(allStepData);
      debugPrint('Step data updated and synced for date: $dateStr');
    } catch (e) {
      debugPrint('Error updating step data with sync: $e');
    }
  }

  /// Get sync status information
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final lastSyncDate = prefs.getString(_lastSyncDateKey);
      final sleepSyncComplete = prefs.getString(_sleepSyncCompleteKey) == 'true';
      final wakeupSyncComplete = prefs.getString(_wakeupSyncCompleteKey) == 'true';
      final dataVersion = prefs.getInt(_dailyDataVersionKey) ?? 0;
      final waterGlassCount = await getWaterGlassCount();
      final canSync = await _canSyncToFirebase();
      
      return {
        'lastSyncDate': lastSyncDate,
        'sleepSyncComplete': sleepSyncComplete,
        'wakeupSyncComplete': wakeupSyncComplete,
        'dataVersion': dataVersion,
        'waterGlassCount': waterGlassCount,
        'realTimeSyncEnabled': _realTimeSyncEnabled,
        'canSyncToFirebase': canSync,
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      debugPrint('Error getting sync status: $e');
      return {
        'error': e.toString(),
        'realTimeSyncEnabled': _realTimeSyncEnabled,
        'isInitialized': _isInitialized,
      };
    }
  }

  /// Force immediate backup of all local data to Firebase
  Future<bool> performEmergencyBackup() async {
    try {
      debugPrint('Performing emergency backup to Firebase');
      
      if (!await _canSyncToFirebase()) {
        debugPrint('Cannot perform emergency backup - no connection or auth');
        return false;
      }

      // Backup all data types
      final userData = await getLocalUserData();
      if (userData != null) {
        await _syncUserDataToFirebaseImmediate(userData);
      }

      final checkinData = await getLocalCheckinData();
      if (checkinData != null) {
        await _syncCheckinDataToFirebaseImmediate(checkinData);
      }

      final stepData = await getLocalStepData();
      if (stepData.isNotEmpty) {
        await _syncStepDataToFirebaseImmediate(stepData);
      }

      final achievements = await getLocalAchievements();
      if (achievements.isNotEmpty) {
        await _syncAchievementsToFirebaseImmediate(achievements);
      }

      final activities = await getLocalActivities();
      if (activities.isNotEmpty) {
        await _syncActivitiesToFirebaseImmediate(activities);
      }

      final experienceData = await getLocalExperienceData();
      if (experienceData.isNotEmpty) {
        await _syncExperienceDataToFirebaseImmediate(experienceData);
      }

      final waterCount = await getWaterGlassCount();
      if (waterCount > 0) {
        await _syncWaterGlassCountToFirebaseImmediate(waterCount);
      }

      debugPrint('Emergency backup completed successfully');
      return true;
    } catch (e) {
      debugPrint('Emergency backup failed: $e');
      return false;
    }
  }

  // Daily Checkin Completion Tracking
  static const String _dailyCheckinCompleteKey = 'daily_checkin_complete';

  /// Check if user has completed daily checkin today
  Future<bool> hasCompletedDailyCheckinToday() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastCheckinDate = prefs.getString(_dailyCheckinCompleteKey);
      
      return lastCheckinDate == today;
    } catch (e) {
      debugPrint('Error checking daily checkin completion: $e');
      return false;
    }
  }

  /// Mark daily checkin as completed for today
  Future<void> markDailyCheckinComplete() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString(_dailyCheckinCompleteKey, today);
      debugPrint('Daily checkin marked as complete for $today');
    } catch (e) {
      debugPrint('Error marking daily checkin complete: $e');
    }
  }
}
