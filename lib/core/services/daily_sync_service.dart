// lib/core/services/daily_sync_service.dart

import 'package:flutter/foundation.dart';

import '../models/user_data.dart';
import '../models/daily_checkin_data.dart';
import '../models/daily_step_data.dart';
import '../models/achievement.dart';
import '../models/activity.dart';
import 'daily_sync/sync_constants.dart';
import 'daily_sync/local_storage_manager.dart';
import 'daily_sync/firebase_sync_manager.dart';
import 'daily_sync/step_tracking_manager.dart';
import 'daily_sync/water_tracking_manager.dart';
import 'daily_sync/scheduled_sync_manager.dart';
import 'daily_sync/daily_reset_manager.dart';

/// Service responsible for managing daily sync operations between local storage and Firebase
/// Data is stored locally throughout the day and synced to Firebase at sleep time
/// Data is read from Firebase at wake up time and stored locally
class DailySyncService {
  static final DailySyncService _instance = DailySyncService._internal();
  factory DailySyncService() => _instance;
  DailySyncService._internal();

  // Background task names (exposed for external use)
  static const String sleepSyncTaskName = SyncConstants.sleepSyncTaskName;
  static const String wakeupSyncTaskName = SyncConstants.wakeupSyncTaskName;

  // Managers
  late final LocalStorageManager _localStorage;
  late final FirebaseSyncManager _firebaseSync;
  late final StepTrackingManager _stepTracking;
  late final WaterTrackingManager _waterTracking;
  late final ScheduledSyncManager _scheduledSync;
  late final DailyResetManager _dailyReset;
  
  bool _isInitialized = false;
  bool _realTimeSyncEnabled = true; // Enable real-time sync for data safety

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize managers
    _localStorage = LocalStorageManager();
    await _localStorage.initialize();
    
    _firebaseSync = FirebaseSyncManager();
    _stepTracking = StepTrackingManager(_localStorage);
    _waterTracking = WaterTrackingManager(_localStorage);
    _scheduledSync = ScheduledSyncManager(_localStorage, _firebaseSync);
    _dailyReset = DailyResetManager(_localStorage);
    
    _isInitialized = true;
    
    // Check if it's a new day and perform initial sync if needed
    await _dailyReset.checkAndPerformDailyReset();
    
    // Ensure step data persistence on app startup
    await _dailyReset.ensureStepDataPersistence(() => _firebaseSync.syncTodaysStepDataFromFirebase());
    
    // Schedule daily sync tasks
    await _scheduledSync.scheduleDailySyncTasks();
    
