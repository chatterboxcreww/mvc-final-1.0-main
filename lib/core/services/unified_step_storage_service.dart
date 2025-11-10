// lib/core/services/unified_step_storage_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_step_data.dart';

/// Unified step storage service - single source of truth for step data
/// Replaces DailySyncService, PersistentStepService, and fragmented storage
class UnifiedStepStorageService {
  static final UnifiedStepStorageService _instance = UnifiedStepStorageService._internal();
  factory UnifiedStepStorageService() => _instance;
  UnifiedStepStorageService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _autoSaveTimer;
  Timer? _cloudSyncTimer;
  
  // Cache for performance
  DailyStepData? _todayCache;
  List<DailyStepData>? _historyCache;
  DateTime? _lastCacheUpdate;
  
  // Keys for storage
  static const String _currentStepDataKey = 'unified_current_step_data';
  static const String _stepHistoryKey = 'unified_step_history';
  static const String _lastSyncKey = 'unified_last_sync';
  static const String _userCalibrationKey = 'unified_user_calibration';
  
  // Auto-save and sync intervals
  static const Duration _autoSaveInterval = Duration(seconds: 60);
  static const Duration _cloudSyncInterval = Duration(minutes: 15);
  static const Duration _cacheValidDuration = Duration(seconds: 5);

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    
    // Load initial data into cache
    await _refreshCache();
    
    // Start auto-save and cloud sync
    _startAutoSave();
    _startCloudSync();
    
