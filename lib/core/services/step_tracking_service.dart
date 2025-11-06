// lib/core/services/step_tracking_service.dart

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

class StepTrackingConstants {
  static const syncTaskName = 'sync_steps_background';
  static const platform = MethodChannel('step_counter_service');
  
  // Enhanced communication settings
  static const updateInterval = Duration(seconds: 2);
  static const maxRetries = 3;
  static const syncInterval = Duration(minutes: 15);
}

class StepTrackingService {
  StepTrackingService._();
  static final StepTrackingService _i = StepTrackingService._();
  factory StepTrackingService() => _i;

  StreamSubscription<StepCount>? _sub;
  bool _backgroundServiceRunning = false;
  bool _stepDetectionAvailable = true;
  Timer? _syncTimer;
  Timer? _healthCheckTimer;
  int _lastKnownStepCount = 0;
  DateTime? _lastUpdateTime;
  
  // Enhanced step count callback for Flutter updates with weak reference support
  final List<Function(int)> _stepCountCallbacks = [];
  final List<Function(String)> _errorCallbacks = [];
  
  // Set callback for step count updates from Kotlin (supports multiple listeners)
  void addStepCountCallback(Function(int) callback) {
    if (!_stepCountCallbacks.contains(callback)) {
      _stepCountCallbacks.add(callback);
      print('StepTrackingService: Added step count callback (total: ${_stepCountCallbacks.length})');
    }
  }
  
  // Remove callback to prevent memory leaks
  void removeStepCountCallback(Function(int) callback) {
    _stepCountCallbacks.remove(callback);
    print('StepTrackingService: Removed step count callback (remaining: ${_stepCountCallbacks.length})');
  }
  
  // Set error callback for debugging
  void addErrorCallback(Function(String) callback) {
    if (!_errorCallbacks.contains(callback)) {
      _errorCallbacks.add(callback);
    }
  }
  
  // Remove error callback
  void removeErrorCallback(Function(String) callback) {
    _errorCallbacks.remove(callback);
  }

  void start() {
    print('StepTrackingService: Starting enhanced Kotlin-Flutter step integration');
    
    // Start the enhanced background service
    _startBackgroundService();
    
    // Set up enhanced communication channel with Kotlin service
    _setupStepCountChannel();
    
    // Start health monitoring and periodic sync
    _startHealthMonitoring();
    _startPeriodicSync();
  }

  Future<void> _startBackgroundService() async {
    // Don't start background service if step detection is not available
    if (!_stepDetectionAvailable) {
      print('StepTrackingService: Step detection not available, skipping background service');
      for (final callback in _errorCallbacks) {
        try {
          callback('Step detection not available on this device');
        } catch (e) {
          print('StepTrackingService: Error in error callback: $e');
        }
      }
      return;
    }
    
    try {
      if (!_backgroundServiceRunning) {
        // Try multiple times to ensure service starts reliably
        bool started = false;
        for (int attempt = 1; attempt <= StepTrackingConstants.maxRetries; attempt++) {
          try {
            await StepTrackingConstants.platform.invokeMethod('startStepService');
            started = true;
            break;
          } catch (e) {
            print('StepTrackingService: Start attempt $attempt failed: $e');
            if (attempt < StepTrackingConstants.maxRetries) {
              await Future.delayed(Duration(seconds: attempt));
            }
          }
        }
        
        if (started) {
          _backgroundServiceRunning = true;
          print('StepTrackingService: Enhanced background step service started successfully');
          
          // Get initial step count
          _fetchInitialStepCount();
        } else {
          throw Exception('Failed to start service after ${StepTrackingConstants.maxRetries} attempts');
        }
      }
    } catch (e) {
      print('StepTrackingService: Failed to start background step service: $e');
      for (final callback in _errorCallbacks) {
        try {
          callback('Failed to start step tracking service: $e');
        } catch (e) {
          print('StepTrackingService: Error in error callback: $e');
        }
      }
      _backgroundServiceRunning = false;
    }
  }

