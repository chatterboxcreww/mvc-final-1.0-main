// lib/core/services/improved_step_tracking_service.dart

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'unified_step_storage_service.dart';

/// Improved step tracking service with sensor fusion and validation
class ImprovedStepTrackingService {
  ImprovedStepTrackingService._();
  static final ImprovedStepTrackingService _instance = ImprovedStepTrackingService._();
  factory ImprovedStepTrackingService() => _instance;

  final UnifiedStepStorageService _storage = UnifiedStepStorageService();
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  
  static const platform = MethodChannel('step_counter_service');
  
  bool _isRunning = false;
  bool _nativeServiceAvailable = true;
  int _lastStepCount = 0;
  DateTime? _lastUpdateTime;
  String _activityType = 'unknown';
  
  // Step smoothing
  final List<int> _stepHistory = [];
  static const int _smoothingWindow = 5;
  
  // Callbacks
  final List<Function(int, String)> _stepCallbacks = [];
  final List<Function(String)> _errorCallbacks = [];
  
  /// Add step count callback
  void addStepCallback(Function(int steps, String activity) callback) {
    if (!_stepCallbacks.contains(callback)) {
      _stepCallbacks.add(callback);
    }
  }
  
  /// Remove step count callback
  void removeStepCallback(Function(int, String) callback) {
    _stepCallbacks.remove(callback);
  }
  
  /// Add error callback
  void addErrorCallback(Function(String) callback) {
    if (!_errorCallbacks.contains(callback)) {
      _errorCallbacks.add(callback);
    }
  }
  
  /// Remove error callback
  void removeErrorCallback(Function(String) callback) {
    _errorCallbacks.remove(callback);
  }

  /// Start step tracking
  Future<void> start() async {
    if (_isRunning) return;
    
    debugPrint('ImprovedStepTrackingService: Starting');
    
    // Initialize storage
    await _storage.initialize();
    
    // Try to start native service first
    final nativeStarted = await _startNativeService();
    
    if (nativeStarted) {
      // Set up communication channel
      _setupNativeChannel();
      
      // Get initial step count
      final initialSteps = await getCurrentSteps();
      await _storage.updateTodaySteps(initialSteps);
      _lastStepCount = initialSteps;
    } else {
      // Fallback to pedometer package
      _startPedometerFallback();
    }
    
    // Start periodic new day check
    _startNewDayCheck();
    
    _isRunning = true;
    debugPrint('ImprovedStepTrackingService: Started successfully');
  }

  /// Start native Android service
  Future<bool> _startNativeService() async {
    try {
      await platform.invokeMethod('startStepService');
      _nativeServiceAvailable = true;
      debugPrint('ImprovedStepTrackingService: Native service started');
      return true;
    } catch (e) {
      debugPrint('ImprovedStepTrackingService: Native service unavailable: $e');
      _nativeServiceAvailable = false;
      _notifyError('Native service unavailable, using fallback');
      return false;
    }
  }

