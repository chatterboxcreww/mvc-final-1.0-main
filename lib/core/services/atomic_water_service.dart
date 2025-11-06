// lib/core/services/atomic_water_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Atomic water tracking service to prevent race conditions
class AtomicWaterService {
  static final AtomicWaterService _instance = AtomicWaterService._internal();
  factory AtomicWaterService() => _instance;
  AtomicWaterService._internal();

  final Completer<void> _initCompleter = Completer<void>();
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  // Mutex-like mechanism using Completer
  Completer<void>? _operationCompleter;
  
  static const String _waterCountKey = 'atomic_water_count';
  static const String _lastResetDateKey = 'atomic_water_reset_date';
  static const String _waterHistoryKey = 'atomic_water_history';

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _checkDailyReset();
    _isInitialized = true;
    
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  /// Ensure initialization before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
    await _initCompleter.future;
  }

  /// Check if it's a new day and reset water count
  Future<void> _checkDailyReset() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastResetDate = _prefs?.getString(_lastResetDateKey);
    
    if (lastResetDate != today) {
      // Save yesterday's count to history before reset
      final currentCount = _prefs?.getInt(_waterCountKey) ?? 0;
      if (currentCount > 0 && lastResetDate != null) {
        await _saveToHistory(lastResetDate, currentCount);
      }
      
      // Reset for new day
      await _prefs?.setInt(_waterCountKey, 0);
      await _prefs?.setString(_lastResetDateKey, today);
      debugPrint('AtomicWaterService: Reset water count for new day: $today');
    }
  }

  /// Save water count to history
  Future<void> _saveToHistory(String date, int count) async {
    try {
      final historyJson = _prefs?.getString(_waterHistoryKey) ?? '{}';
      final history = Map<String, dynamic>.from(
        (historyJson.isNotEmpty) ? 
        Map<String, dynamic>.from(Uri.decodeComponent(historyJson).split('&').fold<Map<String, String>>({}, (map, pair) {
          final parts = pair.split('=');
          if (parts.length == 2) map[parts[0]] = parts[1];
          return map;
        })) : {}
      );
      
      history[date] = count;
      
      // Keep only last 30 days
      final sortedDates = history.keys.toList()..sort();
      if (sortedDates.length > 30) {
        for (int i = 0; i < sortedDates.length - 30; i++) {
          history.remove(sortedDates[i]);
        }
      }
      
      await _prefs?.setString(_waterHistoryKey, Uri.encodeComponent(
        history.entries.map((e) => '${e.key}=${e.value}').join('&')
      ));
    } catch (e) {
      debugPrint('AtomicWaterService: Error saving to history: $e');
    }
  }

  /// Atomic water count update with mutex protection
  Future<int> updateWaterCount(int change) async {
    await _ensureInitialized();
    
    // Wait for any ongoing operation to complete with timeout
    int waitCount = 0;
    const maxWait = 50; // 5 seconds max
    
    while (_operationCompleter != null && 
           !_operationCompleter!.isCompleted && 
           waitCount < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }
    
    if (_operationCompleter != null && !_operationCompleter!.isCompleted) {
      print('AtomicWaterService: ⚠️ Operation timeout - forcing completion');
      _operationCompleter!.completeError(TimeoutException('Water operation timed out'));
      _operationCompleter = null;
    }
    
    // Start new operation
    _operationCompleter = Completer<void>();
    
    try {
      // Check for daily reset before operation
      await _checkDailyReset();
      
      // Get current count
      final currentCount = _prefs?.getInt(_waterCountKey) ?? 0;
      
      // Calculate new count with bounds checking
      final newCount = (currentCount + change).clamp(0, 25); // Max 25 glasses per day
      
      // Validate the change
      if (change > 0 && newCount > currentCount + 1) {
        // Prevent adding more than 1 glass at a time
        throw Exception('Cannot add more than 1 glass at a time');
      }
      
      if (change < 0 && newCount < currentCount - 1) {
        // Prevent removing more than 1 glass at a time
        throw Exception('Cannot remove more than 1 glass at a time');
      }
      
      // Persist the new count atomically
      await _prefs?.setInt(_waterCountKey, newCount);
      
      debugPrint('AtomicWaterService: Water count updated from $currentCount to $newCount');
      
      // Complete the operation
      _operationCompleter?.complete();
      return newCount;
      
    } catch (e) {
      debugPrint('AtomicWaterService: Error updating water count: $e');
      _operationCompleter?.completeError(e);
      rethrow;
    }
  }

  /// Get current water count
  Future<int> getCurrentCount() async {
    await _ensureInitialized();
    await _checkDailyReset();
    return _prefs?.getInt(_waterCountKey) ?? 0;
  }

  /// Set water count to specific value (for initialization)
  Future<void> setWaterCount(int count) async {
    await _ensureInitialized();
    
    // Wait for any ongoing operation with timeout
    int waitCount = 0;
    const maxWait = 50; // 5 seconds max
    
    while (_operationCompleter != null && 
           !_operationCompleter!.isCompleted && 
           waitCount < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }
    
    if (_operationCompleter != null && !_operationCompleter!.isCompleted) {
      print('AtomicWaterService: ⚠️ Set count timeout - forcing completion');
      _operationCompleter!.completeError(TimeoutException('Set water count timed out'));
      _operationCompleter = null;
    }
    
    _operationCompleter = Completer<void>();
    
    try {
      final clampedCount = count.clamp(0, 25);
      await _prefs?.setInt(_waterCountKey, clampedCount);
      _operationCompleter?.complete();
      debugPrint('AtomicWaterService: Water count set to $clampedCount');
    } catch (e) {
      _operationCompleter?.completeError(e);
      rethrow;
    }
  }

  /// Get water history for analytics
  Future<Map<String, int>> getWaterHistory({int days = 7}) async {
    await _ensureInitialized();
    
    try {
      final historyJson = _prefs?.getString(_waterHistoryKey) ?? '';
      if (historyJson.isEmpty) return {};
      
      final decodedHistory = Uri.decodeComponent(historyJson);
      final history = <String, int>{};
      
      for (final pair in decodedHistory.split('&')) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          history[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
      
      // Return only requested number of days
      final sortedDates = history.keys.toList()..sort();
      final recentDates = sortedDates.length > days 
          ? sortedDates.sublist(sortedDates.length - days)
          : sortedDates;
      
      return Map.fromEntries(
        recentDates.map((date) => MapEntry(date, history[date]!))
      );
    } catch (e) {
      debugPrint('AtomicWaterService: Error getting water history: $e');
      return {};
    }
  }

  /// Check if water milestone reached today
  Future<bool> hasReachedMilestone(int milestone) async {
    final currentCount = await getCurrentCount();
    return currentCount >= milestone;
  }

  /// Get water intake statistics
  Future<Map<String, dynamic>> getWaterStats() async {
    final currentCount = await getCurrentCount();
    final history = await getWaterHistory(days: 7);
    
    final weeklyTotal = history.values.fold(0, (sum, count) => sum + count) + currentCount;
    final weeklyAverage = weeklyTotal / 8; // 7 days + today
    final maxDaily = history.values.fold(currentCount, (max, count) => count > max ? count : max);
    
    return {
      'today': currentCount,
      'weeklyTotal': weeklyTotal,
      'weeklyAverage': weeklyAverage.round(),
      'maxDaily': maxDaily,
      'streak': await _calculateStreak(),
    };
  }

  /// Calculate current water streak
  Future<int> _calculateStreak() async {
    final history = await getWaterHistory(days: 30);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final currentCount = await getCurrentCount();
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    // Check today first
    if (currentCount >= 8) { // Assuming 8 glasses is the goal
      streak++;
    } else {
      return 0; // Streak broken today
    }
    
    // Check previous days
    for (int i = 1; i <= 30; i++) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      final dateString = checkDate.toIso8601String().split('T')[0];
      final dayCount = history[dateString] ?? 0;
      
      if (dayCount >= 8) {
        streak++;
      } else {
        break; // Streak broken
      }
    }
    
    return streak;
  }

  /// Reset water count (for testing or admin purposes)
  Future<void> resetWaterCount() async {
    await _ensureInitialized();
    
    // Wait for any ongoing operation with timeout
    int waitCount = 0;
    const maxWait = 50; // 5 seconds max
    
    while (_operationCompleter != null && 
           !_operationCompleter!.isCompleted && 
           waitCount < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }
    
    if (_operationCompleter != null && !_operationCompleter!.isCompleted) {
      print('AtomicWaterService: ⚠️ Reset timeout - forcing completion');
      _operationCompleter!.completeError(TimeoutException('Water reset timed out'));
      _operationCompleter = null;
    }
    
    _operationCompleter = Completer<void>();
    
    try {
      await _prefs?.setInt(_waterCountKey, 0);
      _operationCompleter?.complete();
      debugPrint('AtomicWaterService: Water count reset to 0');
    } catch (e) {
      _operationCompleter?.completeError(e);
      rethrow;
    }
  }
}