// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\providers\leaderboard_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

enum LeaderboardTimeframe { daily, weekly }

class LeaderboardProvider with ChangeNotifier {
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = false;
  LeaderboardTimeframe _currentTimeframe = LeaderboardTimeframe.daily;

  // Getters
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  LeaderboardTimeframe get currentTimeframe => _currentTimeframe;

  // Set timeframe
  void setTimeframe(LeaderboardTimeframe timeframe) {
    _currentTimeframe = timeframe;
    refreshLeaderboard();
    notifyListeners();
  }

  // Refresh leaderboard data
  Future<void> refreshLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('todaySteps', descending: true)
          .limit(100)
          .get();

      _leaderboard = snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry(
          id: doc.id,
          displayName: data['name'] ?? 'Unknown',
          photoUrl: data['profilePicturePath'],
          todaySteps: data['todaySteps'] ?? 0,
          caloriesBurned: (data['todaySteps'] ?? 0) * 0.04,
          timestamp: DateTime.now(),
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing leaderboard: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get weekly leaderboard
  Future<void> getWeeklyLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('weeklySteps', descending: true)
          .limit(100)
          .get();

      _leaderboard = snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry(
          id: doc.id,
          displayName: data['name'] ?? 'Unknown',
          photoUrl: data['profilePicturePath'],
          todaySteps: data['weeklySteps'] ?? 0,
          caloriesBurned: (data['weeklySteps'] ?? 0) * 0.04,
          timestamp: DateTime.now(),
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // print('Error getting weekly leaderboard: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}

