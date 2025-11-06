// lib/core/services/daily_sync/water_tracking_manager.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_constants.dart';
import 'local_storage_manager.dart';

/// Manages water tracking and milestone achievements
class WaterTrackingManager {
  final LocalStorageManager _localStorage;

  WaterTrackingManager(this._localStorage);

  /// Increment water glass count
  Future<int> incrementWaterGlassCount() async {
    try {
      final currentCount = await _localStorage.getWaterGlassCount();
      final newCount = currentCount + 1;
      await _localStorage.saveWaterGlassCount(newCount);
      
      // Check for 9-glass milestone and award experience
      if (newCount == SyncConstants.waterMilestoneTarget) {
        await _awardWaterMilestoneExperience();
      }
      
      debugPrint('Water glass count incremented to: $newCount');
      return newCount;
    } catch (e) {
      debugPrint('Error incrementing water glass count: $e');
      return await _localStorage.getWaterGlassCount();
    }
  }

  /// Decrement water glass count (with minimum of 0)
  Future<int> decrementWaterGlassCount() async {
    try {
      final currentCount = await _localStorage.getWaterGlassCount();
      final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();
      await _localStorage.saveWaterGlassCount(newCount);
      debugPrint('Water glass count decremented to: $newCount');
      return newCount;
    } catch (e) {
      debugPrint('Error decrementing water glass count: $e');
      return await _localStorage.getWaterGlassCount();
    }
  }

  /// Award experience points for reaching 9 glasses milestone
  Future<void> _awardWaterMilestoneExperience() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = _localStorage.prefs;
      
      // Check if experience was already awarded today
      final lastExpAwardDate = prefs.getString(SyncConstants.lastWaterExpAwardDateKey);
      if (lastExpAwardDate == today) {
        debugPrint('Water milestone experience already awarded today');
        return;
      }
      
      // Award experience points
      final experienceData = await _localStorage.getExperienceData();
      final currentExp = experienceData['totalExp'] as int? ?? 0;
      final newExp = currentExp + SyncConstants.waterMilestoneExp;
      
      experienceData['totalExp'] = newExp;
      experienceData['waterMilestoneExp'] = (experienceData['waterMilestoneExp'] as int? ?? 0) + SyncConstants.waterMilestoneExp;
      experienceData['lastWaterMilestone'] = DateTime.now().toIso8601String();
      
      await _localStorage.saveExperienceData(experienceData);
      await prefs.setString(SyncConstants.lastWaterExpAwardDateKey, today);
      
      debugPrint('🎉 Water milestone reached! Awarded ${SyncConstants.waterMilestoneExp} XP for drinking ${SyncConstants.waterMilestoneTarget} glasses. Total XP: $newExp');
    } catch (e) {
      debugPrint('Error awarding water milestone experience: $e');
    }
  }

  /// Check if water milestone (9 glasses) has been reached today
  Future<bool> hasReachedWaterMilestoneToday() async {
    try {
      final waterCount = await _localStorage.getWaterGlassCount();
      return waterCount >= SyncConstants.waterMilestoneTarget;
    } catch (e) {
      debugPrint('Error checking water milestone: $e');
      return false;
    }
  }

  /// Check if water milestone experience has been awarded today
  Future<bool> hasWaterMilestoneExpBeenAwarded() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = _localStorage.prefs;
      final lastExpAwardDate = prefs.getString(SyncConstants.lastWaterExpAwardDateKey);
      return lastExpAwardDate == today;
    } catch (e) {
      debugPrint('Error checking water milestone exp award: $e');
      return false;
    }
  }

  /// Get water milestone status
  Future<Map<String, dynamic>> getWaterMilestoneStatus() async {
    try {
      final waterCount = await _localStorage.getWaterGlassCount();
      final milestoneReached = waterCount >= SyncConstants.waterMilestoneTarget;
      final expAwarded = await hasWaterMilestoneExpBeenAwarded();
      
      return {
        'currentCount': waterCount,
        'milestoneTarget': SyncConstants.waterMilestoneTarget,
        'milestoneReached': milestoneReached,
        'experienceAwarded': expAwarded,
        'remainingForMilestone': milestoneReached ? 0 : (SyncConstants.waterMilestoneTarget - waterCount),
        'experiencePoints': SyncConstants.waterMilestoneExp,
      };
    } catch (e) {
      debugPrint('Error getting water milestone status: $e');
      return {
        'currentCount': 0,
        'milestoneTarget': SyncConstants.waterMilestoneTarget,
        'milestoneReached': false,
        'experienceAwarded': false,
        'remainingForMilestone': SyncConstants.waterMilestoneTarget,
        'experiencePoints': SyncConstants.waterMilestoneExp,
      };
    }
  }
}
