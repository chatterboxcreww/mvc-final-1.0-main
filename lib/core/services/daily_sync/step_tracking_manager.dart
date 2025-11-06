// lib/core/services/daily_sync/step_tracking_manager.dart

import 'package:flutter/foundation.dart';

import '../../models/daily_step_data.dart';
import 'sync_constants.dart';
import 'local_storage_manager.dart';

/// Manages step tracking operations
class StepTrackingManager {
  final LocalStorageManager _localStorage;

  StepTrackingManager(this._localStorage);

  /// Get today's step count
  Future<int> getTodaysStepCount() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final stepData = await _localStorage.getStepData();
      
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
      
      final stepData = await _localStorage.getStepData();
      
      // Get existing goal or use default/provided goal
      int stepGoal = goal ?? SyncConstants.defaultStepGoal;
      final existingTodayData = stepData.where((data) => 
          data.date.toIso8601String().split('T')[0] == todayStr).firstOrNull;
      if (existingTodayData != null && goal == null) {
        stepGoal = existingTodayData.goal;
      }
      
      // Remove existing data for today
      stepData.removeWhere((data) => 
          data.date.toIso8601String().split('T')[0] == todayStr);
      
      // Add new data for today
      final newStepData = DailyStepData(
        date: today,
        steps: steps,
        goal: stepGoal,
        distanceMeters: (steps * SyncConstants.stepsToMetersMultiplier),
        caloriesBurned: (steps * SyncConstants.stepsToCaloriesMultiplier),
      );
      
      stepData.add(newStepData);
      await _localStorage.saveStepData(stepData);
      
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
      final allStepData = await _localStorage.getStepData();
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
      final stepData = await _localStorage.getStepData();
      
      final todaysData = stepData.where((data) => 
          data.date.toIso8601String().split('T')[0] == today).firstOrNull;
      
      return todaysData?.goal ?? SyncConstants.defaultStepGoal;
    } catch (e) {
      debugPrint('Error getting today\'s step goal: $e');
      return SyncConstants.defaultStepGoal;
    }
  }

  /// Update step data for specific date
  Future<void> updateStepDataForDate(DailyStepData stepData) async {
    try {
      final allStepData = await _localStorage.getStepData();
      final dateStr = stepData.date.toIso8601String().split('T')[0];
      
      // Remove existing data for the same date and add updated data
      allStepData.removeWhere((data) => 
          data.date.toIso8601String().split('T')[0] == dateStr);
      allStepData.add(stepData);
      
      await _localStorage.saveStepData(allStepData);
      debugPrint('Step data updated for date: $dateStr');
    } catch (e) {
      debugPrint('Error updating step data for date: $e');
    }
  }
}
