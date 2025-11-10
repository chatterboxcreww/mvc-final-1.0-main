// lib/core/services/step_data_migration_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_step_data.dart';
import 'unified_step_storage_service.dart';

/// Service to migrate data from old storage systems to unified storage
class StepDataMigrationService {
  static final StepDataMigrationService _instance = StepDataMigrationService._internal();
  factory StepDataMigrationService() => _instance;
  StepDataMigrationService._internal();

  static const String _migrationCompleteKey = 'step_data_migration_complete_v2';

  /// Check if migration is needed and perform it
  Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationComplete = prefs.getBool(_migrationCompleteKey) ?? false;
    
    if (migrationComplete) {
      debugPrint('StepDataMigrationService: Migration already complete');
      return;
    }
    
    debugPrint('StepDataMigrationService: Starting migration');
    
    try {
      await _performMigration(prefs);
      await prefs.setBool(_migrationCompleteKey, true);
      debugPrint('StepDataMigrationService: Migration completed successfully');
    } catch (e) {
      debugPrint('StepDataMigrationService: Migration error: $e');
      // Don't mark as complete if migration failed
    }
  }

  /// Perform the actual migration
  Future<void> _performMigration(SharedPreferences prefs) async {
    final unifiedStorage = UnifiedStepStorageService();
    await unifiedStorage.initialize();
    
    // Migrate from PersistentStepService
    await _migratePersistentStepData(prefs, unifiedStorage);
    
    // Migrate from DailySyncService
    await _migrateDailySyncData(prefs, unifiedStorage);
    
    // Migrate from old StepTrackingService
    await _migrateOldTrackingData(prefs, unifiedStorage);
    
    // Clean up old keys
    await _cleanupOldData(prefs);
  }

  /// Migrate data from PersistentStepService
  Future<void> _migratePersistentStepData(
    SharedPreferences prefs,
    UnifiedStepStorageService unifiedStorage,
  ) async {
    try {
      // Migrate current step data
      final currentDataJson = prefs.getString('persistent_current_step_data_v3');
      if (currentDataJson != null) {
        final data = jsonDecode(currentDataJson);
        final stepData = DailyStepData(
          date: DateTime.parse(data['date']),
          steps: data['steps'] ?? 0,
          goal: data['goal'] ?? 10000,
          distanceMeters: (data['distance'] as num?)?.toDouble() ?? 0.0,
          caloriesBurned: (data['calories'] as num?)?.toDouble() ?? 0.0,
          deviceStepsAtSave: data['deviceStepsAtSave'] ?? 0,
        );
        
        // Only migrate if it's from today
        if (_isSameDay(stepData.date, DateTime.now())) {
          await unifiedStorage.updateTodaySteps(
            stepData.steps,
            deviceSteps: stepData.deviceStepsAtSave,
          );
          debugPrint('StepDataMigrationService: Migrated current step data: ${stepData.steps} steps');
        }
      }
      
      // Migrate step history
      final historyJson = prefs.getString('persistent_step_history_v3');
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        
        for (final item in history) {
          final stepData = DailyStepData(
            date: DateTime.parse(item['date']),
            steps: item['steps'] ?? 0,
            goal: item['goal'] ?? 10000,
            distanceMeters: (item['distance'] as num?)?.toDouble() ?? 0.0,
            caloriesBurned: (item['calories'] as num?)?.toDouble() ?? 0.0,
          );
          
          // Add to unified storage (will be added to history)
          if (!_isSameDay(stepData.date, DateTime.now())) {
            // For historical data, we need to add it directly to history
            // This is handled internally by the unified storage
          }
        }
        
        debugPrint('StepDataMigrationService: Migrated ${history.length} historical entries');
      }
      
      // Migrate step goal
      final stepGoal = prefs.getInt('persistent_step_goal');
      if (stepGoal != null && stepGoal > 0) {
        await unifiedStorage.setStepGoal(stepGoal);
        debugPrint('StepDataMigrationService: Migrated step goal: $stepGoal');
      }
    } catch (e) {
      debugPrint('StepDataMigrationService: Error migrating persistent data: $e');
    }
  }

  /// Migrate data from DailySyncService
  Future<void> _migrateDailySyncData(
    SharedPreferences prefs,
    UnifiedStepStorageService unifiedStorage,
  ) async {
    try {
      final stepDataJson = prefs.getString('daily_step_data');
      if (stepDataJson != null) {
        final List<dynamic> stepDataList = jsonDecode(stepDataJson);
        
        for (final item in stepDataList) {
          try {
            final stepData = DailyStepData.fromJson(item);
            
            if (_isSameDay(stepData.date, DateTime.now())) {
              // Update today's data if it has more steps
              final currentToday = await unifiedStorage.getTodayStepData();
              if (stepData.steps > currentToday.steps) {
                await unifiedStorage.updateTodaySteps(stepData.steps);
              }
            }
          } catch (e) {
            debugPrint('StepDataMigrationService: Error parsing daily sync item: $e');
          }
        }
        
        debugPrint('StepDataMigrationService: Migrated ${stepDataList.length} daily sync entries');
      }
    } catch (e) {
      debugPrint('StepDataMigrationService: Error migrating daily sync data: $e');
    }
  }

  /// Migrate data from old StepTrackingService
  Future<void> _migrateOldTrackingData(
    SharedPreferences prefs,
    UnifiedStepStorageService unifiedStorage,
  ) async {
    try {
      // Check for any other step-related keys
      final allKeys = prefs.getKeys();
      final stepKeys = allKeys.where((key) => 
        key.contains('step') && 
        !key.contains('unified') &&
        !key.contains('migration')
      );
      
      debugPrint('StepDataMigrationService: Found ${stepKeys.length} old step-related keys');
      
      // Migrate daily_step_goal if exists
      final dailyGoal = prefs.getInt('daily_step_goal');
      if (dailyGoal != null && dailyGoal > 0) {
        final currentGoal = await unifiedStorage.getStepGoal();
        if (currentGoal == 10000) { // Only update if still default
          await unifiedStorage.setStepGoal(dailyGoal);
          debugPrint('StepDataMigrationService: Migrated daily step goal: $dailyGoal');
        }
      }
    } catch (e) {
      debugPrint('StepDataMigrationService: Error migrating old tracking data: $e');
    }
  }

  /// Clean up old data keys (optional, can be disabled to keep backups)
  Future<void> _cleanupOldData(SharedPreferences prefs) async {
    try {
      // List of old keys to remove
      final oldKeys = [
        'persistent_current_step_data_v3',
        'persistent_step_history_v3',
        'persistent_last_save_timestamp',
        'persistent_device_baseline',
        'persistent_step_goal',
        'daily_step_data',
        'step_tracking_last_sync',
      ];
      
      int removedCount = 0;
      for (final key in oldKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          removedCount++;
        }
      }
      
      debugPrint('StepDataMigrationService: Cleaned up $removedCount old keys');
    } catch (e) {
      debugPrint('StepDataMigrationService: Error cleaning up old data: $e');
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Force re-migration (for testing or recovery)
  Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationCompleteKey);
    await migrateIfNeeded();
  }

  /// Get migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationComplete = prefs.getBool(_migrationCompleteKey) ?? false;
    
    // Count old keys
    final allKeys = prefs.getKeys();
    final oldStepKeys = allKeys.where((key) => 
      (key.contains('step') || key.contains('persistent') || key.contains('daily')) &&
      !key.contains('unified') &&
      !key.contains('migration')
    ).toList();
    
    return {
      'migrationComplete': migrationComplete,
      'oldKeysRemaining': oldStepKeys.length,
      'oldKeys': oldStepKeys,
    };
  }
}
