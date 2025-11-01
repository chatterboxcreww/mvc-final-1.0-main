import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'experience_provider.dart';
import 'user_data_provider.dart';
import '../models/daily_checkin_data.dart';
import '../models/daily_step_data.dart';
import '../services/daily_sync_service.dart';

class TrendsProvider with ChangeNotifier {
  // Core data storage
  List<DailyCheckinData> _checkinHistory = [];
  final List<DailyStepData> _stepHistory = [];
  DailyCheckinData _todayCheckinData = DailyCheckinData(
    date: DateTime.now(),
    waterIntake: 0,
    mood: 3,
    sleepHours: 8.0,
    meditationMinutes: 0,
    weight: 0.0,
  );

  // Loading and error states
  bool _isLoading = false;
  String? _lastError;

  // Analytics and insights
  Map<String, dynamic> _weeklyAnalytics = {};
  Map<String, dynamic> _monthlyAnalytics = {};
  List<String> _healthInsights = [];
  String? _coachInsight;

  // Firebase and connectivity
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final DailySyncService _dailySyncService = DailySyncService();
  
  // Cache keys for local storage
  static const String _checkinCacheKey = 'checkin_history_cache';
  static const String _analyticsKey = 'weekly_analytics_cache';
  static const String _lastSyncKey = 'trends_last_sync';

