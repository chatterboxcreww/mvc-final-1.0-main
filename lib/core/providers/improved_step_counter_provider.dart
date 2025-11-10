// lib/core/providers/improved_step_counter_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/daily_step_data.dart';
import '../models/user_data.dart';
import '../services/improved_step_tracking_service.dart';
import '../services/unified_step_storage_service.dart';
import 'experience_provider.dart';

/// Improved step counter provider with unified storage and better accuracy
class ImprovedStepCounterProvider with ChangeNotifier {
  
  final ImprovedStepTrackingService _trackingService = ImprovedStepTrackingService();
  final UnifiedStepStorageService _storage = UnifiedStepStorageService();
  
  // Step tracking data
  int _todaySteps = 0;
  int _streak = 0;
  double _caloriesBurned = 0.0;
  double _distanceMeters = 0.0;
  String _activityType = 'unknown';
  List<DailyStepData> _weeklyStepData = [];
  bool _isInitialized = false;
  bool _isStepDetectionAvailable = true;
  
  // Provider references
  ExperienceProvider? _experienceProvider;
  dynamic _userDataProvider;
  
  // Timer for periodic updates
  Timer? _updateTimer;
  
  // Getters
  int get todaySteps => _todaySteps;
  int get streak => _streak;
  double get caloriesBurned => _caloriesBurned;
  double get distanceMeters => _distanceMeters;
  String get activityType => _activityType;
  List<DailyStepData> get weeklyStepData => List.unmodifiable(_weeklyStepData);
  bool get isStepDetectionAvailable => _isStepDetectionAvailable;
  bool get isInitialized => _isInitialized;

  /// Set provider references
  void setExperienceProvider(ExperienceProvider provider) {
    _experienceProvider = provider;
  }
  
  void setUserDataProvider(dynamic provider) {
    _userDataProvider = provider;
  }

  /// Initialize the provider
  Future<void> initialize(UserData userData) async {
    if (_isInitialized) return;
    
    debugPrint('ImprovedStepCounterProvider: Initializing');
    
    try {
      // Initialize storage
      await _storage.initialize();
      
      // Set user calibration if available
      if (userData.weight != null && userData.height != null && 
          userData.weight! > 0 && userData.height! > 0) {
        await _trackingService.setUserCalibration(
          height: userData.height!,
          weight: userData.weight!,
        );
      }
      
      // Load initial data
      await _loadInitialData();
      
      // Set up callbacks
      _trackingService.addStepCallback(_onStepUpdate);
      _trackingService.addErrorCallback(_onError);
      
      // Start tracking service
      await _trackingService.start();
      
      // Start periodic updates
      _startPeriodicUpdates();
      
      _isInitialized = true;
      debugPrint('ImprovedStepCounterProvider: Initialized with $_todaySteps steps');
      
      notifyListeners();
    } catch (e) {
      debugPrint('ImprovedStepCounterProvider: Initialization error: $e');
      _isStepDetectionAvailable = false;
      notifyListeners();
    }
  }

  /// Load initial data from storage
  Future<void> _loadInitialData() async {
    try {
      // Load today's data
      final today = await _storage.getTodayStepData();
      _todaySteps = today.steps;
      _caloriesBurned = today.caloriesBurned;
      _distanceMeters = today.distanceMeters;
      
      // Load weekly history
      _weeklyStepData = await _storage.getStepHistory(days: 7);
      
      // Calculate streak
      _calculateStreak();
      
      // Get activity type
      _activityType = await _trackingService.getActivityType();
      
      debugPrint('ImprovedStepCounterProvider: Loaded initial data - $_todaySteps steps');
    } catch (e) {
      debugPrint('ImprovedStepCounterProvider: Error loading initial data: $e');
    }
  }