  // Set up enhanced communication channel with Kotlin service
  void _setupStepCountChannel() {
    try {
      StepTrackingConstants.platform.setMethodCallHandler((call) async {
        try {
          switch (call.method) {
            case 'onStepCountUpdate':
              final int stepCount = call.arguments as int;
              await _handleStepCountUpdate(stepCount);
              break;
            case 'onServiceError':
              final String error = call.arguments as String;
              print('StepTrackingService: Kotlin service error: $error');
              for (final callback in _errorCallbacks) {
                try {
                  callback('Kotlin service error: $error');
                } catch (e) {
                  print('StepTrackingService: Error in error callback: $e');
                }
              }
              break;
            default:
              print('StepTrackingService: Unknown method call: ${call.method}');
          }
        } catch (e) {
          print('StepTrackingService: Error handling method call: $e');
          for (final callback in _errorCallbacks) {
            try {
              callback('Method call error: $e');
            } catch (e) {
              print('StepTrackingService: Error in error callback: $e');
            }
          }
        }
      });
      
      print('StepTrackingService: Enhanced step count communication channel established');
    } catch (e) {
      print('StepTrackingService: Failed to setup communication channel: $e');
      for (final callback in _errorCallbacks) {
        try {
          callback('Communication setup failed: $e');
        } catch (e) {
          print('StepTrackingService: Error in error callback: $e');
        }
      }
    }
  }
  
  // Enhanced step count update handler
  Future<void> _handleStepCountUpdate(int stepCount) async {
    try {
      // Validate step count is reasonable
      if (!_isValidStepCount(stepCount)) {
        print('StepTrackingService: Invalid step count received: $stepCount');
        return;
      }
      
      // Check for significant changes or regular updates
      final now = DateTime.now();
      final shouldUpdate = _lastUpdateTime == null ||
          now.difference(_lastUpdateTime!).inSeconds >= 2 ||
          (stepCount - _lastKnownStepCount).abs() >= 1;
      
      if (shouldUpdate) {
        _lastKnownStepCount = stepCount;
        _lastUpdateTime = now;
        
        print('StepTrackingService: Valid step count update: $stepCount');
        
        // Notify all registered callbacks
        for (final callback in _stepCountCallbacks) {
          try {
            callback(stepCount);
          } catch (e) {
            print('StepTrackingService: Error in callback: $e');
          }
        }
        
        // Auto-sync to Firebase periodically
        _scheduleSyncIfNeeded();
      }
    } catch (e) {
      print('StepTrackingService: Error handling step count update: $e');
      for (final callback in _errorCallbacks) {
        try {
          callback('Step count update error: $e');
        } catch (e) {
          print('StepTrackingService: Error in error callback: $e');
        }
      }
    }
  }
  
  // Enhanced step count validation
  bool _isValidStepCount(int stepCount) {
    // Basic validation rules
    if (stepCount < 0 || stepCount > 100000) {
      return false;
    }
    
    // Check for unreasonable jumps
    if (_lastKnownStepCount > 0) {
      final difference = (stepCount - _lastKnownStepCount).abs();
      // Allow max 1000 steps increase per update (should be much less in normal operation)
      if (difference > 1000) {
        return false;
      }
    }
    
    return true;
  }
  
  // Fetch initial step count from Kotlin service
  Future<void> _fetchInitialStepCount() async {
    try {
      final int steps = await getCurrentStepCount();
      if (steps > 0) {
        await _handleStepCountUpdate(steps);
      }
    } catch (e) {
      print('StepTrackingService: Failed to fetch initial step count: $e');
    }
  }

