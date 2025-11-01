// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\services\storage_service.dart

// lib/core/services/storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import '../models/daily_step_data.dart';
import '../models/daily_checkin_data.dart';

class StorageService {
  // Constants
  static const int _customReminderBaseId = 4000;
  static const int _maxStoredDays = 30;

  // Keys
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _themeModeKey = 'theme_mode';
  static const String _activitiesKey = 'activities';
  static const String _nextNotificationIdKey = 'next_custom_notification_id';
  static const String _weeklyStepDataKey = 'weekly_step_data';
  static const String _checkinHistoryKey = 'checkin_history';
  static const String _lastDataSyncKey = 'last_data_sync';

  // Singleton pattern for better performance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Cached SharedPreferences instance for performance optimization
  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await _prefs;
      final result = prefs.getBool(_onboardingCompleteKey) ?? false;
      debugPrint('StorageService: isOnboardingComplete check result = $result');
      return result;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  Future<void> setOnboardingComplete(bool complete) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(_onboardingCompleteKey, complete);
      debugPrint('StorageService: Onboarding status set to: $complete');
    } catch (e) {
      debugPrint('Error setting onboarding status: $e');
    }
  }

  Future<String?> getThemeMode() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_themeModeKey);
    } catch (e) {
      debugPrint('Error getting theme mode: $e');
      return null;
    }
  }

  Future<void> saveThemeMode(String themeMode) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_themeModeKey, themeMode);
      print('Theme mode saved: $themeMode');
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  Future<List<Activity>> getActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? activitiesJson = prefs.getStringList(_activitiesKey);

      if (activitiesJson != null) {
        return activitiesJson
            .map((jsonString) {
          try {
            return Activity.fromJson(jsonDecode(jsonString));
          } catch (e) {
            print('Error parsing activity JSON: $e');
            return null;
          }
        })
            .where((activity) => activity != null)
            .cast<Activity>()
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting activities: $e');
      return [];
    }
  }

  Future<void> saveActivities(List<Activity> activities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> activitiesJson = activities
          .map((activity) {
        try {
          return jsonEncode(activity.toJson());
        } catch (e) {
          print('Error encoding activity: $e');
          return null;
        }
      })
          .where((jsonString) => jsonString != null)
          .cast<String>()
          .toList();

      await prefs.setStringList(_activitiesKey, activitiesJson);
      print('Saved ${activities.length} activities');
    } catch (e) {
      print('Error saving activities: $e');
    }
  }

  Future<int> getNextCustomNotificationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int nextId = prefs.getInt(_nextNotificationIdKey) ?? _customReminderBaseId;

      if (nextId < _customReminderBaseId) {
        nextId = _customReminderBaseId;
      }

      await prefs.setInt(_nextNotificationIdKey, nextId + 1);
      return nextId;
    } catch (e) {
      print('Error getting next notification ID: $e');
      return _customReminderBaseId;
    }
  }

  Future<void> saveWeeklyStepData(List<DailyStepData> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sort and keep only recent data to prevent unlimited storage growth
      final sortedData = List<DailyStepData>.from(data);
      sortedData.sort((a, b) => b.date.compareTo(a.date));
      final recentData = sortedData.take(_maxStoredDays).toList();

      final List<String> jsonData = recentData
          .map((d) {
        try {
          return jsonEncode(d.toJson());
        } catch (e) {
          print('Error encoding step data: $e');
          return null;
        }
      })
          .where((jsonString) => jsonString != null)
          .cast<String>()
          .toList();

      await prefs.setStringList(_weeklyStepDataKey, jsonData);
      print('Saved ${recentData.length} days of step data');
    } catch (e) {
      print('Error saving weekly step data: $e');
    }
  }

  Future<List<DailyStepData>> getWeeklyStepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonData = prefs.getStringList(_weeklyStepDataKey);

      if (jsonData == null) {
        return [];
      }

      return jsonData
          .map((s) {
        try {
          return DailyStepData.fromJson(jsonDecode(s));
        } catch (e) {
          print('Error decoding step data: $e');
          return null;
        }
      })
          .where((stepData) => stepData != null)
          .cast<DailyStepData>()
          .toList();
    } catch (e) {
      print('Error getting weekly step data: $e');
      // Clear corrupted data and return empty list
      await _clearCorruptedData(_weeklyStepDataKey);
      return [];
    }
  }

  Future<List<DailyCheckinData>> getCheckinHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? historyJson = prefs.getStringList(_checkinHistoryKey);

      if (historyJson != null) {
        return historyJson
            .map((s) {
          try {
          return DailyCheckinData.fromJson(jsonDecode(s));
        } catch (e) {
          // print('Error decoding checkin data: $e');
            return null;
          }
        })
            .where((checkinData) => checkinData != null)
            .cast<DailyCheckinData>()
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting checkin history: $e');
      await _clearCorruptedData(_checkinHistoryKey);
      return [];
    }
  }

  Future<void> saveCheckinHistory(List<DailyCheckinData> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sort and limit history to prevent unlimited growth
      final sortedHistory = List<DailyCheckinData>.from(history);
      sortedHistory.sort((a, b) => b.date.compareTo(a.date));
      final recentHistory = sortedHistory.take(_maxStoredDays).toList();

      final List<String> historyJson = recentHistory
          .map((checkin) {
        try {
          return jsonEncode(checkin.toJson());
        } catch (e) {
          print('Error encoding checkin data: $e');
          return null;
        }
      })
          .where((jsonString) => jsonString != null)
          .cast<String>()
          .toList();

      await prefs.setStringList(_checkinHistoryKey, historyJson);
      print('Saved ${recentHistory.length} checkin records');
    } catch (e) {
      print('Error saving checkin history: $e');
    }
  }

  Future<DateTime?> getLastDataSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? syncTimeString = prefs.getString(_lastDataSyncKey);

      if (syncTimeString != null) {
        return DateTime.tryParse(syncTimeString);
      }
      return null;
    } catch (e) {
      print('Error getting last data sync: $e');
      return null;
    }
  }

  Future<void> setLastDataSync(DateTime syncTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDataSyncKey, syncTime.toIso8601String());
      print('Last data sync time updated: $syncTime');
    } catch (e) {
      print('Error setting last data sync: $e');
    }
  }

  Future<void> _clearCorruptedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      print('Cleared corrupted data for key: $key');
    } catch (e) {
      print('Error clearing corrupted data: $e');
    }
  }

  // Method to check data integrity
  Future<bool> verifyDataIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if critical data is accessible
      final keys = [_onboardingCompleteKey, _themeModeKey, _activitiesKey];

      for (final key in keys) {
        try {
          prefs.get(key);
        } catch (e) {
          print('Data integrity check failed for key: $key');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Data integrity verification failed: $e');
      return false;
    }
  }

  /// Comprehensive method to clear all local data
  Future<void> clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all app-specific keys while preserving system settings
      final keysToRemove = [
        _onboardingCompleteKey,
        _activitiesKey,
        _nextNotificationIdKey,
        _weeklyStepDataKey,
        _checkinHistoryKey,
        _lastDataSyncKey,
        // User data cache keys
        'user_data_cache',
        'last_user_data_sync',
        'user_name',
        'user_age',
        'user_height',
        'user_weight',
        'user_level',
        'daily_step_goal',
        'daily_water_goal',
        'profile_picture_path',
        // Auth state keys
        'is_authenticated',
        'cached_user_uid',
        'cached_user_email',
        'cached_user_display_name',
        'cached_user_photo_url',
        'auth_timestamp',
        // Critical data keys
        'critical_user_data',
        'critical_data_timestamp',
      ];
      
      for (String key in keysToRemove) {
        await prefs.remove(key);
      }
      
      print('StorageService: All local data cleared successfully');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  /// Save critical user data for offline access
  Future<void> saveCriticalUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save as JSON string
      await prefs.setString('critical_user_data', jsonEncode(userData));
      await prefs.setString('critical_data_timestamp', DateTime.now().toIso8601String());
      
      print('StorageService: Critical user data saved');
    } catch (e) {
      print('Error saving critical user data: $e');
    }
  }

  /// Load critical user data for offline access
  Future<Map<String, dynamic>?> loadCriticalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('critical_user_data');
      final timestamp = prefs.getString('critical_data_timestamp');
      
      if (dataString != null && timestamp != null) {
        // Check if data is not too old (30 days)
        final saveTime = DateTime.parse(timestamp);
        if (DateTime.now().difference(saveTime).inDays <= 30) {
          return jsonDecode(dataString);
        } else {
          // Data is too old, remove it
          await prefs.remove('critical_user_data');
          await prefs.remove('critical_data_timestamp');
        }
      }
    } catch (e) {
      print('Error loading critical user data: $e');
    }
    return null;
  }
}