  /// Setup native communication channel
  void _setupNativeChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStepCountUpdate':
          final int steps = call.arguments as int;
          await _handleStepUpdate(steps, 'native');
          break;
        case 'onActivityUpdate':
          final String activity = call.arguments as String;
          _activityType = activity;
          break;
        case 'onServiceError':
          final String error = call.arguments as String;
          _notifyError(error);
          break;
      }
    });
  }

  /// Start pedometer fallback
  void _startPedometerFallback() {
    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          await _handleStepUpdate(event.steps, 'pedometer');
        },
        onError: (error) {
          debugPrint('ImprovedStepTrackingService: Pedometer error: $error');
          _notifyError('Pedometer error: $error');
        },
      );
      
      _statusSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          _activityType = event.status;
        },
        onError: (error) {
          debugPrint('ImprovedStepTrackingService: Status error: $error');
        },
      );
      
      debugPrint('ImprovedStepTrackingService: Pedometer fallback started');
    } catch (e) {
      debugPrint('ImprovedStepTrackingService: Failed to start pedometer: $e');
      _notifyError('Step detection not available on this device');
    }
  }

  /// Handle step update with validation and smoothing
  Future<void> _handleStepUpdate(int rawSteps, String source) async {
    try {
      // Validate step count
      if (!_isValidStepCount(rawSteps)) {
        debugPrint('ImprovedStepTrackingService: Invalid step count: $rawSteps');
        return;
      }
      
      // Apply smoothing
      final smoothedSteps = _applySmoothingFilter(rawSteps);
      
      // Detect anomalies
      if (_isAnomalousUpdate(smoothedSteps)) {
        debugPrint('ImprovedStepTrackingService: Anomalous update detected: $smoothedSteps');
        return;
      }
      
      // Update storage
      await _storage.updateTodaySteps(smoothedSteps, deviceSteps: rawSteps);
      
      _lastStepCount = smoothedSteps;
      _lastUpdateTime = DateTime.now();
      
      // Notify callbacks
      _notifyStepUpdate(smoothedSteps, _activityType);
      
      debugPrint('ImprovedStepTrackingService: Updated steps: $smoothedSteps (source: $source)');
    } catch (e) {
      debugPrint('ImprovedStepTrackingService: Error handling step update: $e');
      _notifyError('Error updating steps: $e');
    }
  }

  /// Apply smoothing filter to reduce noise
  int _applySmoothingFilter(int newSteps) {
    _stepHistory.add(newSteps);
    
    if (_stepHistory.length > _smoothingWindow) {
      _stepHistory.removeAt(0);
    }
    
    if (_stepHistory.length < 3) {
      return newSteps;
    }
    
    // Use median filter to remove outliers
    final sorted = List<int>.from(_stepHistory)..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Validate step count
  bool _isValidStepCount(int steps) {
    // Basic range check
    if (steps < 0 || steps > 100000) {
      return false;
    }
    
    // Check for reasonable increase
    if (_lastStepCount > 0) {
      final increase = steps - _lastStepCount;
      
      // Max 1000 steps increase per update (should be much less normally)
      if (increase > 1000) {
        return false;
      }
      
      // Don't allow decrease (unless device reboot)
      if (increase < -100) {
        return false;
      }
    }
    
    return true;
  }

  /// Detect anomalous updates
  bool _isAnomalousUpdate(int steps) {
    if (_lastUpdateTime == null) return false;
    
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
    final stepIncrease = steps - _lastStepCount;
    
    // If too many steps in too short a time, it's likely an error
    if (timeSinceLastUpdate.inSeconds < 10 && stepIncrease > 100) {
      return true;
    }
    
    // If steps decreased significantly, it's an anomaly
    if (stepIncrease < -50) {
      return true;
    }
    
    return false;
  }

  /// Get current step count
  Future<int> getCurrentSteps() async {
    if (_nativeServiceAvailable) {
      try {
        final steps = await platform.invokeMethod<int>('getCurrentSteps');
        return steps ?? _lastStepCount;
      } catch (e) {
        debugPrint('ImprovedStepTrackingService: Error getting current steps: $e');
      }
    }
    
    // Fallback to storage
    final today = await _storage.getTodayStepData();
    return today.steps;
  }

  /// Get activity type
  Future<String> getActivityType() async {
    if (_nativeServiceAvailable) {
      try {
        final activity = await platform.invokeMethod<String>('getActivityType');
        return activity ?? _activityType;
      } catch (e) {
        debugPrint('ImprovedStepTrackingService: Error getting activity: $e');
      }
    }
    
    return _activityType;
  }

  /// Calibrate stride length
  Future<void> calibrateStride(double strideLength) async {
    try {
      if (_nativeServiceAvailable) {
        await platform.invokeMethod('calibrateStride', {'strideLength': strideLength});
      }
      
      // Update storage calibration
      final currentCalibration = await _storage.getUserCalibration();
      final newCalibration = UserCalibration(
        strideLength: strideLength,
        caloriesPerStep: currentCalibration.caloriesPerStep,
        weight: currentCalibration.weight,
        height: currentCalibration.height,
      );
      
      await _storage.setUserCalibration(newCalibration);
      debugPrint('ImprovedStepTrackingService: Stride calibrated to $strideLength meters');
    } catch (e) {
      debugPrint('ImprovedStepTrackingService: Error calibrating stride: $e');
      _notifyError('Error calibrating stride: $e');
    }
  }

  /// Set user calibration from height and weight
  Future<void> setUserCalibration({required double height, required double weight}) async {
    final calibration = UserCalibration.fromUserData(height: height, weight: weight);
    await _storage.setUserCalibration(calibration);
    
    // Also calibrate native service
    if (_nativeServiceAvailable) {
      try {
        await platform.invokeMethod('calibrateStride', {'strideLength': calibration.strideLength});
      } catch (e) {
        debugPrint('ImprovedStepTrackingService: Error setting native calibration: $e');
      }
    }
    
    debugPrint('ImprovedStepTrackingService: User calibration set - height: $height, weight: $weight');
  }

  /// Start periodic new day check
  void _startNewDayCheck() {
    Timer.periodic(const Duration(hours: 1), (timer) async {
      await _checkForNewDay();
    });
  }

  /// Check for new day
  Future<void> _checkForNewDay() async {
    final today = await _storage.getTodayStepData();
    final now = DateTime.now();
    
    if (!_isSameDay(today.date, now)) {
      debugPrint('ImprovedStepTrackingService: New day detected, resetting');
      await _storage.resetForNewDay();
      _lastStepCount = 0;
      _stepHistory.clear();
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Notify step update
  void _notifyStepUpdate(int steps, String activity) {
    for (final callback in _stepCallbacks) {
      try {
        callback(steps, activity);
      } catch (e) {
        debugPrint('ImprovedStepTrackingService: Error in step callback: $e');
      }
    }
  }

  /// Notify error
  void _notifyError(String error) {
    for (final callback in _errorCallbacks) {
      try {
        callback(error);
      } catch (e) {
        debugPrint('ImprovedStepTrackingService: Error in error callback: $e');
      }
    }
  }

  /// Stop service
  Future<void> stop() async {
    if (!_isRunning) return;
    
    debugPrint('ImprovedStepTrackingService: Stopping');
    
    // Save current state
    await _storage.forceSave();
    
    // Stop native service
    if (_nativeServiceAvailable) {
      try {
        await platform.invokeMethod('stopStepService');
      } catch (e) {
        debugPrint('ImprovedStepTrackingService: Error stopping native service: $e');
      }
    }
    
    // Cancel subscriptions
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    
    _isRunning = false;
    debugPrint('ImprovedStepTrackingService: Stopped');
  }

  /// Dispose
  void dispose() {
    stop();
    _stepCallbacks.clear();
    _errorCallbacks.clear();
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'nativeServiceAvailable': _nativeServiceAvailable,
      'lastStepCount': _lastStepCount,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'activityType': _activityType,
      'callbackCount': _stepCallbacks.length,
    };
  }
}
