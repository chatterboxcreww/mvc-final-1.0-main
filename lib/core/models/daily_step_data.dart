// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\models\daily_step_data.dart

// lib/core/models/daily_step_data.dart

class DailyStepData {
  final DateTime date;
  int steps; // Changed to mutable for proper data updates
  int goal;  // Changed to mutable for goal updates
  final double caloriesBurned;
  final double distanceMeters;
  int deviceStepsAtSave; // Changed to mutable for tracking device baseline

  DailyStepData({
    required this.date,
    required this.steps,
    required this.goal,
    this.caloriesBurned = 0.0,
    this.distanceMeters = 0.0,
    this.deviceStepsAtSave = 0,
  });

  bool get goalReached => steps >= goal;
  
  double get progressPercentage => goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;

  factory DailyStepData.fromJson(Map<String, dynamic> json) {
    return DailyStepData(
      date: DateTime.parse(json['date']),
      steps: json['steps'] ?? 0,
      goal: json['goal'] ?? 10000,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      deviceStepsAtSave: json['deviceStepsAtSave'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'goal': goal,
      'caloriesBurned': caloriesBurned,
      'distanceMeters': distanceMeters,
      'deviceStepsAtSave': deviceStepsAtSave,
    };
  }

  DailyStepData copyWith({
    DateTime? date,
    int? steps,
    int? goal,
    double? caloriesBurned,
    double? distanceMeters,
    int? deviceStepsAtSave,
    bool? goalReached,
  }) {
    return DailyStepData(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      deviceStepsAtSave: deviceStepsAtSave ?? this.deviceStepsAtSave,
    );
  }

  @override
  String toString() {
    return 'DailyStepData(date: $date, steps: $steps, goal: $goal, goalReached: $goalReached)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyStepData &&
        other.date == date &&
        other.steps == steps &&
        other.goal == goal;
  }

  @override
  int get hashCode {
    return date.hashCode ^ steps.hashCode ^ goal.hashCode;
  }
}
