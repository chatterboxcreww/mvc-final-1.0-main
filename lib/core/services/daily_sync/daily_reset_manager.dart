// lib/core/services/daily_sync/daily_reset_manager.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/daily_step_data.dart';
import 'sync_constants.dart';
import 'local_storage_manager.dart';

/// Manages daily reset operations
class DailyResetManager {
  final LocalStorageManager _localStorage;

  DailyResetManager(this._localStorage);

  /// Check if it's a new day and perform reset if necessary
  Future<void> checkAndPerformDailyReset() async {
    final lastSyncDate = await _localStorage.getLastSyncDate();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastSyncDate != today) {
      debugPrint('New day detected, performing daily reset');
      await performDailyReset();
      await _localStorage.setLastSyncDate(today);
    }
  }

  /// Perform daily reset - clear local data and prepare for new day
  Future<void> performDailyReset() async {
    final prefs = _localStorage.prefs;
    
    // Clear previous day's local data (but preserve certain persistent data)
    await _localStorage.clearDailyData();
    
    // CRITICAL FIX: Preserve step data for current day - don't reset steps during app refresh
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existingStepData = await _localStorage.getStepData();
    final todaysSteps = existingStepData.where((step) => 
        step.date.toIso8601String().split('T')[0] == today).toList();
    
    // FIXED: Never clear step data during app restarts - only during actual new day
    // Check if this is a genuine new day (midnight passed) vs app restart
    final lastResetDate = prefs.getString(SyncConstants.lastStepResetDateKey) ?? '';
    final isActualNewDay = lastResetDate != today;
    
    if (isActualNewDay && todaysSteps.isEmpty) {
      // This is a genuine new day and we have no step data for today
      await prefs.remove(SyncConstants.stepDataKey);
      await prefs.setString(SyncConstants.lastStepResetDateKey, today);
      debugPrint('Step data cleared for genuine new day');
    } else {
      // Keep existing step data - either same day or we have today's data
      if (todaysSteps.isNotEmpty) {
        await _localStorage.saveStepData(existingStepData);
        debugPrint('Preserved step data including today\'s ${todaysSteps.first.steps} steps');
      } else {
        debugPrint('No step data to preserve for today, but not clearing existing historical data');
      }
    }
    
    // Reset water glass count for new day only (NOT during app refresh)
    final lastWaterResetDate = prefs.getString(SyncConstants.lastWaterResetDateKey);
    if (lastWaterResetDate != today) {
      await prefs.setInt(SyncConstants.waterGlassCountKey, 0);
      await prefs.setString(SyncConstants.lastWaterResetDateKey, today);
      debugPrint('Water glass count reset to 0 for new day');
    } else {
      debugPrint('Same day - preserving water glass count');
    }
    
    await _localStorage.setSleepSyncComplete(false);
    await _localStorage.setWakeupSyncComplete(false);
    
    // Increment data version for cache invalidation
    await _localStorage.incrementDataVersion();
    
    debugPrint('Daily reset completed - water glass count reset to 0, step data preserved');
  }

  /// Ensure step data persistence on app startup
  Future<void> ensureStepDataPersistence(Future<DailyStepData?> Function() syncTodaysStepData) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existingStepData = await _localStorage.getStepData();
      
      // Check if we have step data for today
      final todaysSteps = existingStepData.where((step) => 
          step.date.toIso8601String().split('T')[0] == today).toList();
      
      if (todaysSteps.isEmpty) {
        // Try to sync today's step data from Firebase if available
        final stepData = await syncTodaysStepData();
        if (stepData != null) {
          existingStepData.removeWhere((data) => 
              data.date.toIso8601String().split('T')[0] == today);
          existingStepData.add(stepData);
          await _localStorage.saveStepData(existingStepData);
          debugPrint('Today\'s step data synced from Firebase: ${stepData.steps} steps');
        } else {
          debugPrint('No step data available from Firebase for today');
        }
      } else {
        debugPrint('Today\'s step data already available: ${todaysSteps.length} entries');
      }
    } catch (e) {
      debugPrint('Error ensuring step data persistence: $e');
    }
  }
}