    debugPrint('UnifiedStepStorageService: Initialized');
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) async {
      await _performAutoSave();
    });
  }

  /// Start cloud sync timer
  void _startCloudSync() {
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer.periodic(_cloudSyncInterval, (_) async {
      await syncToCloud();
    });
  }

  /// Perform auto-save
  Future<void> _performAutoSave() async {
    try {
      if (_todayCache != null) {
        await _saveCurrentStepDataToLocal(_todayCache!);
      }
    } catch (e) {
      debugPrint('UnifiedStepStorageService: Auto-save error: $e');
    }
  }

  /// Refresh cache from storage
  Future<void> _refreshCache() async {
    _todayCache = await _loadCurrentStepDataFromLocal();
    _historyCache = await _loadStepHistoryFromLocal();
    _lastCacheUpdate = DateTime.now();
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Get today's step data (with caching)
  Future<DailyStepData> getTodayStepData() async {
    await _ensureInitialized();
    
    if (_todayCache != null && _isCacheValid() && _isSameDay(_todayCache!.date, DateTime.now())) {
      return _todayCache!;
    }
    
    await _refreshCache();
    
    if (_todayCache == null || !_isSameDay(_todayCache!.date, DateTime.now())) {
      // Create new entry for today
      _todayCache = DailyStepData(
        date: DateTime.now(),
        steps: 0,
        goal: await getStepGoal(),
      );
      await _saveCurrentStepDataToLocal(_todayCache!);
    }
    
    return _todayCache!;
  }

  /// Update today's step count
  Future<void> updateTodaySteps(int steps, {int? deviceSteps}) async {
    await _ensureInitialized();
    
    final today = DateTime.now();
    final goal = await getStepGoal();
    final calibration = await getUserCalibration();
    
    // Validate step count
    if (!_isValidStepCount(steps)) {
      debugPrint('UnifiedStepStorageService: Invalid step count: $steps');
      return;
    }
    
    // Calculate derived values with user calibration
    final distance = steps * calibration.strideLength;
    final calories = steps * calibration.caloriesPerStep;
    
    _todayCache = DailyStepData(
      date: today,
      steps: steps,
      goal: goal,
      distanceMeters: distance,
      caloriesBurned: calories,
      deviceStepsAtSave: deviceSteps ?? 0,
    );
    
    await _saveCurrentStepDataToLocal(_todayCache!);
    await _addToHistory(_todayCache!);
    
    _lastCacheUpdate = DateTime.now();
  }

  /// Add steps to today's count
  Future<int> addStepsToToday(int additionalSteps) async {
    final currentData = await getTodayStepData();
    final newSteps = currentData.steps + additionalSteps;
    await updateTodaySteps(newSteps);
    return newSteps;
  }

  /// Get step history
  Future<List<DailyStepData>> getStepHistory({int days = 30}) async {
    await _ensureInitialized();
    
    if (_historyCache != null && _isCacheValid()) {
      return _historyCache!.take(days).toList();
    }
    
    await _refreshCache();
    return _historyCache?.take(days).toList() ?? [];
  }

  /// Get step statistics
  Future<Map<String, dynamic>> getStepStats() async {
    final today = await getTodayStepData();
    final history = await getStepHistory(days: 7);
    
    final todaySteps = today.steps;
    final weeklyTotal = history.fold(0, (sum, data) => sum + data.steps);
    final weeklyAverage = history.isEmpty ? 0 : weeklyTotal / history.length;
    final maxDaily = history.fold(todaySteps, (max, data) => data.steps > max ? data.steps : max);
    final streak = _calculateStreak([today, ...history]);
    
    return {
      'today': todaySteps,
      'goal': today.goal,
      'weeklyTotal': weeklyTotal,
      'weeklyAverage': weeklyAverage.round(),
      'maxDaily': maxDaily,
      'streak': streak,
      'goalReached': today.goalReached,
      'distance': today.distanceMeters,
      'calories': today.caloriesBurned,
    };
  }

  /// Set step goal
  Future<void> setStepGoal(int goal) async {
    await _ensureInitialized();
    await _prefs?.setInt('step_goal', goal);
    
    // Update today's data with new goal
    if (_todayCache != null) {
      _todayCache = _todayCache!.copyWith(goal: goal);
      await _saveCurrentStepDataToLocal(_todayCache!);
    }
  }

  /// Get step goal
  Future<int> getStepGoal() async {
    await _ensureInitialized();
    return _prefs?.getInt('step_goal') ?? 10000;
  }

  /// Set user calibration
  Future<void> setUserCalibration(UserCalibration calibration) async {
    await _ensureInitialized();
    final json = jsonEncode(calibration.toJson());
    await _prefs?.setString(_userCalibrationKey, json);
    
    // Invalidate cache to recalculate with new calibration
    _todayCache = null;
    _lastCacheUpdate = null;
  }

  /// Get user calibration
  Future<UserCalibration> getUserCalibration() async {
    await _ensureInitialized();
    
    final json = _prefs?.getString(_userCalibrationKey);
    if (json != null) {
      try {
        return UserCalibration.fromJson(jsonDecode(json));
      } catch (e) {
        debugPrint('UnifiedStepStorageService: Error loading calibration: $e');
      }
    }
    
    return UserCalibration.defaultCalibration();
  }

  /// Reset for new day
  Future<void> resetForNewDay() async {
    await _ensureInitialized();
    
    // Save current data to history
    if (_todayCache != null && _todayCache!.steps > 0) {
      await _addToHistory(_todayCache!);
    }
    
    // Clear today's cache
    _todayCache = null;
    await _prefs?.remove(_currentStepDataKey);
    
    debugPrint('UnifiedStepStorageService: Reset for new day');
  }

  /// Sync to cloud (Firebase)
  Future<void> syncToCloud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final today = await getTodayStepData();
      final dateKey = _formatDate(today.date);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('steps')
          .doc(dateKey)
          .set({
        'count': today.steps,
        'goal': today.goal,
        'distance': today.distanceMeters,
        'calories': today.caloriesBurned,
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateKey,
        'goalReached': today.goalReached,
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
      );
      
      await _prefs?.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('UnifiedStepStorageService: Synced to cloud - $dateKey: ${today.steps} steps');
    } catch (e) {
      debugPrint('UnifiedStepStorageService: Cloud sync error: $e');
    }
  }

  /// Sync from cloud
  Future<void> syncFromCloud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('steps')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get()
          .timeout(const Duration(seconds: 10));
      
      final cloudData = snapshot.docs.map((doc) {
        final data = doc.data();
        return DailyStepData(
          date: DateTime.parse(data['date']),
          steps: data['count'] ?? 0,
          goal: data['goal'] ?? 10000,
          distanceMeters: (data['distance'] as num?)?.toDouble() ?? 0.0,
          caloriesBurned: (data['calories'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
      
      // Merge with local data (cloud takes precedence for older data)
      await _mergeCloudData(cloudData);
      
      debugPrint('UnifiedStepStorageService: Synced from cloud - ${cloudData.length} entries');
    } catch (e) {
      debugPrint('UnifiedStepStorageService: Cloud sync from error: $e');
    }
  }

  /// Internal: Save current step data to local storage
  Future<void> _saveCurrentStepDataToLocal(DailyStepData stepData) async {
    try {
      final json = jsonEncode({
        'date': stepData.date.toIso8601String(),
        'steps': stepData.steps,
        'goal': stepData.goal,
        'distance': stepData.distanceMeters,
        'calories': stepData.caloriesBurned,
        'deviceStepsAtSave': stepData.deviceStepsAtSave,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      await _prefs?.setString(_currentStepDataKey, json);
    } catch (e) {
      debugPrint('UnifiedStepStorageService: Error saving current data: $e');
    }
  }

  /// Internal: Load current step data from local storage
  Future<DailyStepData?> _loadCurrentStepDataFromLocal() async {
    try {
      final json = _prefs?.getString(_currentStepDataKey);
      if (json == null) return null;
      
      final data = jsonDecode(json);
      final savedDate = DateTime.parse(data['date']);
      
      // Check if data is from today
      if (_isSameDay(savedDate, DateTime.now())) {
        return DailyStepData(
          date: savedDate,
          steps: data['steps'] ?? 0,
          goal: data['goal'] ?? 10000,
          distanceMeters: (data['distance'] as num?)?.toDouble() ?? 0.0,
          caloriesBurned: (data['calories'] as num?)?.toDouble() ?? 0.0,
          deviceStepsAtSave: data['deviceStepsAtSave'] ?? 0,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('UnifiedStepStorageService: Error loading current data: $e');
      return null;
    }
  }

  /// Internal: Add to history
  Future<void> _addToHistory(DailyStepData stepData) async {
    try {
      final historyJson = _prefs?.getString(_stepHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      
      // Remove existing entry for same date
      history.removeWhere((item) {
        final itemDate = DateTime.parse(item['date']);
        return _isSameDay(itemDate, stepData.date);
      });
      
      // Add new entry
      history.add({
        'date': stepData.date.toIso8601String(),
        'steps': stepData.steps,
        'goal': stepData.goal,
        'distance': stepData.distanceMeters,
        'calories': stepData.caloriesBurned,
        'goalReached': stepData.goalReached,
      });
      
      // Sort and keep last 90 days
      history.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      if (history.length > 90) {
        history.removeRange(90, history.length);
      }
      
      await _prefs?.setString(_stepHistoryKey, jsonEncode(history));
      
      // Update cache
      _historyCache = null;
    } catch (e) {
      debugPrint('UnifiedStepStorageService: Error adding to history: $e');
    }
  }

  /// Internal: Load step history from local storage
  Future<List<DailyStepData>> _loadStepHistoryFromLocal() async {
    try {
      final historyJson = _prefs?.getString(_stepHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      
      return history.map((item) => DailyStepData(
        date: DateTime.parse(item['date']),
        steps: item['steps'] ?? 0,
        goal: item['goal'] ?? 10000,
        distanceMeters: (item['distance'] as num?)?.toDouble() ?? 0.0,
        caloriesBurned: (item['calories'] as num?)?.toDouble() ?? 0.0,
      )).toList();
    } catch (e) {
      debugPrint('UnifiedStepStorageService: Error loading history: $e');
      return [];
    }
  }

  /// Internal: Merge cloud data with local data
  Future<void> _mergeCloudData(List<DailyStepData> cloudData) async {
    final localHistory = await _loadStepHistoryFromLocal();
    final merged = <String, DailyStepData>{};
    
    // Add local data
    for (final data in localHistory) {
      merged[_formatDate(data.date)] = data;
    }
    
    // Merge cloud data (cloud takes precedence for past days)
    for (final data in cloudData) {
      final dateKey = _formatDate(data.date);
      if (!_isSameDay(data.date, DateTime.now())) {
        // For past days, cloud data takes precedence
        merged[dateKey] = data;
      }
    }
    
    // Save merged data
    final mergedList = merged.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final historyJson = jsonEncode(mergedList.map((data) => {
      'date': data.date.toIso8601String(),
      'steps': data.steps,
      'goal': data.goal,
      'distance': data.distanceMeters,
      'calories': data.caloriesBurned,
      'goalReached': data.goalReached,
    }).toList());
    
    await _prefs?.setString(_stepHistoryKey, historyJson);
    _historyCache = null;
  }

  /// Validate step count
  bool _isValidStepCount(int steps) {
    return steps >= 0 && steps <= 100000;
  }

  /// Calculate streak
  int _calculateStreak(List<DailyStepData> stepData) {
    if (stepData.isEmpty) return 0;
    
    final sorted = List<DailyStepData>.from(stepData)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    for (final data in sorted) {
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

  /// Format date as string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Ensure initialization
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Force save
  Future<void> forceSave() async {
    await _performAutoSave();
  }

  /// Dispose resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _cloudSyncTimer?.cancel();
  }
}

/// User calibration data
class UserCalibration {
  final double strideLength; // meters per step
  final double caloriesPerStep;
  final double weight; // kg
  final double height; // cm
  
  UserCalibration({
    required this.strideLength,
    required this.caloriesPerStep,
    required this.weight,
    required this.height,
  });
  
  factory UserCalibration.defaultCalibration() {
    return UserCalibration(
      strideLength: 0.762, // Average stride length
      caloriesPerStep: 0.04, // Average calories per step
      weight: 70.0,
      height: 170.0,
    );
  }
  
  factory UserCalibration.fromUserData({
    required double weight,
    required double height,
  }) {
    // Calculate stride length based on height (rough approximation)
    final strideLength = height * 0.0045; // meters
    
    // Calculate calories per step based on weight
    final caloriesPerStep = (weight * 0.00057);
    
    return UserCalibration(
      strideLength: strideLength,
      caloriesPerStep: caloriesPerStep,
      weight: weight,
      height: height,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'strideLength': strideLength,
      'caloriesPerStep': caloriesPerStep,
      'weight': weight,
      'height': height,
    };
  }
  
  factory UserCalibration.fromJson(Map<String, dynamic> json) {
    return UserCalibration(
      strideLength: (json['strideLength'] as num?)?.toDouble() ?? 0.762,
      caloriesPerStep: (json['caloriesPerStep'] as num?)?.toDouble() ?? 0.04,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      height: (json['height'] as num?)?.toDouble() ?? 170.0,
    );
  }
}
