// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\providers\activity_provider.dart

// lib/core/providers/activity_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../services/storage_service.dart';

final Uuid uuid = Uuid();

class ActivityProvider with ChangeNotifier {
  List<Activity> _activities = [];
  final StorageService _storageService = StorageService();

  List<Activity> get activities => _activities;

  Future<void> loadInitialData() async {
    _activities = await _storageService.getActivities();
    if (_activities.isEmpty) {
      _activities.addAll([
        Activity(id: uuid.v4(),label: 'Morning Walk (30 mins)',type: 'Exercise', isCustom: false),
        Activity(id: uuid.v4(),label: 'Drink 8 glasses of water', type: 'Hydration',isCustom: false),
        Activity(id: uuid.v4(),label: 'Mindfulness Meditation (10 mins)',type: 'Wellness',isCustom: false),
      ]);
      await _storageService.saveActivities(_activities);
    }
  }

  Future<void> addActivity(Activity activity) async {
    _activities.add(activity);
    await _storageService.saveActivities(_activities);
    notifyListeners();
  }

  bool containsActivity({required String label, String? type}) {
    return _activities.any((activity) =>
    activity.label.trim().toLowerCase() == label.trim().toLowerCase() &&
        (type == null || activity.type == type));
  }

  Future<void> removeActivityByLabelAndType({required String label, String? type}) async {
    _activities.removeWhere((activity) =>
    activity.label.trim().toLowerCase() == label.trim().toLowerCase() &&
        (type == null || activity.type == type));
    await _storageService.saveActivities(_activities);
    notifyListeners();
  }

  Future<Activity?> toggleActivityDone(String id) async {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      _activities[index].isDone = !_activities[index].isDone;
      await _storageService.saveActivities(_activities);
      notifyListeners();
      return _activities[index];
    }
    return null;
  }

  Future<void> deleteActivity(String id) async {
    _activities.removeWhere((activity) => activity.id == id);
    await _storageService.saveActivities(_activities);
    notifyListeners();
  }

  Future<void> clearCompletedActivities() async {
    _activities.removeWhere((activity) => activity.isDone && !activity.isCustom);
    await _storageService.saveActivities(_activities);
    notifyListeners();
  }

  Future<void> resetActivitiesCompletion() async {
    for (var activity in _activities) {
      activity.isDone = false;
    }
    await _storageService.saveActivities(_activities);
    notifyListeners();
  }
}
