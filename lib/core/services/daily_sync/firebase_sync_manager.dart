// lib/core/services/daily_sync/firebase_sync_manager.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/user_data.dart';
import '../../models/daily_checkin_data.dart';
import '../../models/daily_step_data.dart';
import '../../models/achievement.dart';
import '../../models/activity.dart';

/// Manages Firebase sync operations
class FirebaseSyncManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();

  /// Check if Firebase sync is possible
  Future<bool> canSync() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking sync capability: $e');
      return false;
    }
  }

  // Immediate Sync Methods (Real-time)

  Future<void> syncUserDataImmediate(UserData userData) async {
    if (!await canSync()) return;
    
    try {
      final user = _auth.currentUser!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData.toJson(), SetOptions(merge: true));
      debugPrint('User data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate user data sync: $e');
    }
  }

  Future<void> syncCheckinDataImmediate(DailyCheckinData checkinData) async {
    if (!await canSync()) return;
    
    try {
      final user = _auth.currentUser!;
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('checkins')
          .doc(today)
          .set(checkinData.toJson(), SetOptions(merge: true));
      debugPrint('Checkin data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate checkin data sync: $e');
    }
  }

  Future<void> syncStepDataImmediate(List<DailyStepData> stepData) async {
    if (!await canSync()) return;
    
    try {
      final user = _auth.currentUser!;
      final batch = _firestore.batch();
      for (final data in stepData) {
        final dateStr = data.date.toIso8601String().split('T')[0];
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('steps')
            .doc(dateStr);
        batch.set(docRef, data.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Step data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate step data sync: $e');
    }
  }

  Future<void> syncAchievementsImmediate(List<Achievement> achievements) async {
    if (!await canSync()) return;
    
    try {
      final user = _auth.currentUser!;
      final batch = _firestore.batch();
      for (final achievement in achievements) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('achievements')
            .doc(achievement.id);
        batch.set(docRef, achievement.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Achievements synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate achievements sync: $e');
    }
  }

  Future<void> syncActivitiesImmediate(List<Activity> activities) async {
    if (!await canSync()) return;
    
    try {
      final user = _auth.currentUser!;
      final batch = _firestore.batch();
      for (final activity in activities) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .doc(activity.id);
        batch.set(docRef, activity.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Activities synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate activities sync: $e');
    }
  }

  Future<void> syncExperienceDataImmediate(Map<String, dynamic> experienceData) async {
    if (!await canSync()) return;
    
    try {
      final user = _auth.currentUser!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('experience')
          .doc('data')
          .set(experienceData, SetOptions(merge: true));
      debugPrint('Experience data synced to Firebase immediately');
    } catch (e) {
      debugPrint('Error in immediate experience data sync: $e');
    }
  }

  Future<void> syncWaterGlassCountImmediate(int count) async {
    if (!await canSync()) return;
    
    try {
      final user = _auth.currentUser!;
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_progress')
          .doc(today)
          .set({
            'waterGlassCount': count,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      debugPrint('Water glass count synced to Firebase immediately: $count');
    } catch (e) {
      debugPrint('Error in immediate water glass count sync: $e');
    }
  }

  // Scheduled Sync Methods (To Firebase)

  Future<void> syncUserDataToFirebase(UserData? userData) async {
    if (userData == null) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userData.toJson(), SetOptions(merge: true));
        debugPrint('User data synced to Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing user data to Firebase: $e');
    }
  }

  Future<void> syncCheckinDataToFirebase(DailyCheckinData? checkinData) async {
    if (checkinData == null) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('checkins')
            .doc(today)
            .set(checkinData.toJson(), SetOptions(merge: true));
        debugPrint('Checkin data synced to Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing checkin data to Firebase: $e');
    }
  }

  Future<void> syncStepDataToFirebase(List<DailyStepData> stepData) async {
    if (stepData.isEmpty) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        for (final data in stepData) {
          final dateStr = data.date.toIso8601String().split('T')[0];
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('steps')
              .doc(dateStr);
          batch.set(docRef, data.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
        debugPrint('Step data synced to Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing step data to Firebase: $e');
    }
  }

  Future<void> syncAchievementsToFirebase(List<Achievement> achievements) async {
    if (achievements.isEmpty) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        for (final achievement in achievements) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('achievements')
              .doc(achievement.id);
          batch.set(docRef, achievement.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
        debugPrint('Achievements synced to Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing achievements to Firebase: $e');
    }
  }

  Future<void> syncActivitiesToFirebase(List<Activity> activities) async {
    if (activities.isEmpty) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        for (final activity in activities) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('activities')
              .doc(activity.id);
          batch.set(docRef, activity.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
        debugPrint('Activities synced to Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing activities to Firebase: $e');
    }
  }

  Future<void> syncExperienceDataToFirebase(Map<String, dynamic> experienceData) async {
    if (experienceData.isEmpty) return;
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('experience')
            .doc('data')
            .set(experienceData, SetOptions(merge: true));
        debugPrint('Experience data synced to Firebase');
      }
    } catch (e) {
      debugPrint('Error syncing experience data to Firebase: $e');
    }
  }

  Future<void> syncWaterGlassCountToFirebase(int waterCount) async {
    try {
      final user = _auth.currentUser;
      if (user != null && waterCount > 0) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_progress')
            .doc(today)
            .set({
              'waterGlassCount': waterCount,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        debugPrint('Water glass count synced to Firebase: $waterCount');
      }
    } catch (e) {
      debugPrint('Error syncing water glass count to Firebase: $e');
    }
  }

  // Scheduled Sync Methods (From Firebase)

  Future<UserData?> syncUserDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          debugPrint('User data synced from Firebase');
          return UserData.fromJson(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error syncing user data from Firebase: $e');
      return null;
    }
  }

  Future<DailyCheckinData?> syncCheckinDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('checkins')
            .doc(today)
            .get();
        if (doc.exists) {
          debugPrint('Checkin data synced from Firebase');
          return DailyCheckinData.fromJson(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error syncing checkin data from Firebase: $e');
      return null;
    }
  }

  Future<List<DailyStepData>> syncStepDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));
        
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('steps')
            .where('date', isGreaterThanOrEqualTo: startDate)
            .get();

        final stepData = query.docs
            .map((doc) => DailyStepData.fromJson(doc.data()))
            .toList();
            
        debugPrint('Step data synced from Firebase');
        return stepData;
      }
      return [];
    } catch (e) {
      debugPrint('Error syncing step data from Firebase: $e');
      return [];
    }
  }

  Future<List<Achievement>> syncAchievementsFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('achievements')
            .get();

        final achievements = query.docs
            .map((doc) => Achievement.fromJson(doc.data()))
            .toList();
            
        debugPrint('Achievements synced from Firebase');
        return achievements;
      }
      return [];
    } catch (e) {
      debugPrint('Error syncing achievements from Firebase: $e');
      return [];
    }
  }

  Future<List<Activity>> syncActivitiesFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));
        
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .get();

        final activities = query.docs
            .map((doc) => Activity.fromJson(doc.data()))
            .toList();
            
        debugPrint('Activities synced from Firebase');
        return activities;
      }
      return [];
    } catch (e) {
      debugPrint('Error syncing activities from Firebase: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> syncExperienceDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('experience')
            .doc('data')
            .get();
        if (doc.exists) {
          debugPrint('Experience data synced from Firebase');
          return Map<String, dynamic>.from(doc.data()!);
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error syncing experience data from Firebase: $e');
      return {};
    }
  }

  Future<int> syncWaterGlassCountFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_progress')
            .doc(today)
            .get();
        if (doc.exists && doc.data()!.containsKey('waterGlassCount')) {
          final waterCount = doc.data()!['waterGlassCount'] as int? ?? 0;
          debugPrint('Water glass count synced from Firebase: $waterCount');
          return waterCount;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error syncing water glass count from Firebase: $e');
      return 0;
    }
  }

  /// Sync today's step data from Firebase
  Future<DailyStepData?> syncTodaysStepDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(today)
          .get();
          
      if (doc.exists) {
        final stepData = DailyStepData.fromJson(doc.data()!);
        debugPrint('Today\'s step data synced from Firebase: ${stepData.steps} steps');
        return stepData;
      }
      return null;
    } catch (e) {
      debugPrint('Error syncing today\'s step data from Firebase: $e');
      return null;
    }
  }
}
