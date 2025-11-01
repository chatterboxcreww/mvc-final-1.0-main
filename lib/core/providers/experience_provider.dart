import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_data.dart';
import '../providers/achievement_provider.dart';
import '../providers/user_data_provider.dart';
import '../services/daily_sync_service.dart';
import '../services/remote_config_service.dart';

class ExperienceProvider with ChangeNotifier {
  int _xp = 0;
  int _level = 1;
  int _totalXpEarned = 0;

  // XP Notification System
  String? _lastXpGainMessage;
  DateTime? _lastXpGainTime;

  // Level-up Notification System
  int? _newlyAchievedLevel;
  DateTime? _levelUpTime;

  // Provider references
  AchievementProvider? _achievementProvider;
  UserDataProvider? _userDataProvider;
  final DailySyncService _dailySyncService = DailySyncService();
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  // Daily milestone tracking to prevent duplicate XP awards with timestamps
  final Map<String, DateTime> _dailyMilestonesAwarded = <String, DateTime>{};

  // Maximum level cap to prevent overflow and maintain game balance
  static const int maxLevel = 100;
  
  // XP multipliers based on health conditions
  static const Map<String, double> _healthConditionMultipliers = {
    'diabetes': 1.5,
    'skinny_fat': 1.4,
    'protein_deficiency': 1.3,
    'vitamin_d_deficiency': 1.2,
    'iron_deficiency': 1.3,
    'hypertension': 1.3,
    'cholesterol': 1.2,
    'obesity': 1.4,
    'metabolic_syndrome': 1.5,
    'insulin_resistance': 1.4,
    'default': 1.0,
  };

  // XP values for different activities - Issue #7 requirements
  static const Map<String, int> _baseXpValues = {
    'step_goal_complete': 75,      // When user completes daily step goal
    'water_goal_complete': 75,     // When user completes daily water goal
    'water_milestone_9': 75,       // When user reaches 9 glasses milestone
    'daily_checkin': 75,           // When user checks in everyday
    'water_glass': 0,              // No XP for individual glasses, only goal completion
    'meditation': 0,               // Removed XP for other activities per requirements
    'sleep_goal': 0,               // Removed XP for other activities per requirements
    'weight_log': 0,               // Removed XP for other activities per requirements
    'mood_log': 0,                 // Removed XP for other activities per requirements
    'custom_activity': 0,          // Removed XP for other activities per requirements
    'streak_bonus': 0,             // Removed XP for other activities per requirements
  };

  // Getters
  int get xp => _xp;
  int get level => _level;
  int get totalXpEarned => _totalXpEarned;

  // Calculate XP needed for next level (exponential progression)
  int get xpForNextLevel => _calculateXpForLevel(_level + 1);

  // Calculate XP progress for current level
  double get levelProgress {
    final currentLevelXp = _calculateXpForLevel(_level);
    final nextLevelXp = _calculateXpForLevel(_level + 1);
    final progressXp = _xp - currentLevelXp;
    final requiredXp = nextLevelXp - currentLevelXp;
    return requiredXp > 0 ? (progressXp / requiredXp).clamp(0.0, 1.0) : 0.0;
  }

  // XP notification getters
  String? get lastXpGainMessage => _lastXpGainMessage;
  DateTime? get lastXpGainTime => _lastXpGainTime;
  
  // Check if there's a recent XP notification to show
  bool get hasRecentXpGain {
    if (_lastXpGainTime == null) return false;
    final timeDiff = DateTime.now().difference(_lastXpGainTime!);
    return timeDiff.inSeconds < 3; // Show for 3 seconds
  }

  // Clear XP notification
  void clearXpNotification() {
    _lastXpGainMessage = null;
    _lastXpGainTime = null;
    notifyListeners();
  }

  // Level-up notification getters
  int? get newlyAchievedLevel => _newlyAchievedLevel;
  DateTime? get levelUpTime => _levelUpTime;
  