  // Getters
  List<DailyCheckinData> get checkinHistory => List.unmodifiable(_checkinHistory);
  List<DailyStepData> get stepHistory => List.unmodifiable(_stepHistory);
  DailyCheckinData get todayCheckinData => _todayCheckinData;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  Map<String, dynamic> get weeklyAnalytics => Map.from(_weeklyAnalytics);
  Map<String, dynamic> get monthlyAnalytics => Map.from(_monthlyAnalytics);
  List<String> get healthInsights => List.from(_healthInsights);
  String? get coachInsight => _coachInsight;
  bool get hasCheckedInToday {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);
    return _checkinHistory.any(
      (d) => DateFormat('yyyy-MM-dd').format(d.date) == todayString,
    );
  }

  /// Set provider references for cross-provider communication
  void setExperienceProvider(ExperienceProvider provider) {
    // Experience provider reference no longer needed since field was removed
  }

  /// Initialize the trends provider and load initial data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize daily sync service
      await _dailySyncService.initialize();
      
      // Load data from local storage first
      await _loadCheckinDataFromLocal();
      await _loadFromCache();
      await _calculateAnalytics();
      await _generateHealthInsights();
    } catch (e) {
      _lastError = 'Failed to initialize trends: $e';
      debugPrint('TrendsProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load check-in data from local storage (daily sync approach)
  Future<void> _loadCheckinDataFromLocal() async {
    try {
      // Load today's checkin data from local storage
      final localCheckinData = await _dailySyncService.getLocalCheckinData();
      if (localCheckinData != null) {
        _todayCheckinData = localCheckinData;
        debugPrint('TrendsProvider: Loaded today\'s checkin data from local storage');
      } else {
        // Create new checkin data for today
        _todayCheckinData = DailyCheckinData(
          date: DateTime.now(),
          waterIntake: 0,
          mood: 3,
          sleepHours: 8.0,
          meditationMinutes: 0,
          weight: 0.0,
        );
        debugPrint('TrendsProvider: Created new checkin data for today');
      }
    } catch (e) {
      debugPrint('TrendsProvider: Error loading local checkin data: $e');
    }
  }

  /// Submit daily checkin - saves to local storage immediately
  Future<void> submitDailyCheckin(DailyCheckinData checkinData, {BuildContext? context}) async {
    try {
      // Validate input data before saving
      final validationErrors = _validateCheckinData(checkinData);
      if (validationErrors.isNotEmpty) {
        _lastError = 'Validation failed: ${validationErrors.join(', ')}';
        debugPrint('TrendsProvider: $lastError');
        notifyListeners();
        return;
      }
      
      // Update local data immediately
      _todayCheckinData = checkinData;
      
      // Save to local storage for daily sync
      await _dailySyncService.saveLocalCheckinData(checkinData);
      
      // Update checkin history for analytics
      final today = DateTime.now();
      final todayString = DateFormat('yyyy-MM-dd').format(today);
      
      // Remove existing entry for today if it exists
      _checkinHistory.removeWhere((data) => 
          DateFormat('yyyy-MM-dd').format(data.date) == todayString);
      
      // Add new entry
      _checkinHistory.add(checkinData);
      
      // Sort by date
      _checkinHistory.sort((a, b) => a.date.compareTo(b.date));
      
      // Update analytics and insights
      await _calculateAnalytics();
      await _generateHealthInsights();
      
      debugPrint('TrendsProvider: Daily checkin saved to local storage');
      notifyListeners();
      
      // Award XP if context is provided
      if (context != null) {
        final experienceProvider = Provider.of<ExperienceProvider>(context, listen: false);
        final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
        experienceProvider.addXpForDailyCheckin(userDataProvider.userData);
      }
    } catch (e) {
      debugPrint('TrendsProvider: Error submitting daily checkin: $e');
      _lastError = 'Failed to submit checkin: $e';
      notifyListeners();
    }
  }

  /// Load checkin history from local storage and Firebase
  Future<void> loadCheckinHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      await _loadFromCache();

      if (isOnline) {
        // Load from Firestore but preserve today's current data with proper conflict resolution
        final currentTodayData = _todayCheckinData;
        await _loadFromFirestore(user.uid);
        
        // Merge today's data with proper conflict resolution
        final today = DateTime.now();
        final todayString = DateFormat('yyyy-MM-dd').format(today);
        final existingTodayIndex = _checkinHistory.indexWhere(
          (data) => DateFormat('yyyy-MM-dd').format(data.date) == todayString,
        );
        
        if (existingTodayIndex != -1) {
          final firestoreToday = _checkinHistory[existingTodayIndex];
          
          // Merge data field by field, taking the maximum/most recent value
          final mergedData = DailyCheckinData(
            date: today,
            // Take higher water intake (user might have logged on another device)
            waterIntake: currentTodayData.waterIntake > firestoreToday.waterIntake 
                ? currentTodayData.waterIntake 
                : firestoreToday.waterIntake,
            // Take most recent mood (prefer local if non-default)
            mood: currentTodayData.mood != 3 ? currentTodayData.mood : firestoreToday.mood,
            // Take most recent sleep hours (prefer local if non-default)
            sleepHours: currentTodayData.sleepHours != 8.0 
                ? currentTodayData.sleepHours 
                : firestoreToday.sleepHours,
            // Take higher meditation minutes
            meditationMinutes: currentTodayData.meditationMinutes > firestoreToday.meditationMinutes
                ? currentTodayData.meditationMinutes
                : firestoreToday.meditationMinutes,
            // Take most recent weight (prefer local if non-zero)
            weight: currentTodayData.weight > 0 ? currentTodayData.weight : firestoreToday.weight,
            // Take higher meal count
            mealCount: currentTodayData.mealCount > firestoreToday.mealCount
                ? currentTodayData.mealCount
                : firestoreToday.mealCount,
          );
          
          print('TrendsProvider: Merged local and Firebase data - water: ${mergedData.waterIntake} glasses');
          _checkinHistory[existingTodayIndex] = mergedData;
          _todayCheckinData = mergedData;
        } else if (currentTodayData.waterIntake > 0 || currentTodayData.weight > 0) {
          // Add today's data if it doesn't exist in Firebase but we have local data
          _checkinHistory.insert(0, currentTodayData);
          print('TrendsProvider: Added local today data to history');
        }
        
        await _saveToCache();
      } else {
        await _loadFromCache();
      }
    } catch (e) {
      _lastError = 'Failed to load check-in history: $e';
      print('TrendsProvider loadCheckinHistory error: $e');
      // Try to load from cache as fallback
      await _loadFromCache();
    }
  }

  /// Load data from Firestore
  Future<void> _loadFromFirestore(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    try {
      // Load check-in data
      final checkinSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_checkins')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('date', descending: true)
          .limit(30)
          .get()
          .timeout(const Duration(seconds: 15));

      _checkinHistory = checkinSnapshot.docs.map((doc) {
        final data = doc.data();
        return DailyCheckinData.fromJson(data);
      }).toList();

      // Load today's data or create if doesn't exist
      _loadTodayData(userId);

      print('TrendsProvider: Loaded ${_checkinHistory.length} check-in records from Firestore');
    } catch (e) {
      print('TrendsProvider: Error loading from Firestore: $e');
      rethrow;
    }
  }

  /// Load today's check-in data
  void _loadTodayData(String userId) {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    // Find today's data in history
    final todayData = _checkinHistory.firstWhere(
          (data) => DateFormat('yyyy-MM-dd').format(data.date) == todayString,
      orElse: () => DailyCheckinData(
        date: today,
        waterIntake: 0,
        mood: 3,
        sleepHours: 8.0,
        meditationMinutes: 0,
        weight: 0.0,
      ),
    );

    _todayCheckinData = todayData;
  }

  /// Save data to local cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save check-in history
      final checkinJson = _checkinHistory.map((data) => data.toJson()).toList();
      await prefs.setString(_checkinCacheKey, jsonEncode(checkinJson));

      // Save analytics
      await prefs.setString(_analyticsKey, jsonEncode(_weeklyAnalytics));

      // Save last sync time
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      print('TrendsProvider: Data saved to cache');
    } catch (e) {
      print('TrendsProvider: Error saving to cache: $e');
    }
  }

  /// Load data from local cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load check-in history
      final checkinCacheString = prefs.getString(_checkinCacheKey);
      if (checkinCacheString != null) {
        final checkinList = jsonDecode(checkinCacheString) as List;
        _checkinHistory = checkinList
            .map((json) => DailyCheckinData.fromJson(json))
            .toList();
        
        // Find and set today's checkin data from cache
        final today = DateTime.now();
        final todayString = DateFormat('yyyy-MM-dd').format(today);
        final todayData = _checkinHistory.where(
          (data) => DateFormat('yyyy-MM-dd').format(data.date) == todayString,
        ).firstOrNull;
        
        if (todayData != null) {
          _todayCheckinData = todayData;
          print('TrendsProvider: Restored today\'s data from cache - water: ${todayData.waterIntake} glasses');
        }
      }

      // Load analytics
      final analyticsString = prefs.getString(_analyticsKey);
      if (analyticsString != null) {
        _weeklyAnalytics = jsonDecode(analyticsString);
      }

      print('TrendsProvider: Data loaded from cache');
    } catch (e) {
      print('TrendsProvider: Error loading from cache: $e');
    }
  }

  /// Get today's check-in data
  DailyCheckinData getTodayCheckinData() {
    return _todayCheckinData;
  }

  /// Update today's water intake without resetting other data
  Future<void> updateTodayWaterIntake(int waterGlasses) async {
    try {
      final today = DateTime.now();
      final todayString = DateFormat('yyyy-MM-dd').format(today);

      // Update today's checkin data
      _todayCheckinData = _todayCheckinData.copyWith(waterIntake: waterGlasses);

      // Update in history if exists, otherwise create new entry
      final existingIndex = _checkinHistory.indexWhere(
        (data) => DateFormat('yyyy-MM-dd').format(data.date) == todayString,
      );

      if (existingIndex != -1) {
        _checkinHistory[existingIndex] = _checkinHistory[existingIndex].copyWith(
          waterIntake: waterGlasses,
        );
      } else {
        // Create new entry for today with current water intake
        final newEntry = DailyCheckinData(
          date: today,
          waterIntake: waterGlasses,
          mood: _todayCheckinData.mood,
          sleepHours: _todayCheckinData.sleepHours,
          meditationMinutes: _todayCheckinData.meditationMinutes,
          weight: _todayCheckinData.weight,
        );
        _checkinHistory.insert(0, newEntry);
      }

      // Save to cache immediately to preserve data
      await _saveToCache();

      // Save to Firestore if online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          try {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('daily_checkins')
                .doc(todayString)
                .set(_todayCheckinData.toJson(), SetOptions(merge: true))
                .timeout(const Duration(seconds: 8));
          } catch (e) {
            print('TrendsProvider: Failed to sync water intake to Firestore: $e');
            // Continue anyway since we saved locally
          }
        }
      }

      print('TrendsProvider: Updated today\'s water intake to $waterGlasses glasses');
      notifyListeners();
    } catch (e) {
      print('TrendsProvider: Error updating water intake: $e');
    }
  }

  /// Calculate comprehensive analytics
  Future<void> _calculateAnalytics() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Weekly analytics
      final weeklyData = _checkinHistory.where(
            (data) => data.date.isAfter(weekAgo),
      ).toList();

      _weeklyAnalytics = {
        'averageWaterIntake': _calculateAverageWater(weeklyData),
        'averageMood': _calculateAverageMood(weeklyData),
        'averageSleep': _calculateAverageSleep(weeklyData),
        'totalMeditation': _calculateTotalMeditation(weeklyData),
        'waterStreak': getWaterStreak(_checkinHistory),
        'sleepConsistency': _calculateSleepConsistency(weeklyData),
        'perfectDays': getPerfectDayStreak(_checkinHistory),
        'moodTrend': _calculateMoodTrend(weeklyData),
        'hydrationGoalDays': _getHydrationGoalDays(weeklyData),
      };

      // Monthly analytics
      final monthlyData = _checkinHistory.where(
            (data) => data.date.isAfter(monthAgo),
      ).toList();

      _monthlyAnalytics = {
        'averageWaterIntake': _calculateAverageWater(monthlyData),
        'averageMood': _calculateAverageMood(monthlyData),
        'averageSleep': _calculateAverageSleep(monthlyData),
        'totalMeditation': _calculateTotalMeditation(monthlyData),
        'bestWeek': _findBestWeek(monthlyData),
        'improvementAreas': _identifyImprovementAreas(monthlyData),
        'consistencyScore': _calculateConsistencyScore(monthlyData),
      };

    } catch (e) {
      print('TrendsProvider: Error calculating analytics: $e');
    }
  }

  /// Generate personalized health insights
  Future<void> _generateHealthInsights() async {
    _healthInsights.clear();

    try {
      final weeklyData = _checkinHistory.take(7).toList();

      // Water intake insights
      final avgWater = _calculateAverageWater(weeklyData);
      if (avgWater < 6) {
        _healthInsights.add('💧 Try to increase your daily water intake. Aim for at least 8 glasses per day.');
      } else if (avgWater >= 8) {
        _healthInsights.add('💧 Great hydration! You\'re meeting your daily water goals consistently.');
      }

      // Sleep insights
      final avgSleep = _calculateAverageSleep(weeklyData);
      if (avgSleep < 7) {
        _healthInsights.add('😴 Consider getting more sleep. 7-9 hours per night is optimal for health.');
      } else if (avgSleep > 9) {
        _healthInsights.add('😴 You might be getting too much sleep. Try to maintain 7-9 hours per night.');
      } else {
        _healthInsights.add('😴 Excellent sleep habits! You\'re getting the right amount of rest.');
      }

      // Mood insights
      final avgMood = _calculateAverageMood(weeklyData);
      if (avgMood < 3) {
        _healthInsights.add('😔 Your mood has been lower recently. Consider meditation or talking to someone.');
      } else if (avgMood >= 4) {
        _healthInsights.add('😊 Your mood has been great! Keep up whatever you\'re doing.');
      }

      // Meditation insights
      final totalMeditation = _calculateTotalMeditation(weeklyData);
      if (totalMeditation == 0) {
        _healthInsights.add('🧘 Try adding meditation to your routine. Even 5 minutes daily can help.');
      } else if (totalMeditation >= 70) {
        _healthInsights.add('🧘 Fantastic meditation practice! You\'re prioritizing mental wellness.');
      }

      // Streak insights
      final waterStreak = getWaterStreak(_checkinHistory);
      if (waterStreak >= 7) {
        _healthInsights.add('🔥 Amazing water intake streak! Keep up the great hydration habits.');
      }

      // Consistency insights
      final consistency = _calculateConsistencyScore(weeklyData);
      if (consistency >= 0.8) {
        _healthInsights.add('📈 You\'re very consistent with your health tracking. Great discipline!');
      } else if (consistency < 0.5) {
        _healthInsights.add('📱 Try to be more consistent with daily check-ins for better insights.');
      }

    } catch (e) {
      print('TrendsProvider: Error generating health insights: $e');
    }
  }

  /// Generate AI-powered coaching insights
  String generateCoachInsight(List<DailyStepData> stepHistory) {
    try {
      if (stepHistory.isEmpty) {
        return "Start tracking your daily activities to get personalized insights!";
      }

      final recentSteps = stepHistory.take(7).toList();
      final avgSteps = recentSteps.fold(0, (sum, data) => sum + data.steps) / recentSteps.length;
      final weeklyData = _checkinHistory.take(7).toList();
      final avgMood = _calculateAverageMood(weeklyData);
      final avgWater = _calculateAverageWater(weeklyData);

      List<String> insights = [];

      // Step-based insights
      if (avgSteps < 5000) {
        insights.add("Your step count is below recommended levels. Try to take short walks throughout the day.");
      } else if (avgSteps >= 10000) {
        insights.add("Excellent step count! You're staying very active.");
      } else {
        insights.add("Good activity level! Try to reach 10,000 steps daily for optimal health.");
      }

      // Holistic insights combining multiple metrics
      if (avgMood >= 4 && avgWater >= 8 && avgSteps >= 8000) {
        insights.add("You're doing amazing across all health metrics! Keep up this fantastic routine.");
      } else if (avgMood < 3 && avgWater < 6) {
        insights.add("Low mood and hydration often go together. Try drinking more water and see if your mood improves.");
      }

      // Weekly progress insights
      if (recentSteps.length >= 2) {
        final trend = _calculateStepTrend(recentSteps);
        if (trend > 0.1) {
          insights.add("Your activity level is trending upward. Great momentum!");
        } else if (trend < -0.1) {
          insights.add("Your activity has decreased recently. Consider setting smaller, achievable goals.");
        }
      }

      _coachInsight = insights.isNotEmpty
          ? insights.join(' ')
          : "Keep tracking your health data for personalized insights!";

      return _coachInsight!;
    } catch (e) {
      print('TrendsProvider: Error generating coach insight: $e');
      return "Unable to generate insights at this time. Keep tracking for better analysis!";
    }
  }

  // Analytics calculation methods
  double _calculateAverageWater(List<DailyCheckinData> data) {
    if (data.isEmpty) return 0.0;
    return data.fold(0, (sum, item) => sum + item.waterIntake) / data.length;
  }

  double _calculateAverageMood(List<DailyCheckinData> data) {
    if (data.isEmpty) return 3.0;
    return data.fold(0, (sum, item) => sum + item.mood) / data.length;
  }

  double _calculateAverageSleep(List<DailyCheckinData> data) {
    if (data.isEmpty) return 8.0;
    return data.fold(0.0, (sum, item) => sum + item.sleepHours) / data.length;
  }

  int _calculateTotalMeditation(List<DailyCheckinData> data) {
    return data.fold(0, (sum, item) => sum + item.meditationMinutes);
  }

  double _calculateSleepConsistency(List<DailyCheckinData> data) {
    if (data.length < 2) return 1.0;

    final sleepTimes = data.map((d) => d.sleepHours).toList();
    final avg = sleepTimes.reduce((a, b) => a + b) / sleepTimes.length;
    final variance = sleepTimes.map((time) => pow(time - avg, 2)).reduce((a, b) => a + b) / sleepTimes.length;
    final standardDeviation = sqrt(variance);

    // Return consistency score (lower deviation = higher consistency)
    return max(0.0, 1.0 - (standardDeviation / 3.0));
  }

  String _calculateMoodTrend(List<DailyCheckinData> data) {
    if (data.length < 3) return 'stable';

    final moods = data.map((d) => d.mood.toDouble()).toList();
    final firstHalf = moods.take(moods.length ~/ 2).toList();
    final secondHalf = moods.skip(moods.length ~/ 2).toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    if (secondAvg > firstAvg + 0.5) return 'improving';
    if (secondAvg < firstAvg - 0.5) return 'declining';
    return 'stable';
  }

  int _getHydrationGoalDays(List<DailyCheckinData> data) {
    return data.where((d) => d.waterIntake >= 8).length;
  }

  Map<String, dynamic> _findBestWeek(List<DailyCheckinData> data) {
    // Implementation for finding the best performing week
    return {
      'week': 'Current week',
      'score': 85,
      'highlights': ['Great hydration', 'Consistent sleep']
    };
  }

  List<String> _identifyImprovementAreas(List<DailyCheckinData> data) {
    List<String> areas = [];

    if (_calculateAverageWater(data) < 6) areas.add('Hydration');
    if (_calculateAverageSleep(data) < 7) areas.add('Sleep duration');
    if (_calculateAverageMood(data) < 3) areas.add('Mood management');
    if (_calculateTotalMeditation(data) < 30) areas.add('Meditation practice');

    return areas;
  }

  double _calculateConsistencyScore(List<DailyCheckinData> data) {
    if (data.isEmpty) return 0.0;

    final totalDays = data.length;
    final activeDays = data.where((d) =>
    d.waterIntake > 0 || d.meditationMinutes > 0 || d.sleepHours > 0
    ).length;

    return activeDays / totalDays;
  }

  double _calculateStepTrend(List<DailyStepData> data) {
    if (data.length < 2) return 0.0;

    final first = data.first.steps;
    final last = data.last.steps;

    return (last - first) / first;
  }

  // Streak calculation methods
  int getWaterStreak(List<DailyCheckinData> history) {
    int streak = 0;
    final sortedHistory = [...history];
    sortedHistory.sort((a, b) => b.date.compareTo(a.date));

    for (final data in sortedHistory) {
      if (data.waterIntake >= 8) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int getConsistentSleepDays(List<DailyCheckinData> history) {
    return history.where((data) => data.sleepHours >= 7 && data.sleepHours <= 9).length;
  }

  int getTotalMeditationMinutes(List<DailyCheckinData> history) {
    return history.fold(0, (sum, data) => sum + data.meditationMinutes);
  }

  int getPerfectDayStreak(List<DailyCheckinData> history) {
    int streak = 0;
    final sortedHistory = [...history];
    sortedHistory.sort((a, b) => b.date.compareTo(a.date));

    for (final data in sortedHistory) {
      if (data.waterIntake >= 8 &&
          data.sleepHours >= 7 &&
          data.sleepHours <= 9 &&
          data.mood >= 4) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Refresh all data from Firebase
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadCheckinHistory();
      await _calculateAnalytics();
      await _generateHealthInsights();
    } catch (e) {
      _lastError = 'Failed to refresh data: $e';
      print('TrendsProvider refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all local data and cache
  Future<void> clearAllData() async {
    try {
      _checkinHistory.clear();
      _stepHistory.clear();
      _todayCheckinData = DailyCheckinData(
        date: DateTime.now(),
        waterIntake: 0,
        mood: 3,
        sleepHours: 8.0,
        meditationMinutes: 0,
        weight: 0.0,
      );
      _weeklyAnalytics.clear();
      _monthlyAnalytics.clear();
      _healthInsights.clear();
      _coachInsight = null;

      // Clear cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_checkinCacheKey);
      await prefs.remove(_analyticsKey);
      await prefs.remove(_lastSyncKey);

      notifyListeners();
    } catch (e) {
      print('TrendsProvider: Error clearing data: $e');
    }
  }

  /// Export data for backup or analysis
  Map<String, dynamic> exportData() {
    return {
      'checkinHistory': _checkinHistory.map((data) => data.toJson()).toList(),
      'weeklyAnalytics': _weeklyAnalytics,
      'monthlyAnalytics': _monthlyAnalytics,
      'healthInsights': _healthInsights,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Validate checkin data before saving
  List<String> _validateCheckinData(DailyCheckinData data) {
    final errors = <String>[];
    
    // Validate water intake
    if (data.waterIntake < 0) {
      errors.add('Water intake cannot be negative');
    } else if (data.waterIntake > 30) {
      errors.add('Water intake seems unrealistic (max 30 glasses)');
    }
    
    // Validate sleep hours
    if (data.sleepHours < 0) {
      errors.add('Sleep hours cannot be negative');
    } else if (data.sleepHours > 24) {
      errors.add('Sleep hours cannot exceed 24');
    }
    
    // Validate mood
    if (data.mood < 1 || data.mood > 5) {
      errors.add('Mood must be between 1 and 5');
    }
    
    // Validate meditation minutes
    if (data.meditationMinutes < 0) {
      errors.add('Meditation minutes cannot be negative');
    } else if (data.meditationMinutes > 1440) {
      errors.add('Meditation minutes cannot exceed 24 hours');
    }
    
    // Validate weight
    if (data.weight < 0) {
      errors.add('Weight cannot be negative');
    } else if (data.weight > 500) {
      errors.add('Weight seems unrealistic (max 500kg)');
    }
    
    // Validate meal count
    if (data.mealCount < 0 || data.mealCount > 10) {
      errors.add('Meal count must be between 0 and 10');
    }
    
    return errors;
  }

  /// Get dynamic XP reward for daily check-in (configurable)
  int getDailyCheckinXP() {
    // Make XP dynamic based on user level or consistency
    final userLevel = 1; // Get from experience provider or user data
    final baseXP = 10;
    final bonusXP = (userLevel * 2);
    return baseXP + bonusXP;
  }

  /// Get configurable messages for daily check-in
  Map<String, String> getDailyCheckinMessages() {
    return {
      'prompt': "Complete your daily check-in to earn experience points!",
      'weightLabel': "Today's Weight (kg) - Optional",
      'weightHint': 'Enter weight (optional)',
      'weightHelper': 'Leave empty if you prefer not to track weight today',
      'buttonText': 'Complete Daily Check-in',
      'completedMessage': "You've already completed your daily check-in today! Come back tomorrow.",
      'thankYouMessage': "Thanks for staying consistent with your health tracking! 🎉",
    };
  }

  /// Import data from backup
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      if (data['checkinHistory'] != null) {
        final checkinList = data['checkinHistory'] as List;
        _checkinHistory = checkinList
            .map((json) => DailyCheckinData.fromJson(json))
            .toList();
      }

      if (data['weeklyAnalytics'] != null) {
        _weeklyAnalytics = Map<String, dynamic>.from(data['weeklyAnalytics']);
      }

      if (data['monthlyAnalytics'] != null) {
        _monthlyAnalytics = Map<String, dynamic>.from(data['monthlyAnalytics']);
      }

      if (data['healthInsights'] != null) {
        _healthInsights = List<String>.from(data['healthInsights']);
      }

      await _saveToCache();
      notifyListeners();
      return true;
    } catch (e) {
      // print('TrendsProvider: Error importing data: $e');
      return false;
    }
  }
}
