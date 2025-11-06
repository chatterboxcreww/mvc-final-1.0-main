// lib/core/providers/user_data/cache_manager.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_data.dart';

/// Manages caching operations for user data
class UserDataCacheManager {
  static const String _userDataCacheKey = 'user_data_cache_v2';
  static const String _lastSyncKey = 'last_user_data_sync_v2';
  static const String _dataHashKey = 'user_data_integrity_hash';
  static const String _lastUpdateKey = 'last_data_update_timestamp';
  static const String _criticalDataKey = 'critical_user_data_backup';

  final SharedPreferences _prefs;

  UserDataCacheManager(this._prefs);

  /// Save user data to local cache
  Future<void> saveToCache(UserData userData) async {
    try {
      final Map<String, dynamic> userDataJson = userData.toJson();
      await _prefs.setString(_userDataCacheKey, jsonEncode(userDataJson));
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      // Save critical fields individually
      await _prefs.setString('user_name', userData.name ?? '');
      await _prefs.setInt('user_age', userData.age ?? 0);
      await _prefs.setDouble('user_height', userData.height ?? 0.0);
      await _prefs.setDouble('user_weight', userData.weight ?? 0.0);
      await _prefs.setInt('user_level', userData.level);
      await _prefs.setInt('daily_step_goal', userData.dailyStepGoal ?? 10000);
      await _prefs.setInt('daily_water_goal', userData.dailyWaterGoal ?? 8);
      await _prefs.setString('profile_picture_path', userData.profilePicturePath ?? '');
      
      debugPrint('UserDataCacheManager: Saved complete data to local cache');
    } catch (e) {
      debugPrint('UserDataCacheManager: Error saving to cache: $e');
    }
  }

  /// Load user data from local cache
  Future<UserData?> loadFromCache() async {
    try {
      final cachedDataString = _prefs.getString(_userDataCacheKey);
      final lastSyncString = _prefs.getString(_lastSyncKey);

      if (cachedDataString != null) {
        // Check if cache is not too old (30 days max)
        if (lastSyncString != null) {
          final lastSync = DateTime.parse(lastSyncString);
          if (DateTime.now().difference(lastSync).inDays > 30) {
            debugPrint('UserDataCacheManager: Cache is too old, ignoring');
            return null;
          }
        }

        try {
          final Map<String, dynamic> userDataJson = jsonDecode(cachedDataString);
          final userData = UserData.fromJson(userDataJson);
          debugPrint('UserDataCacheManager: Successfully loaded data from cache');
          return userData;
        } catch (parseError) {
          debugPrint('UserDataCacheManager: Error parsing cached JSON: $parseError');
          return _loadFromIndividualFields();
        }
      }
    } catch (e) {
      debugPrint('UserDataCacheManager: Error loading from cache: $e');
    }
    return null;
  }

  /// Load from individual fields as fallback
  UserData? _loadFromIndividualFields() {
    try {
      final String name = _prefs.getString('user_name') ?? '';
      final int age = _prefs.getInt('user_age') ?? 0;
      final double height = _prefs.getDouble('user_height') ?? 0.0;
      final double weight = _prefs.getDouble('user_weight') ?? 0.0;
      final int level = _prefs.getInt('user_level') ?? 1;
      final int stepGoal = _prefs.getInt('daily_step_goal') ?? 10000;
      final int waterGoal = _prefs.getInt('daily_water_goal') ?? 8;
      final String profilePicture = _prefs.getString('profile_picture_path') ?? '';
      
      return UserData(
        userId: '',
        name: name.isNotEmpty ? name : null,
        age: age > 0 ? age : null,
        height: height > 0 ? height : null,
        weight: weight > 0 ? weight : null,
        level: level,
        dailyStepGoal: stepGoal,
        dailyWaterGoal: waterGoal,
        profilePicturePath: profilePicture.isNotEmpty ? profilePicture : null,
        memberSince: DateTime.now().subtract(const Duration(days: 30)),
      );
    } catch (e) {
      debugPrint('UserDataCacheManager: Error loading from individual fields: $e');
      return null;
    }
  }

  /// Save to all cache layers
  Future<void> saveToAllLayers(UserData userData) async {
    try {
      final dataToSave = {
        'userData': userData.toJson(),
        'lastDataUpdate': DateTime.now().toIso8601String(),
        'syncTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final dataJson = jsonEncode(dataToSave);
      final dataHash = dataJson.hashCode.toString();
      
      // Layer 1: Instant cache
      await _prefs.setString(_userDataCacheKey, dataJson);
      
      // Layer 2: Critical backup
      await _prefs.setString(_criticalDataKey, dataJson);
      
      // Layer 3: Data integrity hash
      await _prefs.setString(_dataHashKey, dataHash);
      
      // Update timestamps
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      await _prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      debugPrint('UserDataCacheManager: Saved to all cache layers');
    } catch (e) {
      debugPrint('UserDataCacheManager: Error saving to cache layers: $e');
    }
  }

  /// Load from instant cache
  UserData? loadFromInstantCache() {
    try {
      final cachedData = _prefs.getString(_userDataCacheKey);
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        if (data.containsKey('userData')) {
          return UserData.fromJson(data['userData']);
        } else {
          return UserData.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('UserDataCacheManager: Error loading instant cache: $e');
    }
    return null;
  }

  /// Load from critical backup
  UserData? loadFromCriticalBackup() {
    try {
      final backupData = _prefs.getString(_criticalDataKey);
      if (backupData != null) {
        final data = jsonDecode(backupData);
        if (data.containsKey('userData')) {
          return UserData.fromJson(data['userData']);
        } else {
          return UserData.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('UserDataCacheManager: Error loading critical backup: $e');
    }
    return null;
  }

  /// Verify data integrity
  bool verifyDataIntegrity() {
    try {
      final storedHash = _prefs.getString(_dataHashKey);
      final cachedData = _prefs.getString(_userDataCacheKey);
      
      if (storedHash != null && cachedData != null) {
        final currentHash = cachedData.hashCode.toString();
        return storedHash == currentHash;
      }
      return false;
    } catch (e) {
      debugPrint('UserDataCacheManager: Error verifying data integrity: $e');
      return false;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      await _prefs.remove(_userDataCacheKey);
      await _prefs.remove(_lastSyncKey);
      await _prefs.remove(_dataHashKey);
      await _prefs.remove(_lastUpdateKey);
      await _prefs.remove(_criticalDataKey);
      debugPrint('UserDataCacheManager: All cache cleared');
    } catch (e) {
      debugPrint('UserDataCacheManager: Error clearing cache: $e');
    }
  }
}
