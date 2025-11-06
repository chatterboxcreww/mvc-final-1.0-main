// lib/core/services/daily_sync/scheduled_sync_manager.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

import '../../models/user_data.dart';
import 'sync_constants.dart';
import 'local_storage_manager.dart';
import 'firebase_sync_manager.dart';

/// Manages scheduled sync operations (sleep/wakeup sync)
class ScheduledSyncManager {
  final LocalStorageManager _localStorage;
  final FirebaseSyncManager _firebaseSync;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();

  ScheduledSyncManager(this._localStorage, this._firebaseSync);

  /// Schedule background tasks for sleep and wakeup sync
  Future<void> scheduleDailySyncTasks() async {
    try {
      // Cancel existing tasks
      await Workmanager().cancelByUniqueName(SyncConstants.sleepSyncTaskName);
      await Workmanager().cancelByUniqueName(SyncConstants.wakeupSyncTaskName);
      
      // Schedule sleep sync task (runs periodically to check if it's sleep time)
      await Workmanager().registerPeriodicTask(
        SyncConstants.sleepSyncTaskName,
        SyncConstants.sleepSyncTaskName,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(minutes: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
      );
      
      // Schedule wakeup sync task (runs periodically to check if it's wakeup time)
      await Workmanager().registerPeriodicTask(
        SyncConstants.wakeupSyncTaskName,
        SyncConstants.wakeupSyncTaskName,
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

  /// Check if it's sleep time and perform sync to Firebase
  Future<bool> performSleepTimeSync() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if sleep sync already completed today
      final sleepSyncComplete = await _localStorage.isSleepSyncComplete();
      if (sleepSyncComplete) return true;

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection for sleep sync');
        return false;
      }

      // Check if it's sleep time
      if (!await _isSleepTime()) return false;

      debugPrint('Performing sleep time sync to Firebase');

      // Sync all local data to Firebase
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

      // Mark sleep sync as complete
      await _localStorage.setSleepSyncComplete(true);
      
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

      // Check if wakeup sync already completed today
      final wakeupSyncComplete = await _localStorage.isWakeupSyncComplete();
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

      // Mark wakeup sync as complete
      await _localStorage.setWakeupSyncComplete(true);
      
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
      final userData = await _localStorage.getUserData();
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
      final userData = await _localStorage.getUserData();
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
}