    debugPrint('DailySyncService initialized with real-time sync: $_realTimeSyncEnabled');
  }

  /// Enable or disable real-time sync
  void setRealTimeSyncEnabled(bool enabled) {
    _realTimeSyncEnabled = enabled;
    debugPrint('Real-time sync ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if real-time sync is enabled
  bool get isRealTimeSyncEnabled => _realTimeSyncEnabled;

  // ========== Sleep/Wakeup Sync Methods ==========

  /// Check if it's sleep time and perform sync to Firebase
  Future<bool> performSleepTimeSync() => _scheduledSync.performSleepTimeSync();

  /// Check if it's wakeup time and sync from Firebase to local storage
  Future<bool> performWakeupTimeSync() => _scheduledSync.performWakeupTimeSync();

  // ========== Local Storage Methods ==========

  /// Save user data to local storage
  Future<void> saveLocalUserData(UserData userData) async {
    await _localStorage.saveUserData(userData);
    
    // Immediate sync to Firebase if real-time sync is enabled
    if (_realTimeSyncEnabled) {
      try {
        await _firebaseSync.syncUserDataImmediate(userData);
      } catch (e) {
        debugPrint('Warning: Firebase sync failed but local save succeeded: $e');
      }
    }
  }

  /// Get user data from local storage
  Future<UserData?> getLocalUserData() => _localStorage.getUserData();

  /// Save checkin data to local storage
  Future<void> saveLocalCheckinData(DailyCheckinData checkinData) async {
    await _localStorage.saveCheckinData(checkinData);
    
    // Immediate sync to Firebase if real-time sync is enabled
    if (_realTimeSyncEnabled) {
      await _firebaseSync.syncCheckinDataImmediate(checkinData);
    }
  }

  /// Get checkin data from local storage
  Future<DailyCheckinData?> getLocalCheckinData() => _localStorage.getCheckinData();

  /// Save step data to local storage
  Future<void> saveLocalStepData(List<DailyStepData> stepData) async {
    await _localStorage.saveStepData(stepData);
    
    // Immediate sync to Firebase if real-time sync is enabled
    if (_realTimeSyncEnabled) {
      await _firebaseSync.syncStepDataImmediate(stepData);
    }
  }

  /// Get step data from local storage
  Future<List<DailyStepData>> getLocalStepData() => _localStorage.getStepData();

  /// Save achievements to local storage
  Future<void> saveLocalAchievements(List<Achievement> achievements) async {
    await _localStorage.saveAchievements(achievements);
    
    // Immediate sync to Firebase if real-time sync is enabled
    if (_realTimeSyncEnabled) {
      await _firebaseSync.syncAchievementsImmediate(achievements);
    }
  }

  /// Get achievements from local storage
  Future<List<Achievement>> getLocalAchievements() => _localStorage.getAchievements();

  /// Save activities to local storage
  Future<void> saveLocalActivities(List<Activity> activities) async {
    await _localStorage.saveActivities(activities);
    
    // Immediate sync to Firebase if real-time sync is enabled
    if (_realTimeSyncEnabled) {
      await _firebaseSync.syncActivitiesImmediate(activities);
    }
  }

  /// Get activities from local storage
  Future<List<Activity>> getLocalActivities() => _localStorage.getActivities();

  /// Save experience data to local storage
  Future<void> saveLocalExperienceData(Map<String, dynamic> experienceData) async {
    await _localStorage.saveExperienceData(experienceData);
    
    // Immediate sync to Firebase if real-time sync is enabled
    if (_realTimeSyncEnabled) {
      await _firebaseSync.syncExperienceDataImmediate(experienceData);
    }
  }

  /// Get experience data from local storage
  Future<Map<String, dynamic>> getLocalExperienceData() => _localStorage.getExperienceData();

  // ========== Water Glass Count Methods ==========

  /// Save water glass count to local storage
  Future<void> saveWaterGlassCount(int count) async {
    await _localStorage.saveWaterGlassCount(count);
    
    // Immediate sync to Firebase if real-time sync is enabled
    if (_realTimeSyncEnabled) {
      await _firebaseSync.syncWaterGlassCountImmediate(count);
    }
  }

  /// Get water glass count from local storage
  Future<int> getWaterGlassCount() => _localStorage.getWaterGlassCount();

  /// Increment water glass count
  Future<int> incrementWaterGlassCount() => _waterTracking.incrementWaterGlassCount();

  /// Decrement water glass count (with minimum of 0)
  Future<int> decrementWaterGlassCount() => _waterTracking.decrementWaterGlassCount();

  /// Check if water milestone (9 glasses) has been reached today
  Future<bool> hasReachedWaterMilestoneToday() => _waterTracking.hasReachedWaterMilestoneToday();

  /// Check if water milestone experience has been awarded today
  Future<bool> hasWaterMilestoneExpBeenAwarded() => _waterTracking.hasWaterMilestoneExpBeenAwarded();

  /// Get water milestone status
  Future<Map<String, dynamic>> getWaterMilestoneStatus() => _waterTracking.getWaterMilestoneStatus();

  // ========== Step Data Convenience Methods ==========

  /// Get today's step count
  Future<int> getTodaysStepCount() => _stepTracking.getTodaysStepCount();

  /// Update today's step count with persistence
  Future<void> updateTodaysStepCount(int steps, {int? goal}) => 
      _stepTracking.updateTodaysStepCount(steps, goal: goal);

  /// Add steps to today's count (incremental)
  Future<int> addStepsToToday(int additionalSteps) => _stepTracking.addStepsToToday(additionalSteps);

  /// Get step data for the last N days
  Future<List<DailyStepData>> getRecentStepData(int days) => _stepTracking.getRecentStepData(days);

  /// Set today's step goal
  Future<void> setTodaysStepGoal(int goal) => _stepTracking.setTodaysStepGoal(goal);

  /// Get today's step goal
  Future<int> getTodaysStepGoal() => _stepTracking.getTodaysStepGoal();

  // ========== Firebase Sync Methods ==========

  /// Force sync all data to Firebase (emergency use)
  Future<void> forceSyncToFirebase() async {
    debugPrint('Performing force sync to Firebase');
    final userData = await _localStorage.getUserData();
    final checkinData = await _localStorage.getCheckinData();
    final stepData = await _localStorage.getStepData();
    final achievements = await _localStorage.getAchievements();
    final activities = await _localStorage.getActivities();
    final experienceData = await _localStorage.getExperienceData();
    final waterCount = await _localStorage.getWaterGlassCount();

    await _firebaseSync.syncUserDataToFirebase(userData);
    await _firebaseSync.syncCheckinDataToFirebase(checkinData);
    await _firebaseSync.syncStepDataToFirebase(stepData);
    await _firebaseSync.syncAchievementsToFirebase(achievements);
    await _firebaseSync.syncActivitiesToFirebase(activities);
    await _firebaseSync.syncExperienceDataToFirebase(experienceData);
    await _firebaseSync.syncWaterGlassCountToFirebase(waterCount);
    debugPrint('Force sync to Firebase completed');
  }

  /// Force sync all data from Firebase (emergency use)
  Future<void> forceSyncFromFirebase() async {
    debugPrint('Performing force sync from Firebase');
    final userData = await _firebaseSync.syncUserDataFromFirebase();
    final checkinData = await _firebaseSync.syncCheckinDataFromFirebase();
    final stepData = await _firebaseSync.syncStepDataFromFirebase();
    final achievements = await _firebaseSync.syncAchievementsFromFirebase();
    final activities = await _firebaseSync.syncActivitiesFromFirebase();
    final experienceData = await _firebaseSync.syncExperienceDataFromFirebase();
    final waterCount = await _firebaseSync.syncWaterGlassCountFromFirebase();

    if (userData != null) await _localStorage.saveUserData(userData);
    if (checkinData != null) await _localStorage.saveCheckinData(checkinData);
    if (stepData.isNotEmpty) await _localStorage.saveStepData(stepData);
    if (achievements.isNotEmpty) await _localStorage.saveAchievements(achievements);
    if (activities.isNotEmpty) await _localStorage.saveActivities(activities);
    if (experienceData.isNotEmpty) await _localStorage.saveExperienceData(experienceData);
    if (waterCount > 0) await _localStorage.saveWaterGlassCount(waterCount);
    debugPrint('Force sync from Firebase completed');
  }

  /// Check if local data is available
  Future<bool> hasLocalData() async {
    final userData = await getLocalUserData();
    return userData != null;
  }

  /// Get data version for cache invalidation
  Future<int> getDataVersion() => _localStorage.getDataVersion();

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
      await _stepTracking.updateStepDataForDate(stepData);
      
      // Immediate sync if enabled
      if (_realTimeSyncEnabled) {
        final allStepData = await getLocalStepData();
        await _firebaseSync.syncStepDataImmediate(allStepData);
      }
      
      final dateStr = stepData.date.toIso8601String().split('T')[0];
      debugPrint('Step data updated and synced for date: $dateStr');
    } catch (e) {
      debugPrint('Error updating step data with sync: $e');
    }
  }

  /// Get sync status information
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final lastSyncDate = await _localStorage.getLastSyncDate();
      final sleepSyncComplete = await _localStorage.isSleepSyncComplete();
      final wakeupSyncComplete = await _localStorage.isWakeupSyncComplete();
      final dataVersion = await _localStorage.getDataVersion();
      final waterGlassCount = await getWaterGlassCount();
      final canSync = await _firebaseSync.canSync();
      
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
      
      if (!await _firebaseSync.canSync()) {
        debugPrint('Cannot perform emergency backup - no connection or auth');
        return false;
      }

      // Backup all data types
      final userData = await getLocalUserData();
      if (userData != null) {
        await _firebaseSync.syncUserDataImmediate(userData);
      }

      final checkinData = await getLocalCheckinData();
      if (checkinData != null) {
        await _firebaseSync.syncCheckinDataImmediate(checkinData);
      }

      final stepData = await getLocalStepData();
      if (stepData.isNotEmpty) {
        await _firebaseSync.syncStepDataImmediate(stepData);
      }

      final achievements = await getLocalAchievements();
      if (achievements.isNotEmpty) {
        await _firebaseSync.syncAchievementsImmediate(achievements);
      }

      final activities = await getLocalActivities();
      if (activities.isNotEmpty) {
        await _firebaseSync.syncActivitiesImmediate(activities);
      }

      final experienceData = await getLocalExperienceData();
      if (experienceData.isNotEmpty) {
        await _firebaseSync.syncExperienceDataImmediate(experienceData);
      }

      final waterCount = await getWaterGlassCount();
      if (waterCount > 0) {
        await _firebaseSync.syncWaterGlassCountImmediate(waterCount);
      }

      debugPrint('Emergency backup completed successfully');
      return true;
    } catch (e) {
      debugPrint('Emergency backup failed: $e');
      return false;
    }
  }

  // ========== Daily Checkin Completion Tracking ==========

  /// Check if user has completed daily checkin today
  Future<bool> hasCompletedDailyCheckinToday() async {
    try {
      final prefs = _localStorage.prefs;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastCheckinDate = prefs.getString(SyncConstants.dailyCheckinCompleteKey);
      
      return lastCheckinDate == today;
    } catch (e) {
      debugPrint('Error checking daily checkin completion: $e');
      return false;
    }
  }

  /// Mark daily checkin as completed for today
  Future<void> markDailyCheckinComplete() async {
    try {
      final prefs = _localStorage.prefs;
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString(SyncConstants.dailyCheckinCompleteKey, today);
      debugPrint('Daily checkin marked as complete for $today');
    } catch (e) {
      debugPrint('Error marking daily checkin complete: $e');
    }
  }
}
