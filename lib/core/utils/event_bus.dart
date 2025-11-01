// lib/core/utils/event_bus.dart

import 'dart:async';

/// Event types for the application
enum AppEventType {
  xpGained,
  levelUp,
  achievementUnlocked,
  stepGoalReached,
  waterGoalReached,
  dailyCheckinComplete,
  dataSync,
}

/// Base class for all events
abstract class AppEvent {
  final AppEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  AppEvent(this.type, this.data) : timestamp = DateTime.now();
}

/// XP gained event
class XpGainedEvent extends AppEvent {
  final int xpAmount;
  final String activityType;
  
  XpGainedEvent(this.xpAmount, this.activityType)
      : super(AppEventType.xpGained, {
          'xpAmount': xpAmount,
          'activityType': activityType,
        });
}

/// Level up event
class LevelUpEvent extends AppEvent {
  final int newLevel;
  final int previousLevel;
  
  LevelUpEvent(this.newLevel, this.previousLevel)
      : super(AppEventType.levelUp, {
          'newLevel': newLevel,
          'previousLevel': previousLevel,
        });
}

/// Achievement unlocked event
class AchievementUnlockedEvent extends AppEvent {
  final String achievementId;
  final String achievementName;
  
  AchievementUnlockedEvent(this.achievementId, this.achievementName)
      : super(AppEventType.achievementUnlocked, {
          'achievementId': achievementId,
          'achievementName': achievementName,
        });
}

/// Step goal reached event
class StepGoalReachedEvent extends AppEvent {
  final int steps;
  final int goal;
  
  StepGoalReachedEvent(this.steps, this.goal)
      : super(AppEventType.stepGoalReached, {
          'steps': steps,
          'goal': goal,
        });
}

/// Water goal reached event
class WaterGoalReachedEvent extends AppEvent {
  final int glasses;
  final int goal;
  
  WaterGoalReachedEvent(this.glasses, this.goal)
      : super(AppEventType.waterGoalReached, {
          'glasses': glasses,
          'goal': goal,
        });
}

/// Daily checkin complete event
class DailyCheckinCompleteEvent extends AppEvent {
  DailyCheckinCompleteEvent()
      : super(AppEventType.dailyCheckinComplete, {});
}

/// Data sync event
class DataSyncEvent extends AppEvent {
  final bool success;
  final String? error;
  
  DataSyncEvent(this.success, {this.error})
      : super(AppEventType.dataSync, {
          'success': success,
          'error': error,
        });
}

/// Simple event bus for decoupling providers
class EventBus {
  // Singleton pattern
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();
  
  // Stream controllers for each event type
  final Map<AppEventType, StreamController<AppEvent>> _controllers = {};
  
  // Get or create stream controller for event type
  StreamController<AppEvent> _getController(AppEventType type) {
    if (!_controllers.containsKey(type)) {
      _controllers[type] = StreamController<AppEvent>.broadcast();
    }
    return _controllers[type]!;
  }
  
  /// Publish an event
  void publish(AppEvent event) {
    final controller = _getController(event.type);
    if (!controller.isClosed) {
      controller.add(event);
    }
  }
  
  /// Subscribe to events of a specific type
  StreamSubscription<AppEvent> subscribe(
    AppEventType type,
    void Function(AppEvent) onEvent,
  ) {
    return _getController(type).stream.listen(onEvent);
  }
  
  /// Subscribe to all events
  StreamSubscription<AppEvent> subscribeAll(
    void Function(AppEvent) onEvent,
  ) {
    // Merge all streams
    final streams = AppEventType.values.map((type) => _getController(type).stream);
    return StreamGroup.merge(streams).listen(onEvent);
  }
  
  /// Dispose all controllers
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
  
  /// Dispose specific event type controller
  void disposeType(AppEventType type) {
    if (_controllers.containsKey(type)) {
      _controllers[type]!.close();
      _controllers.remove(type);
    }
  }
}

/// Stream group helper for merging streams
class StreamGroup<T> {
  static Stream<T> merge(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();
    final subscriptions = <StreamSubscription<T>>[];
    
    for (final stream in streams) {
      subscriptions.add(stream.listen(
        controller.add,
        onError: controller.addError,
      ));
    }
    
    controller.onCancel = () {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    };
    
    return controller.stream;
  }
}