  /// Handle step update from tracking service
  void _onStepUpdate(int steps, String activity) {
    _todaySteps = steps;
    _activityType = activity;
    
    // Update derived values from storage (includes calibration)
    _updateDerivedValues();
    
    // Check for goal achievement
    _checkGoalAchievement();
    
    // Notify listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Handle error from tracking service
  void _onError(String error) {
    debugPrint('ImprovedStepCounterProvider: Error from tracking service: $error');
    
    if (error.contains('not available')) {
      _isStepDetectionAvailable = false;
      notifyListeners();
    }
  }

  /// Update derived values
  Future<void> _updateDerivedValues() async {
    try {
      final today = await _storage.getTodayStepData();
      _caloriesBurned = today.caloriesBurned;
      _distanceMeters = today.distanceMeters;
    } catch (e) {
      debugPrint('ImprovedStepCounterProvider: Error updating derived values: $e');
    }
  }

  /// Check goal achievement
  Future<void> _checkGoalAchievement() async {
    try {
      final today = await _storage.getTodayStepData();
      
      // Check if goal just reached
      if (today.goalReached && _todaySteps >= today.goal) {
        // Award XP
        if (_experienceProvider != null && _userDataProvider != null) {
          await _experienceProvider!.addXpForSteps(
            _todaySteps,
            today.goal,
            _userDataProvider!.userData,
          );
          debugPrint('ImprovedStepCounterProvider: Goal achieved! Awarded XP');
        }
      }
    } catch (e) {
      debugPrint('ImprovedStepCounterProvider: Error checking goal achievement: $e');
    }
  }

  /// Calculate streak
  void _calculateStreak() {
    _streak = 0;
    final sortedData = List<DailyStepData>.from(_weeklyStepData)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final data in sortedData) {
      if (data.goalReached) {
        _streak++;
      } else {
        break;
      }
    }
  }

  /// Start periodic updates
  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _refreshData();
    });
  }

  /// Refresh data from storage
  Future<void> _refreshData() async {
    try {
      final today = await _storage.getTodayStepData();
      _todaySteps = today.steps;
      _caloriesBurned = today.caloriesBurned;
      _distanceMeters = today.distanceMeters;
      
      _weeklyStepData = await _storage.getStepHistory(days: 7);
      _calculateStreak();
      
      notifyListeners();
    } catch (e) {
      debugPrint('ImprovedStepCounterProvider: Error refreshing data: $e');
    }
  }

  /// Get today's step count
  Future<int> getTodayStepCount() async {
    return _todaySteps;
  }

  /// Get step statistics
  Future<Map<String, dynamic>> getStepStats() async {
    return await _storage.getStepStats();
  }

  /// Set step goal
  Future<void> setStepGoal(int goal) async {
    await _storage.setStepGoal(goal);
    await _refreshData();
  }

  /// Calibrate stride length manually
  Future<void> calibrateStride(double strideLength) async {
    await _trackingService.calibrateStride(strideLength);
    await _refreshData();
  }

  /// Update user calibration
  Future<void> updateUserCalibration({required double height, required double weight}) async {
    await _trackingService.setUserCalibration(height: height, weight: weight);
    await _refreshData();
  }

  /// Manual step adjustment (for corrections)
  Future<void> adjustSteps(int adjustment) async {
    final newSteps = (_todaySteps + adjustment).clamp(0, 100000);
    await _storage.updateTodaySteps(newSteps);
    await _refreshData();
    debugPrint('ImprovedStepCounterProvider: Steps adjusted by $adjustment to $newSteps');
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    debugPrint('ImprovedStepCounterProvider: Lifecycle changed to $state');
    
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app resumes
      _refreshData();
    } else if (state == AppLifecycleState.paused) {
      // Force save when app goes to background
      _storage.forceSave();
    }
  }

  /// Force sync to cloud
  Future<void> syncToCloud() async {
    await _storage.syncToCloud();
  }

  /// Sync from cloud
  Future<void> syncFromCloud() async {
    await _storage.syncFromCloud();
    await _refreshData();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _trackingService.removeStepCallback(_onStepUpdate);
    _trackingService.removeErrorCallback(_onError);
    _trackingService.dispose();
    _storage.dispose();
    super.dispose();
  }
}
