// lib/core/services/achievement_background_service.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/user_data.dart';
import 'storage_service.dart';
import '../providers/achievement_provider.dart'; // Import AchievementProvider
import '../models/daily_checkin_data.dart'; // Import DailyCheckinData
import '../models/daily_step_data.dart'; // Import DailyStepData

// Constants for background tasks
const String ACHIEVEMENT_CHECK_TASK = "com.healthapp.achievement_check";
const String ACHIEVEMENT_BACKGROUND_PORT = "achievement_background_port";
const int checkIntervalMinutes = 60; // Check achievements every hour

// Import notification constants
// ACHIEVEMENT_NOTIFICATION_BASE_ID is defined in notification_service.dart

// Make this accessible as a static constant for external use
class AchievementBackgroundConstants {
  static const String checkTaskName = ACHIEVEMENT_CHECK_TASK;
}

class AchievementBackgroundService {
  static final AchievementBackgroundService _instance = AchievementBackgroundService._internal();
  factory AchievementBackgroundService() => _instance;
  AchievementBackgroundService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  ReceivePort? _port;
  bool _isInitialized = false;
  DateTime? _lastCheckTime;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print("AchievementBackgroundService: Initializing...");

    // Register background task handler
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Set up communication port for background tasks
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(
        _port!.sendPort,
        ACHIEVEMENT_BACKGROUND_PORT
    );

    _port!.listen((dynamic data) {
      print("AchievementBackgroundService: Received from background: $data");
      _processCheckResult(data);
    });

    // Load last check time
    await _loadLastCheckTime();

    _isInitialized = true;
    print("AchievementBackgroundService: Initialized successfully");
  }

  // Load last check time from SharedPreferences
  Future<void> _loadLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckTimeStr = prefs.getString('last_achievement_check_time');
    if (lastCheckTimeStr != null) {
      _lastCheckTime = DateTime.parse(lastCheckTimeStr);
    }
    print("AchievementBackgroundService: Loaded last check time: $_lastCheckTime");
  }

  // Save last check time to SharedPreferences
  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastCheckTime != null) {
      await prefs.setString('last_achievement_check_time', _lastCheckTime!.toIso8601String());
    }
  }

  // Process check result from background task
  void _processCheckResult(dynamic data) {
    if (data is Map && data.containsKey('success') && data.containsKey('unlockedAchievements')) {
      if (data['success']) {
        _lastCheckTime = DateTime.now();
        _saveLastCheckTime();

        final unlockedAchievements = data['unlockedAchievements'] as List<dynamic>;
        print("AchievementBackgroundService: Processed ${unlockedAchievements.length} unlocked achievements");
      }
    }
  }

  // Schedule periodic achievement check task
  Future<void> schedulePeriodicCheck() async {
    try {
      await Workmanager().registerPeriodicTask(
        'achievement_check_periodic',
        ACHIEVEMENT_CHECK_TASK,
        // FIX: Changed CHECK_INTERVAL_MINUTES to the correctly defined checkIntervalMinutes
        frequency: Duration(minutes: checkIntervalMinutes),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      // Also register a one-time task to run immediately
      await Workmanager().registerOneOffTask(
        'achievement_check_immediate',
        ACHIEVEMENT_CHECK_TASK,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      print("AchievementBackgroundService: Scheduled periodic check task");
    } catch (e) {
      print("AchievementBackgroundService: Failed to schedule periodic check - $e");
    }
  }

  // Check for achievements in the background
  Future<Map<String, dynamic>> checkAchievementsInBackground() async {
    final user = _auth.currentUser;
    if (user == null) return {'success': false, 'unlockedAchievements': []};

    try {
      print("AchievementBackgroundService: Starting background achievement check");

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return {'success': false, 'unlockedAchievements': []};
      }

      final userData = UserData.fromJson(userDoc.data()!);

      // Fetch raw data needed for achievement checks
      final List<DailyStepData> weeklyStepData = await _storageService.getWeeklyStepData();
      final List<DailyCheckinData> checkinHistory = await _storageService.getCheckinHistory();
      // For comment count, you might need to query Firebase directly or pass it if stored elsewhere
      // For simplicity, we'll pass 0 for now, or you can implement a Firebase query here.
      final int totalCommentCount = 0; // Placeholder

      final achievementProvider = AchievementProvider();

      // Run the centralized achievement check
      await achievementProvider.checkAchievements(
        userData,
        weeklyStepData,
        checkinHistory,
        totalCommentCount,
      );

      // The checkAchievements method now handles saving and notifications internally.
      // We can return the list of newly unlocked achievements if needed.
      final newlyUnlocked = achievementProvider.newlyUnlockedAchievement;
      final unlockedList = newlyUnlocked != null ? [newlyUnlocked.id] : [];

      print("AchievementBackgroundService: Background check completed.");
      return {
        'success': true,
        'unlockedAchievements': unlockedList,
      };
    } catch (e) {
      print("AchievementBackgroundService: Error checking achievements: $e");
      return {'success': false, 'unlockedAchievements': []};
    }
  }



  // Clean up resources
  void dispose() {
    IsolateNameServer.removePortNameMapping(ACHIEVEMENT_BACKGROUND_PORT);
    _port?.close();
  }
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // print("AchievementBackgroundService: Background task started: $task");

    if (task == AchievementBackgroundConstants.checkTaskName) {
      final achievementService = AchievementBackgroundService();

      // Initialize the service first
      await achievementService.initialize();

      // Perform the check
      final result = await achievementService.checkAchievementsInBackground();

      // Try to send result back to main isolate
      SendPort? sendPort = IsolateNameServer.lookupPortByName(ACHIEVEMENT_BACKGROUND_PORT);
      if (sendPort != null) {
        sendPort.send(result);
      }
    }

    return true;
  });
}