  // Check if there's a recent level-up to show
  bool get hasNewLevelUp {
    if (_levelUpTime == null || _newlyAchievedLevel == null) return false;
    final timeDiff = DateTime.now().difference(_levelUpTime!);
    return timeDiff.inSeconds < 5; // Show for 5 seconds
  }

  // Clear level-up notification
  void clearLevelUpNotification() {
    _newlyAchievedLevel = null;
    _levelUpTime = null;
    notifyListeners();
  }

  /// Set provider references for cross-provider communication
  void setAchievementProvider(AchievementProvider provider) {
    _achievementProvider = provider;
  }

  void setUserDataProvider(UserDataProvider provider) {
    _userDataProvider = provider;
  }

  /// Calculate total XP needed for a specific level (exponential progression)
  int _calculateXpForLevel(int level) {
    if (level <= 1) return 0;

    // Exponential formula: Each level requires exponentially more XP
    // Level 2 = 100, Level 3 = 300, Level 4 = 700, Level 5 = 1500, etc.
    int totalXp = 0;
    for (int i = 2; i <= level; i++) {
      // Each level requires base amount * (level^1.8) for exponential growth
      final levelRequirement = (100 * (i * i * 0.8)).round();
      totalXp += levelRequirement;
    }
    return totalXp;
  }

  /// Calculate level from total XP with max level cap
  int _calculateLevelFromXp(int totalXp) {
    int level = 1;
    while (level < maxLevel && _calculateXpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level.clamp(1, maxLevel);
  }

  /// Check and clear daily milestones if it's a new day
  void _checkAndClearDailyMilestones() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Remove any milestones that are not from today (using timestamp comparison)
    _dailyMilestonesAwarded.removeWhere((milestone, timestamp) {
      final milestoneDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
      return milestoneDate.isBefore(today);
    });
  }

  /// Initialize experience data from local storage
  Future<void> initializeFromUserData(UserData userData) async {
    // First try to load from local storage
    await _loadExperienceData();
    
    // Clear daily milestones if it's a new day
    _checkAndClearDailyMilestones();
    
    // If no local data, fall back to UserData
    if (_xp == 0 && _level == 1) {
      _level = userData.level;

      // Calculate XP from level (approximate)
      if (_level > 1) {
        _xp = _calculateXpForLevel(_level);
        _totalXpEarned = _xp;
      } else {
        _xp = 0;
        _totalXpEarned = 0;
      }
    }

    notifyListeners();
  }

