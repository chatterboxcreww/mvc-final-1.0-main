// lib/core/services/conflict_resolution_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import '../models/daily_step_data.dart';
import '../models/achievement.dart';

/// Service for resolving conflicts between local and remote data
class ConflictResolutionService {
  static final ConflictResolutionService _instance = ConflictResolutionService._internal();
  factory ConflictResolutionService() => _instance;
  ConflictResolutionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _conflictLogKey = 'conflict_resolution_log';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';

  /// Resolve conflict between local and remote data using last-write-wins strategy
  Future<T> resolveConflict<T>({
    required T localData,
    required T remoteData,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
    required String dataType,
  }) async {
    try {
      // Log the conflict for debugging
      await _logConflict(dataType, localTimestamp, remoteTimestamp);
      
      // Last-write-wins strategy
      final T resolvedData;
      if (localTimestamp.isAfter(remoteTimestamp)) {
        resolvedData = localData;
        debugPrint('ConflictResolution: Using local data for $dataType (local: $localTimestamp > remote: $remoteTimestamp)');
      } else {
        resolvedData = remoteData;
        debugPrint('ConflictResolution: Using remote data for $dataType (remote: $remoteTimestamp >= local: $localTimestamp)');
      }
      
      return resolvedData;
    } catch (e) {
      debugPrint('ConflictResolution: Error resolving conflict for $dataType: $e');
      // Fallback to remote data in case of error
      return remoteData;
    }
  }

