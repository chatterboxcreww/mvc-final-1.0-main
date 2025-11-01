// lib/core/providers/water_tracking_provider.dart

import 'package:flutter/material.dart';
import '../services/daily_sync_service.dart';

/// Centralized water tracking provider - single source of truth
class WaterTrackingProvider with ChangeNotifier {
  final DailySyncService _dailySyncService = DailySyncService();
  
  int _waterCount = 0;
  bool _isLoading = false;
  DateTime? _lastUpdate;
  
  // Getters
  int get waterCount => _waterCount;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;
  
  /// Initialize and load water count from storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _waterCount = await _dailySyncService.getWaterGlassCount();
      _lastUpdate = DateTime.now();
      debugPrint('WaterTrackingProvider: Initialized with $_waterCount glasses');
    } catch (e) {
      debugPrint('WaterTrackingProvider: Error initializing: $e');
      _waterCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Increment water count
  Future<int> incrementWater() async {
    try {
      _waterCount = await _dailySyncService.incrementWaterGlassCount();
      _lastUpdate = DateTime.now();
      debugPrint('WaterTrackingProvider: Incremented to $_waterCount glasses');
      notifyListeners();
      return _waterCount;
    } catch (e) {
      debugPrint('WaterTrackingProvider: Error incrementing: $e');
      rethrow;
    }
  }
  
  /// Decrement water count
  Future<int> decrementWater() async {
    if (_waterCount <= 0) {
      debugPrint('WaterTrackingProvider: Cannot decrement below 0');
      return _waterCount;
    }
    
    try {
      _waterCount = await _dailySyncService.decrementWaterGlassCount();
      _lastUpdate = DateTime.now();
      debugPrint('WaterTrackingProvider: Decremented to $_waterCount glasses');
      notifyListeners();
      return _waterCount;
    } catch (e) {
      debugPrint('WaterTrackingProvider: Error decrementing: $e');
      rethrow;
    }
  }
  
  /// Set water count directly (for sync purposes)
  Future<void> setWaterCount(int count) async {
    if (count < 0) {
      debugPrint('WaterTrackingProvider: Cannot set negative water count');
      return;
    }
    
    try {
      // Save to storage
      await _dailySyncService.saveWaterGlassCount(count);
      _waterCount = count;
      _lastUpdate = DateTime.now();
      debugPrint('WaterTrackingProvider: Set to $count glasses');
      notifyListeners();
    } catch (e) {
      debugPrint('WaterTrackingProvider: Error setting water count: $e');
      rethrow;
    }
  }
  
  /// Reset water count (for new day)
  Future<void> resetWaterCount() async {
    await setWaterCount(0);
    debugPrint('WaterTrackingProvider: Reset water count for new day');
  }
  
  /// Get progress towards goal
  double getProgress(int goal) {
    if (goal <= 0) return 0.0;
    return (_waterCount / goal).clamp(0.0, 1.0);
  }
  
  /// Check if goal is reached
  bool isGoalReached(int goal) {
    return _waterCount >= goal;
  }
}
