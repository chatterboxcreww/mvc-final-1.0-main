// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\models\firebase_step_data.dart

// lib/core/models/firebase_step_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'daily_step_data.dart';

/// Model for storing step data in Firebase
/// This model is used to serialize/deserialize step data for Firebase storage
class FirebaseStepData {
  final DateTime date;
  final int count;
  final Timestamp? timestamp;

  FirebaseStepData({
    required this.date,
    required this.count,
    this.timestamp,
  });

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'count': count,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  /// Create from a Firestore document
  factory FirebaseStepData.fromMap(Map<String, dynamic> map) {
    return FirebaseStepData(
      date: (map['date'] as Timestamp).toDate(),
      count: map['count'] ?? 0,
      timestamp: map['timestamp'] as Timestamp?,
    );
  }

  /// Convert to a DailyStepData object for local storage
  DailyStepData toDailyStepData({int goal = 10000}) {
    return DailyStepData(
      date: date,
      steps: count,
      goal: goal,
      caloriesBurned: count * 0.04, // 0.04 calories per step
      distanceMeters: count * 0.762, // 0.762 meters per step
    );
  }

  /// Create from a DailyStepData object
  factory FirebaseStepData.fromDailyStepData(DailyStepData dailyData) {
    return FirebaseStepData(
      date: dailyData.date,
      count: dailyData.steps,
      timestamp: Timestamp.now(),
    );
  }

  @override
  String toString() {
    return 'FirebaseStepData(date: $date, count: $count, timestamp: $timestamp)';
  }
}
