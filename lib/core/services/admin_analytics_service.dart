import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Service for tracking and storing admin analytics data in Firebase
class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Constants for analytics tracking
  static const String _lastActiveKey = 'last_active_timestamp';
  static const String _dailyActiveKey = 'daily_active_users';
  static const String _weeklyActiveKey = 'weekly_active_users';
  static const String _monthlyActiveKey = 'monthly_active_users';
  static const String _totalUsersKey = 'total_users';
  static const String _userEngagementKey = 'user_engagement';
  static const String _featureUsageKey = 'feature_usage';
  static const String _userRetentionKey = 'user_retention';
  
  /// Track user activity and update active user counts
  Future<void> trackUserActivity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final userId = user.uid;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      
      // Get last active timestamp from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastActive = prefs.getInt(_lastActiveKey) ?? 0;
      
      // Update last active timestamp
      await prefs.setInt(_lastActiveKey, now.millisecondsSinceEpoch);
      
      // Update user's last active timestamp in Firestore
      await _firestore.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      // Check if this is a new day, week, or month
      final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastActive);
      final isNewDay = lastActiveDate.day != now.day || 
                       lastActiveDate.month != now.month || 
                       lastActiveDate.year != now.year;
      final isNewWeek = _getWeekNumber(now) != _getWeekNumber(lastActiveDate) ||
                        now.year != lastActiveDate.year;
      final isNewMonth = now.month != lastActiveDate.month || 
                         now.year != lastActiveDate.year;
      
      // Update admin analytics in Firestore
      final adminRef = _firestore.collection('admin').doc('analytics');
      
      // Update daily active users if this is a new day
      if (isNewDay || lastActive == 0) {
        await _updateActiveUsers(adminRef, _dailyActiveKey, today, userId);
      }
      
      // Update weekly active users if this is a new week
      if (isNewWeek || lastActive == 0) {
        final weekStart = _getStartOfWeek(now).millisecondsSinceEpoch;
        await _updateActiveUsers(adminRef, _weeklyActiveKey, weekStart, userId);
      }
      
      // Update monthly active users if this is a new month
      if (isNewMonth || lastActive == 0) {
        final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
        await _updateActiveUsers(adminRef, _monthlyActiveKey, monthStart, userId);
      }
      
      // Track user engagement
      await _trackUserEngagement(userId);
      
    } catch (e) {
      debugPrint('Error tracking user activity: $e');
    }
  }
  
  /// Update active users count for a specific time period
  Future<void> _updateActiveUsers(DocumentReference adminRef, String key, int timestamp, String userId) async {
    try {
      // Get the current active users map
      final doc = await adminRef.get();
      Map<String, dynamic> data = doc.exists ? doc.data() as Map<String, dynamic> : {};
      
      // Get or create the active users map for this time period
      Map<String, dynamic> activeUsers = data[key] != null ? 
          Map<String, dynamic>.from(data[key]) : {};
      
      // Get or create the users set for this timestamp
      String timestampStr = timestamp.toString();
      List<String> users = activeUsers[timestampStr] != null ?
          List<String>.from(activeUsers[timestampStr]) : [];
      
      // Add the user if not already in the list
      if (!users.contains(userId)) {
        users.add(userId);
      }
      
      // Update the active users map
      activeUsers[timestampStr] = users;
      
      // Update the admin analytics document
      await adminRef.set({
        key: activeUsers,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error updating active users: $e');
    }
  }
  
  /// Track user engagement metrics
  Future<void> _trackUserEngagement(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      
      // Calculate engagement score based on user activity
      int engagementScore = 0;
      
      // Check for completed activities
      if (userData['stepCount'] != null) engagementScore += 1;
      if (userData['waterIntake'] != null) engagementScore += 1;
      if (userData['level'] != null) engagementScore += (userData['level'] as num).toInt();
      
      // Update user engagement in admin analytics
      await _firestore.collection('admin').doc('analytics').set({
        _userEngagementKey: {
          userId: {
            'score': engagementScore,
            'lastActive': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error tracking user engagement: $e');
    }
  }
  
  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection('admin').doc('analytics').set({
        _featureUsageKey: {
          featureName: FieldValue.increment(1)
        }
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error tracking feature usage: $e');
    }
  }
  
  /// Track user retention
  Future<void> trackUserRetention() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final userId = user.uid;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      
      // Get user creation time
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final creationTime = userData['createdAt'] as Timestamp?;
      
      if (creationTime != null) {
        final daysSinceCreation = now.difference(creationTime.toDate()).inDays;
        
        // Update user retention in admin analytics
        await _firestore.collection('admin').doc('analytics').set({
          _userRetentionKey: {
            daysSinceCreation.toString(): FieldValue.increment(1)
          }
        }, SetOptions(merge: true));
      }
      
    } catch (e) {
      debugPrint('Error tracking user retention: $e');
    }
  }
  
  /// Update total users count
  Future<void> updateTotalUsers() async {
    try {
      // Count total users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      
      // Update total users count in admin analytics
      await _firestore.collection('admin').doc('analytics').set({
        _totalUsersKey: totalUsers,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error updating total users: $e');
    }
  }
  
  /// Get week number from date
  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
        DateFormat('D').format(date)); // Day of year (1-366)
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
  
  /// Get start of week from date
  DateTime _getStartOfWeek(DateTime date) {
    final daysToSubtract = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }
}