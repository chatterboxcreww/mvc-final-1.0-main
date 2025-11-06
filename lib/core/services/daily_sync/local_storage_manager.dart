// lib/core/services/daily_sync/local_storage_manager.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_data.dart';
import '../../models/daily_checkin_data.dart';
import '../../models/daily_step_data.dart';
import '../../models/achievement.dart';
import '../../models/activity.dart';
import 'sync_constants.dart';

/// Manages local storage operations for daily sync service
class LocalStorageManager {
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs => _prefs!;

  // User Data
  Future<void> saveUserData(UserData userData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final userDataJson = jsonEncode(userData.toJson());
      final success = await prefs.setString(SyncConstants.userDataKey, userDataJson);
      
      if (!success) {
        throw Exception('Failed to write user data to SharedPreferences');
      }
      
      debugPrint('User data saved to local storage successfully');
    } catch (e) {
      debugPrint('Error saving user data to local storage: $e');
      rethrow;
    }
  }

  Future<UserData?> getUserData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(SyncConstants.userDataKey);
      if (userDataJson != null) {
        return UserData.fromJson(jsonDecode(userDataJson));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data from local storage: $e');
      return null;
    }
  }

  // Checkin Data
  Future<void> saveCheckinData(DailyCheckinData checkinData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final checkinDataJson = jsonEncode(checkinData.toJson());
      await prefs.setString(SyncConstants.checkinDataKey, checkinDataJson);
      debugPrint('Checkin data saved to local storage');
    } catch (e) {
      debugPrint('Error saving checkin data to local storage: $e');
    }
  }

  Future<DailyCheckinData?> getCheckinData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final checkinDataJson = prefs.getString(SyncConstants.checkinDataKey);
      if (checkinDataJson != null) {
        return DailyCheckinData.fromJson(jsonDecode(checkinDataJson));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting checkin data from local storage: $e');
      return null;
    }
  }

  // Step Data
  Future<void> saveStepData(List<DailyStepData> stepData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final stepDataJson = jsonEncode(stepData.map((data) => data.toJson()).toList());
      await prefs.setString(SyncConstants.stepDataKey, stepDataJson);
      debugPrint('Step data saved to local storage');
    } catch (e) {
      debugPrint('Error saving step data to local storage: $e');
    }
  }

  Future<List<DailyStepData>> getStepData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final stepDataJson = prefs.getString(SyncConstants.stepDataKey);
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

  // Achievements
  Future<void> saveAchievements(List<Achievement> achievements) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final achievementsJson = jsonEncode(achievements.map((achievement) => achievement.toJson()).toList());
      await prefs.setString(SyncConstants.achievementsKey, achievementsJson);
      debugPrint('Achievements saved to local storage');
    } catch (e) {
      debugPrint('Error saving achievements to local storage: $e');
    }
  }

  Future<List<Achievement>> getAchievements() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(SyncConstants.achievementsKey);
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

  // Activities
  Future<void> saveActivities(List<Activity> activities) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(activities.map((activity) => activity.toJson()).toList());
      await prefs.setString(SyncConstants.activitiesKey, activitiesJson);
      debugPrint('Activities saved to local storage');
    } catch (e) {
      debugPrint('Error saving activities to local storage: $e');
    }
  }

  Future<List<Activity>> getActivities() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString(SyncConstants.activitiesKey);
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

  // Experience Data
  Future<void> saveExperienceData(Map<String, dynamic> experienceData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final experienceDataJson = jsonEncode(experienceData);
      await prefs.setString(SyncConstants.experienceDataKey, experienceDataJson);
      debugPrint('Experience data saved to local storage');
    } catch (e) {
      debugPrint('Error saving experience data to local storage: $e');
    }
  }

  Future<Map<String, dynamic>> getExperienceData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final experienceDataJson = prefs.getString(SyncConstants.experienceDataKey);
      if (experienceDataJson != null) {
        return Map<String, dynamic>.from(jsonDecode(experienceDataJson));
      }
      return {};
    } catch (e) {
      debugPrint('Error getting experience data from local storage: $e');
      return {};
    }
  }

  // Water Glass Count
  Future<void> saveWaterGlassCount(int count) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setInt(SyncConstants.waterGlassCountKey, count);
      debugPrint('Water glass count saved: $count');
    } catch (e) {
      debugPrint('Error saving water glass count: $e');
    }
  }

  Future<int> getWaterGlassCount() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      return prefs.getInt(SyncConstants.waterGlassCountKey) ?? 0;
    } catch (e) {
      debugPrint('Error getting water glass count: $e');
      return 0;
    }
  }

  // Utility Methods
  Future<int> getDataVersion() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(SyncConstants.dailyDataVersionKey) ?? 0;
  }

  Future<void> incrementDataVersion() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt(SyncConstants.dailyDataVersionKey) ?? 0;
    await prefs.setInt(SyncConstants.dailyDataVersionKey, currentVersion + 1);
  }

  Future<String?> getLastSyncDate() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(SyncConstants.lastSyncDateKey);
  }

  Future<void> setLastSyncDate(String date) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(SyncConstants.lastSyncDateKey, date);
  }

  Future<bool> isSleepSyncComplete() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(SyncConstants.sleepSyncCompleteKey) == 'true';
  }

  Future<void> setSleepSyncComplete(bool complete) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(SyncConstants.sleepSyncCompleteKey, complete.toString());
  }

  Future<bool> isWakeupSyncComplete() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(SyncConstants.wakeupSyncCompleteKey) == 'true';
  }

  Future<void> setWakeupSyncComplete(bool complete) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(SyncConstants.wakeupSyncCompleteKey, complete.toString());
  }

  Future<void> clearDailyData() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(SyncConstants.checkinDataKey);
    await prefs.remove(SyncConstants.activitiesKey);
    await prefs.remove(SyncConstants.experienceDataKey);
  }
}
