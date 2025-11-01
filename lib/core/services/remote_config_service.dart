// lib/core/services/remote_config_service.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing remote configuration values
/// Allows dynamic adjustment of game parameters without app updates
class RemoteConfigService {
  // Singleton pattern
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for config values
  final Map<String, dynamic> _configCache = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(hours: 1);
  
  // Default XP values (fallback if remote config fails)
  static const Map<String, int> defaultXpValues = {
    'step_goal_complete': 75,
    'water_goal_complete': 75,
    'water_milestone_9': 75,
    'daily_checkin': 75,
    'meditation': 0,
    'sleep_goal': 0,
    'weight_log': 0,
    'mood_log': 0,
    'custom_activity': 0,
    'streak_bonus': 0,
  };
  
  // Default health multipliers
  static const Map<String, double> defaultHealthMultipliers = {
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
  
  /// Initialize and fetch remote config
  Future<void> initialize() async {
    try {
      await fetchConfig();
      debugPrint('RemoteConfigService: Initialized successfully');
    } catch (e) {
      debugPrint('RemoteConfigService: Initialization failed, using defaults: $e');
    }
  }
  
  /// Fetch configuration from Firestore
  Future<void> fetchConfig() async {
    try {
      // Check if cache is still valid
      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint('RemoteConfigService: Using cached config');
        return;
      }
      
      // Fetch from Firestore
      final doc = await _firestore
          .collection('app_config')
          .doc('game_parameters')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (doc.exists && doc.data() != null) {
        _configCache.clear();
        _configCache.addAll(doc.data()!);
        _lastFetchTime = DateTime.now();
        debugPrint('RemoteConfigService: Fetched ${_configCache.length} config values');
      } else {
        debugPrint('RemoteConfigService: No remote config found, using defaults');
      }
    } catch (e) {
      debugPrint('RemoteConfigService: Error fetching config: $e');
      // Continue with cached or default values
    }
  }
  
  /// Get XP value for activity type
  int getXpValue(String activityType) {
    try {
      // Try to get from cache first
      if (_configCache.containsKey('xp_values')) {
        final xpValues = _configCache['xp_values'] as Map<String, dynamic>?;
        if (xpValues != null && xpValues.containsKey(activityType)) {
          return (xpValues[activityType] as num).toInt();
        }
      }
      
      // Fallback to default
      return defaultXpValues[activityType] ?? 10;
    } catch (e) {
      debugPrint('RemoteConfigService: Error getting XP value for $activityType: $e');
      return defaultXpValues[activityType] ?? 10;
    }
  }
  
  /// Get all XP values
  Map<String, int> getAllXpValues() {
    try {
      if (_configCache.containsKey('xp_values')) {
        final xpValues = _configCache['xp_values'] as Map<String, dynamic>?;
        if (xpValues != null) {
          return xpValues.map((key, value) => MapEntry(key, (value as num).toInt()));
        }
      }
      
      return Map.from(defaultXpValues);
    } catch (e) {
      debugPrint('RemoteConfigService: Error getting all XP values: $e');
      return Map.from(defaultXpValues);
    }
  }
  
  /// Get health condition multiplier
  double getHealthMultiplier(String condition) {
    try {
      if (_configCache.containsKey('health_multipliers')) {
        final multipliers = _configCache['health_multipliers'] as Map<String, dynamic>?;
        if (multipliers != null && multipliers.containsKey(condition)) {
          return (multipliers[condition] as num).toDouble();
        }
      }
      
      return defaultHealthMultipliers[condition] ?? 1.0;
    } catch (e) {
      debugPrint('RemoteConfigService: Error getting health multiplier for $condition: $e');
      return defaultHealthMultipliers[condition] ?? 1.0;
    }
  }
  
  /// Get all health multipliers
  Map<String, double> getAllHealthMultipliers() {
    try {
      if (_configCache.containsKey('health_multipliers')) {
        final multipliers = _configCache['health_multipliers'] as Map<String, dynamic>?;
        if (multipliers != null) {
          return multipliers.map((key, value) => MapEntry(key, (value as num).toDouble()));
        }
      }
      
      return Map.from(defaultHealthMultipliers);
    } catch (e) {
      debugPrint('RemoteConfigService: Error getting all health multipliers: $e');
      return Map.from(defaultHealthMultipliers);
    }
  }
  
  /// Get generic config value
  T? getValue<T>(String key, {T? defaultValue}) {
    try {
      if (_configCache.containsKey(key)) {
        return _configCache[key] as T?;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('RemoteConfigService: Error getting value for $key: $e');
      return defaultValue;
    }
  }
  
  /// Force refresh config (bypass cache)
  Future<void> forceRefresh() async {
    _lastFetchTime = null;
    await fetchConfig();
  }
  
  /// Clear cache
  void clearCache() {
    _configCache.clear();
    _lastFetchTime = null;
    debugPrint('RemoteConfigService: Cache cleared');
  }
  
  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'cached_values': _configCache.length,
      'last_fetch': _lastFetchTime?.toIso8601String(),
      'cache_valid': _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration,
    };
  }
}
