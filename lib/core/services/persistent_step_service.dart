// lib/core/services/persistent_step_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_step_data.dart';

/// Persistent step tracking service to prevent data loss during app lifecycle changes
class PersistentStepService {
  static final PersistentStepService _instance = PersistentStepService._internal();
  factory PersistentStepService() => _instance;
  PersistentStepService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _autoSaveTimer;
  
  // Keys for persistent storage
  static const String _currentStepDataKey = 'persistent_current_step_data_v3';
  static const String _stepHistoryKey = 'persistent_step_history_v3';
  static const String _lastSaveTimestampKey = 'persistent_last_save_timestamp';
  static const String _deviceStepBaselineKey = 'persistent_device_baseline';
  static const String _stepGoalKey = 'persistent_step_goal';
  
  // Auto-save interval
  static const Duration _autoSaveInterval = Duration(seconds: 30);

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    
    // Start auto-save timer
    _startAutoSave();
    
    debugPrint('PersistentStepService: Initialized with auto-save every ${_autoSaveInterval.inSeconds}s');
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) async {
      await _performAutoSave();
    });
  }

  /// Perform auto-save of current step data
  Future<void> _performAutoSave() async {
    try {
      final currentData = await getCurrentStepData();
      if (currentData != null) {
        await _saveCurrentStepData(currentData);
        await _prefs?.setInt(_lastSaveTimestampKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('PersistentStepService: Auto-save error: $e');
    }
  }

  /// Save current step data with timestamp
  Future<void> saveCurrentStepData(DailyStepData stepData) async {
    await _ensureInitialized();
    await _saveCurrentStepData(stepData);
    
    // Also save to history
    await _saveToHistory(stepData);
    
    debugPrint('PersistentStepService: Saved step data - ${stepData.steps} steps for ${stepData.date}');
  }

  /// Internal method to save current step data
  Future<void> _saveCurrentStepData(DailyStepData stepData) async {
    try {
      final stepDataJson = jsonEncode({
        'date': stepData.date.toIso8601String(),
        'steps': stepData.steps,
        'goal': stepData.goal,
        'deviceStepsAtSave': stepData.deviceStepsAtSave,
        'goalReached': stepData.goalReached,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      await _prefs?.setString(_currentStepDataKey, stepDataJson);
    } catch (e) {
      debugPrint('PersistentStepService: Error saving current step data: $e');
    }
  }

  /// Restore current step data
  Future<DailyStepData?> getCurrentStepData() async {
    await _ensureInitialized();
    
    try {
      final stepDataJson = _prefs?.getString(_currentStepDataKey);
      if (stepDataJson == null) return null;
      
      final data = jsonDecode(stepDataJson);
      final savedDate = DateTime.parse(data['date']);
      final today = DateTime.now();
      
      // Check if saved data is from today
      if (_isSameDay(savedDate, today)) {
        return DailyStepData(
          date: savedDate,
          steps: data['steps'] ?? 0,
          goal: data['goal'] ?? 10000,
          deviceStepsAtSave: data['deviceStepsAtSave'] ?? 0,
        );
      } else {
        // Data is from previous day, return null to start fresh
        debugPrint('PersistentStepService: Saved data is from ${savedDate.toIso8601String().split('T')[0]}, starting fresh for today');
        return null;
      }
    } catch (e) {
      debugPrint('PersistentStepService: Error restoring step data: $e');
      return null;
    }
  }

  /// Save step data to history
  Future<void> _saveToHistory(DailyStepData stepData) async {
    try {
      final historyJson = _prefs?.getString(_stepHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      
      // Remove existing entry for the same date
      history.removeWhere((item) {
        final itemDate = DateTime.parse(item['date']);
        return _isSameDay(itemDate, stepData.date);
      });
      
      // Add new entry
      history.add({
        'date': stepData.date.toIso8601String(),
        'steps': stepData.steps,
        'goal': stepData.goal,
        'goalReached': stepData.goalReached,
      });
      
      // Keep only last 30 days
      history.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      if (history.length > 30) {
        history.removeRange(30, history.length);
      }
      
      await _prefs?.setString(_stepHistoryKey, jsonEncode(history));
    } catch (e) {
      debugPrint('PersistentStepService: Error saving to history: $e');
    }
  }

  /// Get step history
  Future<List<DailyStepData>> getStepHistory({int days = 7}) async {
    await _ensureInitialized();
    
    try {
      final historyJson = _prefs?.getString(_stepHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      
      final stepDataList = history.map((item) => DailyStepData(
        date: DateTime.parse(item['date']),
        steps: item['steps'] ?? 0,
        goal: item['goal'] ?? 10000,
      )).toList();
      
      // Sort by date (newest first) and return requested number of days
      stepDataList.sort((a, b) => b.date.compareTo(a.date));
      return stepDataList.take(days).toList();
    } catch (e) {
      debugPrint('PersistentStepService: Error getting step history: $e');
      return [];
    }
  }

  /// Update step count for today
  Future<void> updateTodaySteps(int steps, {int? deviceSteps, int? goal}) async {
    await _ensureInitialized();
    
    final today = DateTime.now();
    final currentData = await getCurrentStepData();
    
    final updatedData = DailyStepData(
      date: today,
      steps: steps.clamp(0, 100000), // Reasonable upper limit
      goal: goal ?? currentData?.goal ?? 10000,
      deviceStepsAtSave: deviceSteps ?? currentData?.deviceStepsAtSave ?? 0,
    );
    
    await saveCurrentStepData(updatedData);
  }

  /// Add steps to today's count
  Future<int> addStepsToToday(int additionalSteps) async {
    final currentData = await getCurrentStepData();
    final currentSteps = currentData?.steps ?? 0;
    final newSteps = currentSteps + additionalSteps;
    
    await updateTodaySteps(newSteps, goal: currentData?.goal);
    return newSteps;
  }

  /// Set device step baseline for calculating daily steps
  Future<void> setDeviceStepBaseline(int deviceSteps) async {
    await _ensureInitialized();
    await _prefs?.setInt(_deviceStepBaselineKey, deviceSteps);
    debugPrint('PersistentStepService: Set device step baseline to $deviceSteps');
  }

  /// Get device step baseline
  Future<int> getDeviceStepBaseline() async {
    await _ensureInitialized();
    return _prefs?.getInt(_deviceStepBaselineKey) ?? 0;
  }

  /// Calculate daily steps from device cumulative count
  Future<int> calculateDailySteps(int currentDeviceSteps) async {
    final baseline = await getDeviceStepBaseline();
    
    if (baseline == 0) {
      // First time setup - set baseline and return 0
      await setDeviceStepBaseline(currentDeviceSteps);
      return 0;
    }
    
    final dailySteps = currentDeviceSteps - baseline;
    return dailySteps.clamp(0, 100000); // Ensure reasonable bounds
  }

  /// Reset for new day
  Future<void> resetForNewDay(int currentDeviceSteps) async {
    await _ensureInitialized();
    
    // Save current data to history before reset
    final currentData = await getCurrentStepData();
    if (currentData != null && currentData.steps > 0) {
      await _saveToHistory(currentData);
    }
    
    // Set new baseline for new day
    await setDeviceStepBaseline(currentDeviceSteps);
    
    // Clear current step data
    await _prefs?.remove(_currentStepDataKey);
    
    debugPrint('PersistentStepService: Reset for new day with device baseline $currentDeviceSteps');
  }

  /// Get step statistics
  Future<Map<String, dynamic>> getStepStats() async {
    final currentData = await getCurrentStepData();
    final history = await getStepHistory(days: 7);
    
    final todaySteps = currentData?.steps ?? 0;
    final weeklyTotal = history.fold(todaySteps, (sum, data) => sum + data.steps);
    final weeklyAverage = weeklyTotal / (history.length + 1);
    final maxDaily = history.fold(todaySteps, (max, data) => data.steps > max ? data.steps : max);
    final streak = _calculateStreak([currentData, ...history].where((d) => d != null).cast<DailyStepData>().toList());
    
    return {
      'today': todaySteps,
      'goal': currentData?.goal ?? 10000,
      'weeklyTotal': weeklyTotal,
      'weeklyAverage': weeklyAverage.round(),
      'maxDaily': maxDaily,
      'streak': streak,
      'goalReached': currentData?.goalReached ?? false,
    };
  }

  /// Calculate step streak
  int _calculateStreak(List<DailyStepData> stepData) {
    if (stepData.isEmpty) return 0;
    
    stepData.sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    for (final data in stepData) {
      if (data.goalReached) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Ensure initialization
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get last save timestamp
  Future<DateTime?> getLastSaveTimestamp() async {
    await _ensureInitialized();
    final timestamp = _prefs?.getInt(_lastSaveTimestampKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Force save current data
  Future<void> forceSave() async {
    await _performAutoSave();
  }

  /// Dispose resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }
}