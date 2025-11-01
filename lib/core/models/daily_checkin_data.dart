// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\models\daily_checkin_data.dart

// lib/core/models/daily_checkin_data.dart
class DailyCheckinData {
  final DateTime date;
  int mood; // 1 to 5 scale
  int waterIntake; // in glasses
  double weight; // in kg
  double sleepHours; // hours of sleep
  int mealCount; // number of meals logged
  int meditationMinutes; // minutes spent meditating

  DailyCheckinData({
    required this.date,
    this.mood = 3,
    this.waterIntake = 0,
    this.weight = 0.0,
    this.sleepHours = 0.0,
    this.mealCount = 0,
    this.meditationMinutes = 0,
  });

  factory DailyCheckinData.fromJson(Map<String, dynamic> json) {
    return DailyCheckinData(
      date: DateTime.parse(json['date']),
      mood: json['mood'] ?? 3,
      waterIntake: json['waterIntake'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0.0,
      mealCount: json['mealCount'] ?? 0,
      meditationMinutes: json['meditationMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mood': mood,
      'waterIntake': waterIntake,
      'weight': weight,
      'sleepHours': sleepHours,
      'mealCount': mealCount,
      'meditationMinutes': meditationMinutes,
    };
  }

  DailyCheckinData copyWith({
    DateTime? date,
    int? mood,
    int? waterIntake,
    double? weight,
    double? sleepHours,
    int? mealCount,
    int? meditationMinutes,
  }) {
    return DailyCheckinData(
      date: date ?? this.date,
      mood: mood ?? this.mood,
      waterIntake: waterIntake ?? this.waterIntake,
      weight: weight ?? this.weight,
      sleepHours: sleepHours ?? this.sleepHours,
      mealCount: mealCount ?? this.mealCount,
      meditationMinutes: meditationMinutes ?? this.meditationMinutes,
    );
  }
}