  /// Load experience data from Firebase (for wake-up sync)
  Future<void> loadExperienceDataFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('experience')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _xp = data['xp'] ?? 0;
        _level = data['level'] ?? 1;
        _totalXpEarned = data['totalXpEarned'] ?? _xp;
      }

      notifyListeners();
    } catch (e) {
      print('ExperienceProvider: Error loading experience data: $e');
    }
  }

  /// Save experience data to local storage (daily sync approach)
  Future<void> _saveExperienceData() async {
    try {
      final experienceData = {
        'xp': _xp,
        'level': _level,
        'totalXpEarned': _totalXpEarned,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await _dailySyncService.saveLocalExperienceData(experienceData);
      debugPrint('ExperienceProvider: Experience data saved to local storage');
    } catch (e) {
      debugPrint('ExperienceProvider: Error saving experience data to local storage: $e');
    }
  }

  /// Load experience data from local storage
  Future<void> _loadExperienceData() async {
    try {
      final experienceData = await _dailySyncService.getLocalExperienceData();
      if (experienceData.isNotEmpty) {
        _xp = experienceData['xp'] ?? 0;
        _level = experienceData['level'] ?? 1;
        _totalXpEarned = experienceData['totalXpEarned'] ?? _xp;
        debugPrint('ExperienceProvider: Experience data loaded from local storage');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ExperienceProvider: Error loading experience data from local storage: $e');
    }
  }

  /// Keep Firebase methods for sleep time sync
  Future<void> saveExperienceDataToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('experience')
          .doc('current')
          .set({
        'xp': _xp,
        'level': _level,
        'totalXpEarned': _totalXpEarned,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update the main user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'level': _level,
        'totalXp': _totalXpEarned,
      });
    } catch (e) {
      print('ExperienceProvider: Error saving experience data: $e');
    }
  }

  /// Add XP with health condition multipliers and max level cap
  Future<void> addXp(String activityType, UserData userData, {int? customAmount}) async {
    // Don't add XP if already at max level
    if (_level >= maxLevel) {
      print('ExperienceProvider: Already at max level ($maxLevel), no XP added');
      return;
    }
    
    // Get XP value from remote config (with fallback to defaults)
    final baseXp = customAmount ?? _remoteConfig.getXpValue(activityType);
    final multiplier = _getHealthMultiplier(userData);
    final finalXp = (baseXp * multiplier).round();

    _xp += finalXp;
    _totalXpEarned += finalXp;

    // Create XP gain notification
    _lastXpGainMessage = "You gained exp";
    _lastXpGainTime = DateTime.now();

    // Check for level up
    final newLevel = _calculateLevelFromXp(_xp);
    if (newLevel > _level && newLevel <= maxLevel) {
      await _handleLevelUp(newLevel, userData);
    }

    // Save to Firebase
    await _saveExperienceData();

    notifyListeners();

    // print('ExperienceProvider: Added $finalXp XP for $activityType (base: $baseXp, multiplier: ${multiplier.toStringAsFixed(1)})');
  }

  /// Acknowledge that the level-up animation has been shown
  void acknowledgeLevelUp() {
    // Level up acknowledged - no longer needed since field was removed
    notifyListeners();
  }

  /// Get health condition multiplier from remote config
  double _getHealthMultiplier(UserData userData) {
    // Check for health conditions that increase XP multiplier (using remote config)
    if (userData.hasDiabetes == true) {
      return _remoteConfig.getHealthMultiplier('diabetes');
    } else if (userData.isSkinnyFat == true) {
      return _remoteConfig.getHealthMultiplier('skinny_fat');
    } else if (userData.hasProteinDeficiency == true) {
      return _remoteConfig.getHealthMultiplier('protein_deficiency');
    }

    return _remoteConfig.getHealthMultiplier('default');
  }

  /// Handle level up event
  Future<void> _handleLevelUp(int newLevel, UserData userData) async {
    final previousLevel = _level;
    _level = newLevel;

    // Set level-up notification
    _newlyAchievedLevel = newLevel;
    _levelUpTime = DateTime.now();

    print('ExperienceProvider: Level up! $previousLevel → $newLevel');

    // Trigger level achievements
    if (_achievementProvider != null) {
      _achievementProvider!.checkLevelAchievements(_level);
    }

    // Update user data with new level
    if (_userDataProvider != null) {
      final updatedUserData = userData.copyWith(level: _level);
      await _userDataProvider!.updateUserData(updatedUserData);
    }

    // Show level up notification (handled by UI layer)
  }

  /// Specialized XP methods for different activities

  /// Add XP for water intake with timestamp-based duplicate prevention
  Future<void> addXpForWater(int glassCount, UserData userData) async {
    try {
      print('ExperienceProvider: Checking water milestones - glasses: $glassCount, user goal: ${userData.dailyWaterGoal ?? 8}');
      
      final now = DateTime.now();
      final userGoal = userData.dailyWaterGoal ?? 8;
      
      // Award XP when user reaches their personal goal (only once per day)
      if (glassCount >= userGoal) {
        final goalKey = 'water_goal_complete';
        final lastAwarded = _dailyMilestonesAwarded[goalKey];
        
        // Check if not awarded today
        if (lastAwarded == null || !_isSameDay(lastAwarded, now)) {
          print('ExperienceProvider: Personal water goal ($userGoal glasses) reached - awarding XP');
          _dailyMilestonesAwarded[goalKey] = now;
          await addXp('water_goal_complete', userData);
        } else {
          print('ExperienceProvider: Personal water goal already awarded today');
        }
      }
      // Award XP at 9 glasses milestone only if it's not the user's goal (only once per day)
      if (glassCount >= 9 && userGoal != 9) {
        final milestoneKey = 'water_milestone_9';
        final lastAwarded = _dailyMilestonesAwarded[milestoneKey];
        
        // Check if not awarded today
        if (lastAwarded == null || !_isSameDay(lastAwarded, now)) {
          print('ExperienceProvider: 9 glasses milestone reached - awarding XP');
          _dailyMilestonesAwarded[milestoneKey] = now;
          await addXp('water_milestone_9', userData);
        } else {
          print('ExperienceProvider: 9 glasses milestone already awarded today');
        }
      }
    } catch (e) {
      print('ExperienceProvider: Error adding water XP: $e');
    }
  }
  
  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Add XP for step goals
  Future<void> addXpForSteps(int steps, int goal, UserData userData) async {
    // Only award XP for completing daily step goal
    if (steps >= goal) {
      await addXp('step_goal_complete', userData);
    }
  }

  /// Add XP for daily check-in
  Future<void> addXpForDailyCheckin(UserData userData) async {
    await addXp('daily_checkin', userData);
  }

  /// Legacy methods - these now return without awarding XP
  /// Keeping for backward compatibility

  Future<void> addXpForMeditation(int minutes, UserData userData) async {
    // No longer awards XP - legacy method for compatibility
    return;
  }

  Future<void> addXpForSleep(double hours, UserData userData) async {
    // No longer awards XP - legacy method for compatibility
    return;
  }

  Future<void> addXpForWeightLog(UserData userData) async {
    // No longer awards XP - legacy method for compatibility
    return;
  }

  Future<void> addXpForMoodLog(UserData userData) async {
    // No longer awards XP - legacy method for compatibility
    return;
  }

  Future<void> addXpForCustomActivity(UserData userData) async {
    // No longer awards XP - legacy method for compatibility
    return;
  }

  Future<void> addXpForStreak(int streakDays, UserData userData) async {
    // No longer awards XP - legacy method for compatibility
    return;
  }

  Future<void> processGains(UserData userData) async {
    // No longer awards XP - legacy method for compatibility
    return;
  }

  /// Check and update level achievements
  void checkLevelAchievements() {
    if (_achievementProvider != null) {
      _achievementProvider!.checkLevelAchievements(_level);
    }
  }

  /// Get XP breakdown for display
  Map<String, dynamic> getXpBreakdown() {
    return {
      'currentXp': _xp,
      'currentLevel': _level,
      'nextLevelXp': xpForNextLevel,
      'xpForCurrentLevel': _calculateXpForLevel(_level),
      'xpToNextLevel': xpForNextLevel - _xp,
      'totalXpEarned': _totalXpEarned,
      'levelProgress': levelProgress,
    };
  }

  /// Get level benefits/rewards
  List<String> getLevelBenefits(int level) {
    final benefits = <String>[];

    if (level >= 5) benefits.add('Unlock custom themes');
    if (level >= 10) benefits.add('Advanced analytics');
    if (level >= 15) benefits.add('Personal coach insights');
    if (level >= 20) benefits.add('Community features');
    if (level >= 25) benefits.add('Export health data');
    if (level >= 30) benefits.add('Premium achievements');

    return benefits;
  }

  /// Reset experience data
  Future<void> resetExperience() async {
    _xp = 0;
    _level = 1;
    _totalXpEarned = 0;

    await _saveExperienceData();
    notifyListeners();
  }

  /// Get daily XP summary
  Future<Map<String, int>> getDailyXpSummary() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('xp_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final summary = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final activity = data['activity'] as String;
        final xp = data['xp'] as int;
        summary[activity] = (summary[activity] ?? 0) + xp;
      }

      return summary;
    } catch (e) {
      print('ExperienceProvider: Error getting daily XP summary: $e');
      return {};
    }
  }
}