  /// Sync user data with conflict resolution
  Future<UserData?> syncUserDataWithConflictResolution(UserData localData, DateTime localTimestamp) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get remote data
      final remoteDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!remoteDoc.exists) {
        // No remote data, upload local data
        await _uploadUserData(localData, localTimestamp);
        return localData;
      }

      final remoteDataMap = remoteDoc.data()!;
      final remoteTimestamp = (remoteDataMap['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now();
      final remoteData = UserData.fromJson(remoteDataMap);

      // Check if conflict exists
      if (_hasUserDataConflict(localData, remoteData)) {
        // Resolve conflict
        final resolvedData = await resolveConflict<UserData>(
          localData: localData,
          remoteData: remoteData,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
          dataType: 'UserData',
        );

        // Upload resolved data to Firebase
        await _uploadUserData(resolvedData, DateTime.now());
        return resolvedData;
      } else {
        // No conflict, use newer data
        if (localTimestamp.isAfter(remoteTimestamp)) {
          await _uploadUserData(localData, localTimestamp);
          return localData;
        } else {
          return remoteData;
        }
      }
    } catch (e) {
      debugPrint('ConflictResolution: Error syncing user data: $e');
      return localData; // Fallback to local data
    }
  }

  /// Sync step data with conflict resolution
  Future<List<DailyStepData>> syncStepDataWithConflictResolution(
    List<DailyStepData> localStepData,
    DateTime localTimestamp,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return localStepData;

      // Get remote step data
      final remoteSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stepData')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      if (remoteSnapshot.docs.isEmpty) {
        // No remote data, upload local data
        await _uploadStepData(localStepData);
        return localStepData;
      }

      final remoteStepData = remoteSnapshot.docs.map((doc) {
        final data = doc.data();
        return DailyStepData(
          date: (data['date'] as Timestamp).toDate(),
          steps: data['steps'] ?? 0,
          goal: data['goal'] ?? 10000,
          deviceStepsAtSave: data['deviceStepsAtSave'] ?? 0,
        );
      }).toList();

      // Merge and resolve conflicts
      final mergedData = await _mergeStepData(localStepData, remoteStepData, localTimestamp);
      
      // Upload merged data
      await _uploadStepData(mergedData);
      return mergedData;
    } catch (e) {
      debugPrint('ConflictResolution: Error syncing step data: $e');
      return localStepData;
    }
  }

  /// Sync achievements with conflict resolution
  Future<List<Achievement>> syncAchievementsWithConflictResolution(
    List<Achievement> localAchievements,
    DateTime localTimestamp,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return localAchievements;

      // Get remote achievements
      final remoteDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .doc('progress')
          .get();

      if (!remoteDoc.exists) {
        // No remote data, upload local data
        await _uploadAchievements(localAchievements);
        return localAchievements;
      }

      final remoteDataMap = remoteDoc.data()!;
      final remoteTimestamp = (remoteDataMap['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now();
      final remoteProgressData = remoteDataMap['progress'] as Map<String, dynamic>? ?? {};

      // Merge achievements
      final mergedAchievements = await _mergeAchievements(
        localAchievements,
        remoteProgressData,
        localTimestamp,
        remoteTimestamp,
      );

      // Upload merged data
      await _uploadAchievements(mergedAchievements);
      return mergedAchievements;
    } catch (e) {
      debugPrint('ConflictResolution: Error syncing achievements: $e');
      return localAchievements;
    }
  }

  /// Check if user data has conflicts
  bool _hasUserDataConflict(UserData local, UserData remote) {
    return local.name != remote.name ||
           local.age != remote.age ||
           local.height != remote.height ||
           local.weight != remote.weight ||
           local.dailyStepGoal != remote.dailyStepGoal ||
           local.dailyWaterGoal != remote.dailyWaterGoal ||
           local.level != remote.level;
  }

  /// Merge step data from local and remote sources
  Future<List<DailyStepData>> _mergeStepData(
    List<DailyStepData> localData,
    List<DailyStepData> remoteData,
    DateTime localTimestamp,
  ) async {
    final Map<String, DailyStepData> mergedMap = {};

    // Add remote data first
    for (final stepData in remoteData) {
      final dateKey = stepData.date.toIso8601String().split('T')[0];
      mergedMap[dateKey] = stepData;
    }

    // Overlay local data (newer data wins)
    for (final stepData in localData) {
      final dateKey = stepData.date.toIso8601String().split('T')[0];
      final existing = mergedMap[dateKey];
      
      if (existing == null || stepData.steps > existing.steps) {
        // Use local data if it's new or has more steps (assuming more accurate)
        mergedMap[dateKey] = stepData;
      }
    }

    // Convert back to list and sort
    final mergedList = mergedMap.values.toList();
    mergedList.sort((a, b) => b.date.compareTo(a.date));
    
    return mergedList.take(30).toList(); // Keep only last 30 days
  }

  /// Merge achievements from local and remote sources
  Future<List<Achievement>> _mergeAchievements(
    List<Achievement> localAchievements,
    Map<String, dynamic> remoteProgressData,
    DateTime localTimestamp,
    DateTime remoteTimestamp,
  ) async {
    final Map<String, Achievement> mergedMap = {};

    // Start with local achievements
    for (final achievement in localAchievements) {
      mergedMap[achievement.id] = achievement;
    }

    // Merge remote progress
    for (final entry in remoteProgressData.entries) {
      final achievementId = entry.key;
      final remoteProgress = entry.value as Map<String, dynamic>;
      
      final localAchievement = mergedMap[achievementId];
      if (localAchievement != null) {
        // Merge progress - use higher values
        final remoteCurrentValue = remoteProgress['currentValue'] ?? 0;
        final remoteIsUnlocked = remoteProgress['isUnlocked'] ?? false;
        final remoteUnlockedAt = remoteProgress['unlockedAt'] != null
            ? DateTime.parse(remoteProgress['unlockedAt'])
            : null;

        // Use the achievement with higher progress or unlocked status
        if (remoteIsUnlocked && !localAchievement.isUnlocked) {
          // Remote is unlocked but local isn't
          mergedMap[achievementId] = localAchievement.copyWith(
            isUnlocked: true,
            unlockedAt: remoteUnlockedAt,
            currentValue: remoteCurrentValue,
            progress: 1.0,
          );
        } else if (remoteCurrentValue > localAchievement.currentValue) {
          // Remote has higher progress
          mergedMap[achievementId] = localAchievement.copyWith(
            currentValue: remoteCurrentValue,
            progress: remoteCurrentValue / localAchievement.targetValue,
          );
        }
      }
    }

    return mergedMap.values.toList();
  }

  /// Upload user data to Firebase
  Future<void> _uploadUserData(UserData userData, DateTime timestamp) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        ...userData.toJson(),
        'lastUpdated': Timestamp.fromDate(timestamp),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ConflictResolution: Error uploading user data: $e');
    }
  }

  /// Upload step data to Firebase
  Future<void> _uploadStepData(List<DailyStepData> stepData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      
      for (final data in stepData) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stepData')
            .doc(data.date.toIso8601String().split('T')[0]);
        
        batch.set(docRef, {
          'date': Timestamp.fromDate(data.date),
          'steps': data.steps,
          'goal': data.goal,
          'deviceStepsAtSave': data.deviceStepsAtSave,
          'goalReached': data.goalReached,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('ConflictResolution: Error uploading step data: $e');
    }
  }

  /// Upload achievements to Firebase
  Future<void> _uploadAchievements(List<Achievement> achievements) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final progressData = <String, dynamic>{};
      for (final achievement in achievements) {
        progressData[achievement.id] = {
          'isUnlocked': achievement.isUnlocked,
          'unlockedAt': achievement.unlockedAt?.toIso8601String(),
          'currentValue': achievement.currentValue,
          'progress': achievement.progress,
        };
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .doc('progress')
          .set({
        'progress': progressData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ConflictResolution: Error uploading achievements: $e');
    }
  }

  /// Log conflict for debugging
  Future<void> _logConflict(String dataType, DateTime localTime, DateTime remoteTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingLog = prefs.getString(_conflictLogKey) ?? '[]';
      final List<dynamic> log = jsonDecode(existingLog);
      
      log.add({
        'dataType': dataType,
        'localTimestamp': localTime.toIso8601String(),
        'remoteTimestamp': remoteTime.toIso8601String(),
        'resolvedAt': DateTime.now().toIso8601String(),
        'resolution': localTime.isAfter(remoteTime) ? 'local' : 'remote',
      });
      
      // Keep only last 50 conflicts
      if (log.length > 50) {
        log.removeRange(0, log.length - 50);
      }
      
      await prefs.setString(_conflictLogKey, jsonEncode(log));
    } catch (e) {
      debugPrint('ConflictResolution: Error logging conflict: $e');
    }
  }

  /// Get conflict resolution statistics
  Future<Map<String, dynamic>> getConflictStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logJson = prefs.getString(_conflictLogKey) ?? '[]';
      final List<dynamic> log = jsonDecode(logJson);
      
      final stats = <String, int>{};
      int localWins = 0;
      int remoteWins = 0;
      
      for (final entry in log) {
        final dataType = entry['dataType'] as String;
        final resolution = entry['resolution'] as String;
        
        stats[dataType] = (stats[dataType] ?? 0) + 1;
        
        if (resolution == 'local') {
          localWins++;
        } else {
          remoteWins++;
        }
      }
      
      return {
        'totalConflicts': log.length,
        'localWins': localWins,
        'remoteWins': remoteWins,
        'conflictsByType': stats,
        'lastConflict': log.isNotEmpty ? log.last['resolvedAt'] : null,
      };
    } catch (e) {
      debugPrint('ConflictResolution: Error getting conflict stats: $e');
      return {};
    }
  }

  /// Clear conflict log
  Future<void> clearConflictLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conflictLogKey);
    } catch (e) {
      debugPrint('ConflictResolution: Error clearing conflict log: $e');
    }
  }

  /// Set last sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncTimestampKey, timestamp.toIso8601String());
    } catch (e) {
      debugPrint('ConflictResolution: Error setting last sync timestamp: $e');
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_lastSyncTimestampKey);
      return timestampString != null ? DateTime.parse(timestampString) : null;
    } catch (e) {
      debugPrint('ConflictResolution: Error getting last sync timestamp: $e');
      return null;
    }
  }
}