  // Get current step count from Kotlin service with retry mechanism
  Future<int> getCurrentStepCount() async {
    for (int attempt = 1; attempt <= StepTrackingConstants.maxRetries; attempt++) {
      try {
        final int steps = await StepTrackingConstants.platform.invokeMethod('getCurrentSteps');
        print('StepTrackingService: Retrieved step count: $steps (attempt $attempt)');
        return steps;
      } catch (e) {
        print('StepTrackingService: Failed to get step count (attempt $attempt): $e');
        if (attempt < StepTrackingConstants.maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }
    
    print('StepTrackingService: All attempts failed, returning cached value: $_lastKnownStepCount');
    return _lastKnownStepCount;
  }
  
  // Enhanced health monitoring
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      try {
        // Check if service is still running
        if (_backgroundServiceRunning) {
          final currentSteps = await getCurrentStepCount();
          
          // If we haven't received updates in a while, restart service
          if (_lastUpdateTime != null) {
            final timeSinceUpdate = DateTime.now().difference(_lastUpdateTime!);
            if (timeSinceUpdate.inMinutes > 10) {
              print('StepTrackingService: No updates for ${timeSinceUpdate.inMinutes} minutes, restarting service');
              await _restartService();
            }
          }
        }
      } catch (e) {
        print('StepTrackingService: Health check failed: $e');
        for (final callback in _errorCallbacks) {
          try {
            callback('Health check failed: $e');
          } catch (e) {
            print('StepTrackingService: Error in error callback: $e');
          }
        }
      }
    });
  }
  
  // Enhanced periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(StepTrackingConstants.syncInterval, (timer) async {
      await syncStepsToFirebase();
    });
  }
  
  // Schedule sync if needed (avoid too frequent syncs)
  void _scheduleSyncIfNeeded() {
    final now = DateTime.now();
    final timeSinceLastSync = _lastUpdateTime != null ? now.difference(_lastUpdateTime!) : Duration(minutes: 10);
    
    // Only sync if it's been more than 5 minutes since last sync
    if (timeSinceLastSync.inMinutes >= 5) {
      syncStepsToFirebase();
      _lastUpdateTime = now;
      print('StepTrackingService: Scheduled sync triggered after ${timeSinceLastSync.inMinutes} minutes');
    }
  }
  
  // Restart service if it becomes unresponsive
  Future<void> _restartService() async {
    try {
      print('StepTrackingService: Restarting background service');
      await stopBackgroundService();
      await Future.delayed(Duration(seconds: 2));
      await _startBackgroundService();
    } catch (e) {
      print('StepTrackingService: Failed to restart service: $e');
      for (final callback in _errorCallbacks) {
        try {
          callback('Service restart failed: $e');
        } catch (e) {
          print('StepTrackingService: Error in error callback: $e');
        }
      }
    }
  }

  Future<void> syncStepsToFirebase() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('StepTrackingService: No authenticated user for sync');
      return;
    }

    try {
      // Get current step count from Kotlin service with timeout
      final currentSteps = await getCurrentStepCount().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('StepTrackingService: Step count retrieval timed out');
          return 0;
        },
      );

      if (currentSteps <= 0) {
        print('StepTrackingService: No steps to sync');
        return;
      }

      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('steps')
          .doc(dateKey);

      // Add timeout to Firestore operation
      await ref.set({
        'count': currentSteps,
        'timestamp': FieldValue.serverTimestamp(),
        'date': '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        'source': 'kotlin_service',
        'devicePlatform': Platform.operatingSystem,
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firebase sync timeout after 10 seconds');
        },
      );

      print('StepTrackingService: Successfully synced $currentSteps steps to Firebase');
    } catch (e) {
      print('StepTrackingService: Failed to sync steps to Firebase: $e');
      // Don't call error callbacks for sync failures - they're not critical
      // The app should continue working offline
    }
  }

  void schedulePeriodicSync() {
    // Enhanced background sync using Workmanager
    try {
      Workmanager().registerPeriodicTask(
        'enhanced-step-sync-${DateTime.now().millisecondsSinceEpoch}',
        StepTrackingConstants.syncTaskName,
        frequency: Duration(minutes: 30), // Sync every 30 minutes
        initialDelay: Duration(minutes: 5),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
        inputData: {
          'source': 'kotlin_step_service',
          'version': '2.0',
        },
      );
      
      print('StepTrackingService: Enhanced periodic step sync scheduled every 30 minutes');
    } catch (e) {
      print('StepTrackingService: Failed to schedule periodic sync: $e');
      for (final callback in _errorCallbacks) {
        try {
          callback('Sync scheduling failed: $e');
        } catch (e) {
          print('StepTrackingService: Error in error callback: $e');
        }
      }
    }
  }

  Future<void> stopBackgroundService() async {
    try {
      if (_backgroundServiceRunning) {
        await StepTrackingConstants.platform.invokeMethod('stopStepService');
        _backgroundServiceRunning = false;
        print('StepTrackingService: Enhanced background step service stopped');
      }
    } catch (e) {
      print('StepTrackingService: Failed to stop background step service: $e');
      for (final callback in _errorCallbacks) {
        try {
          callback('Service stop failed: $e');
        } catch (e) {
          print('StepTrackingService: Error in error callback: $e');
        }
      }
    }
  }

  void dispose() {
    print('StepTrackingService: Disposing service and cleaning up resources');
    
    // Cancel timers
    _syncTimer?.cancel();
    _healthCheckTimer?.cancel();
    
    // Cancel subscriptions
    _sub?.cancel();
    
    // Stop background service
    stopBackgroundService();
    
    // Clear all callbacks
    _stepCountCallbacks.clear();
    _errorCallbacks.clear();
    
    print('StepTrackingService: Service disposed successfully');
  }
  
  // Get service status for debugging
  Map<String, dynamic> getServiceStatus() {
    return {
      'backgroundServiceRunning': _backgroundServiceRunning,
      'stepDetectionAvailable': _stepDetectionAvailable,
      'lastKnownStepCount': _lastKnownStepCount,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'stepCountCallbacks': _stepCountCallbacks.length,
      'errorCallbacks': _errorCallbacks.length,
    };
  }

}