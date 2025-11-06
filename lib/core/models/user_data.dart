// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\models\user_data.dart

import 'package:flutter/material.dart';
import 'app_enums.dart';

class UserData {
  final String userId;
  String? name;
  String? email;
  int? age;
  double? height; // in cm
  double? weight; // in kg
  double? bmr; // Basal Metabolic Rate

  DietPreference? dietPreference;
  Gender? gender;
  TimeOfDay? sleepTime;
  TimeOfDay? wakeupTime;

  bool? hasDiabetes;
  bool? isSkinnyFat;
  bool? hasProteinDeficiency;
  bool? hasHighBloodPressure;
  bool? hasHighCholesterol;
  bool? isUnderweight;
  bool? hasAnxiety;
  bool? hasLowEnergyLevels;
  List<String>? allergies;

  // User preferences and goals
  String? activityLevel;
  int? dailyWaterGoal;
  int? dailyStepGoal;
  int? dailyCalorieGoal;
  int? sleepGoalHours;
  int todaySteps;

  DateTime? memberSince;
  String? profilePicturePath;

  bool waterReminderEnabled;
  bool morningWalkReminderEnabled;
  bool wakeupNotificationEnabled;
  bool sleepNotificationEnabled;

  bool? prefersCoffee;
  bool? prefersTea;

  int level;

  UserData({
    required this.userId,
    this.name,
    this.email,
    this.age,
    this.height,
    this.weight,
    this.bmr,
    this.dietPreference,
    this.gender,
    this.sleepTime,
    this.wakeupTime,
    this.hasDiabetes,
    this.isSkinnyFat,
    this.hasProteinDeficiency,
    this.hasHighBloodPressure,
    this.hasHighCholesterol,
    this.isUnderweight,
    this.hasAnxiety,
    this.hasLowEnergyLevels,
    this.allergies,
    this.activityLevel,
    this.dailyWaterGoal = 8,
    this.dailyStepGoal = 10000,
    this.dailyCalorieGoal,
    this.sleepGoalHours = 8,
    this.todaySteps = 0,
    this.memberSince,
    this.profilePicturePath,
    this.waterReminderEnabled = true,
    this.morningWalkReminderEnabled = true,
    this.wakeupNotificationEnabled = true,
    this.sleepNotificationEnabled = true,
    this.prefersCoffee,
    this.prefersTea,
    this.level = 1,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['userId'] ?? '',
      name: json['name'],
      email: json['email'],
      age: json['age'],
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      bmr: (json['bmr'] as num?)?.toDouble(),
      dietPreference: json['dietPreference'] != null
          ? DietPreference.values.firstWhere(
            (e) => e.name == json['dietPreference'],
        orElse: () => DietPreference.vegetarian,
      )
          : null,
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
            (e) => e.name == json['gender'],
        orElse: () => Gender.other,
      )
          : null,
      sleepTime: json['sleepTimeHour'] != null && json['sleepTimeMinute'] != null
          ? TimeOfDay(hour: json['sleepTimeHour'], minute: json['sleepTimeMinute'])
          : null,
      wakeupTime: json['wakeupTimeHour'] != null && json['wakeupTimeMinute'] != null
          ? TimeOfDay(hour: json['wakeupTimeHour'], minute: json['wakeupTimeMinute'])
          : null,
      hasDiabetes: json['hasDiabetes'],
      isSkinnyFat: json['isSkinnyFat'],
      hasProteinDeficiency: json['hasProteinDeficiency'],
      hasHighBloodPressure: json['hasHighBloodPressure'],
      hasHighCholesterol: json['hasHighCholesterol'],
      isUnderweight: json['isUnderweight'],
      hasAnxiety: json['hasAnxiety'],
      hasLowEnergyLevels: json['hasLowEnergyLevels'],
      allergies: json['allergies'] != null ? List<String>.from(json['allergies']) : null,
      activityLevel: json['activityLevel'],
      dailyWaterGoal: json['dailyWaterGoal'],
      dailyStepGoal: json['dailyStepGoal'] ?? 10000,
      dailyCalorieGoal: json['dailyCalorieGoal'],
      sleepGoalHours: json['sleepGoalHours'],
      todaySteps: json['todaySteps'] ?? 0,
      memberSince: json['memberSince'] != null ? DateTime.tryParse(json['memberSince']) : null,
      profilePicturePath: json['profilePicturePath'],
      waterReminderEnabled: json['waterReminderEnabled'] ?? true,
      morningWalkReminderEnabled: json['morningWalkReminderEnabled'] ?? true,
      wakeupNotificationEnabled: json['wakeupNotificationEnabled'] ?? true,
      sleepNotificationEnabled: json['sleepNotificationEnabled'] ?? true,
      prefersCoffee: json['prefersCoffee'],
      prefersTea: json['prefersTea'],
      level: json['level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'age': age,
      'height': height,
      'weight': weight,
      'bmr': bmr,
      'dietPreference': dietPreference?.name,
      'gender': gender?.name,
      'sleepTimeHour': sleepTime?.hour,
      'sleepTimeMinute': sleepTime?.minute,
      'wakeupTimeHour': wakeupTime?.hour,
      'wakeupTimeMinute': wakeupTime?.minute,
      'hasDiabetes': hasDiabetes,
      'isSkinnyFat': isSkinnyFat,
      'hasProteinDeficiency': hasProteinDeficiency,
      'hasHighBloodPressure': hasHighBloodPressure,
      'hasHighCholesterol': hasHighCholesterol,
      'isUnderweight': isUnderweight,
      'hasAnxiety': hasAnxiety,
      'hasLowEnergyLevels': hasLowEnergyLevels,
      'allergies': allergies,
      'activityLevel': activityLevel,
      'dailyWaterGoal': dailyWaterGoal,
      'dailyStepGoal': dailyStepGoal,
      'dailyCalorieGoal': dailyCalorieGoal,
      'sleepGoalHours': sleepGoalHours,
      'todaySteps': todaySteps,
      'memberSince': memberSince?.toIso8601String(),
      'profilePicturePath': profilePicturePath,
      'waterReminderEnabled': waterReminderEnabled,
      'morningWalkReminderEnabled': morningWalkReminderEnabled,
      'wakeupNotificationEnabled': wakeupNotificationEnabled,
      'sleepNotificationEnabled': sleepNotificationEnabled,
      'prefersCoffee': prefersCoffee,
      'prefersTea': prefersTea,
      'level': level,
    };
  }

  // Helper getters and methods
  bool get hasHealthInfo =>
      hasDiabetes != null ||
          isSkinnyFat != null ||
          hasProteinDeficiency != null ||
          hasHighBloodPressure != null ||
          hasHighCholesterol != null ||
          isUnderweight != null ||
          hasAnxiety != null ||
          hasLowEnergyLevels != null ||
          (allergies != null && allergies!.isNotEmpty);

  double? get bmi {
    if (height != null && weight != null && height! > 0 && weight! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  String get bmiCategory {
    final calculatedBmi = bmi;
    if (calculatedBmi == null) return 'Not calculated';

    if (calculatedBmi < 18.5) return 'Underweight';
    if (calculatedBmi < 25) return 'Normal weight';
    if (calculatedBmi < 30) return 'Overweight';
    return 'Obese';
  }

  bool get isProfileComplete {
    // Basic profile requirements for modern onboarding flow
    final hasBasicInfo = name != null && name!.isNotEmpty &&
        age != null &&
        height != null &&
        weight != null &&
        gender != null;
    
    // Health goals are set in the final screen
    final hasHealthGoals = dailyStepGoal != null &&
        dailyWaterGoal != null;
    
    // If user has basic info and health goals, consider profile complete for app usage
    // Lifestyle preferences (diet, sleep) can be set later or have defaults
    return hasBasicInfo && hasHealthGoals;
  }

  /// Calculate BMR using Mifflin-St Jeor Equation
  double? calculateBMR() {
    if (height == null || weight == null || age == null || gender == null) {
      return null;
    }
    
    // Mifflin-St Jeor Equation
    // Men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
    // Women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
    
    double baseBMR = (10 * weight!) + (6.25 * height!) - (5 * age!);
    
    if (gender == Gender.male) {
      return baseBMR + 5;
    } else if (gender == Gender.female) {
      return baseBMR - 161;
    } else {
      // For other/non-binary, use average
      return baseBMR - 78; // Average of +5 and -161
    }
  }
  
  /// Calculate daily calorie goal based on BMR and activity level
  int? calculateDailyCalorieGoal() {
    final calculatedBMR = bmr ?? calculateBMR();
    if (calculatedBMR == null || activityLevel == null) {
      return null;
    }
    
    // Activity level multipliers
    double multiplier;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'veryActive':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.55; // Default to moderate
    }
    
    return (calculatedBMR * multiplier).round();
  }

  UserData sanitized() {
    // Calculate BMR if not already set
    final calculatedBMR = bmr ?? calculateBMR();
    final calculatedCalorieGoal = dailyCalorieGoal ?? calculateDailyCalorieGoal();
    
    return UserData(
      userId: userId,
      name: name,
      email: email,
      age: age,
      height: height,
      weight: weight,
      bmr: calculatedBMR,
      dietPreference: dietPreference,
      gender: gender,
      sleepTime: sleepTime,
      wakeupTime: wakeupTime,
      // Ensure health conditions have proper boolean values instead of null
      hasDiabetes: hasDiabetes ?? false,
      isSkinnyFat: isSkinnyFat ?? false,
      hasProteinDeficiency: hasProteinDeficiency ?? false,
      hasHighBloodPressure: hasHighBloodPressure ?? false,
      hasHighCholesterol: hasHighCholesterol ?? false,
      isUnderweight: isUnderweight ?? false,
      hasAnxiety: hasAnxiety ?? false,
      hasLowEnergyLevels: hasLowEnergyLevels ?? false,
      allergies: allergies ?? [],
      activityLevel: activityLevel,
      dailyWaterGoal: dailyWaterGoal ?? 8,
      dailyStepGoal: dailyStepGoal ?? 10000,
      dailyCalorieGoal: calculatedCalorieGoal,
      sleepGoalHours: sleepGoalHours ?? 8,
      todaySteps: todaySteps >= 0 ? todaySteps : 0,
      memberSince: memberSince,
      profilePicturePath: profilePicturePath,
      waterReminderEnabled: waterReminderEnabled,
      morningWalkReminderEnabled: morningWalkReminderEnabled,
      wakeupNotificationEnabled: wakeupNotificationEnabled,
      sleepNotificationEnabled: sleepNotificationEnabled,
      // Ensure preferences have proper boolean values
      prefersCoffee: prefersCoffee ?? false,
      prefersTea: prefersTea ?? false,
      level: level > 0 ? level : 1,
    );
  }

  // Validation helper methods
  bool isValidAge() {
    return age == null || (age! >= 1 && age! <= 120);
  }
  
  bool isValidHeight() {
    return height == null || (height! >= 50 && height! <= 300); // in cm
  }
  
  bool isValidWeight() {
    return weight == null || (weight! >= 20 && weight! <= 500); // in kg
  }
  
  bool isValidDailyStepGoal() {
    return dailyStepGoal == null || (dailyStepGoal! >= 1000 && dailyStepGoal! <= 50000);
  }
  
  bool isValidDailyWaterGoal() {
    return dailyWaterGoal == null || (dailyWaterGoal! > 0 && dailyWaterGoal! <= 20); // Reasonable water glass goal
  }
  
  bool isValidSleepSchedule() {
    if (sleepTime == null || wakeupTime == null) return true;
    
    // Convert to minutes for easier comparison
    final sleepMinutes = sleepTime!.hour * 60 + sleepTime!.minute;
    final wakeupMinutes = wakeupTime!.hour * 60 + wakeupTime!.minute;
    
    // Calculate sleep duration accounting for overnight sleep
    int sleepDurationMinutes;
    if (wakeupMinutes < sleepMinutes) {
      // Sleep crosses midnight
      sleepDurationMinutes = (24 * 60 - sleepMinutes) + wakeupMinutes;
    } else {
      sleepDurationMinutes = wakeupMinutes - sleepMinutes;
    }
    
    // Check if sleep duration is reasonable (between 3 and 14 hours)
    return sleepDurationMinutes >= 180 && sleepDurationMinutes <= 840;
  }

  // Comprehensive validation
  Map<String, String> validate({bool isOnboarding = false}) {
    Map<String, String> errors = {};

    // During onboarding, only validate fields that are actually set
    // After onboarding, require all essential fields
    
    if (!isOnboarding) {
      // Strict validation for profile completion
      if (name == null || name!.trim().isEmpty) {
        errors['name'] = 'Name is required';
      }
    } else {
      // Lenient validation during onboarding - only check if field exists
      if (name != null && name!.trim().isEmpty) {
        errors['name'] = 'Name cannot be empty';
      }
    }

    // Only validate if the field is set (not null)
    if (age != null && !isValidAge()) {
      errors['age'] = 'Age must be between 1 and 120 years';
    }
    
    if (height != null && !isValidHeight()) {
      errors['height'] = 'Height must be between 50 and 300 cm';
    }
    
    if (weight != null && !isValidWeight()) {
      errors['weight'] = 'Weight must be between 20 and 500 kg';
    }
    
    if (dailyStepGoal != null && !isValidDailyStepGoal()) {
      errors['dailyStepGoal'] = 'Daily step goal must be between 1,000 and 50,000 steps';
    }
    
    if (dailyWaterGoal != null && !isValidDailyWaterGoal()) {
      errors['dailyWaterGoal'] = 'Daily water goal must be between 1 and 20 glasses';
    }
    
    if (!isValidSleepSchedule()) {
      errors['sleepSchedule'] = 'Sleep schedule must allow for 3-14 hours of sleep';
    }

    return errors;
  }

  UserData copyWith({
    String? userId,
    String? name,
    String? email,
    int? age,
    double? height,
    double? weight,
    double? bmr,
    DietPreference? dietPreference,
    Gender? gender,
    TimeOfDay? sleepTime,
    TimeOfDay? wakeupTime,
    bool? hasDiabetes,
    bool? isSkinnyFat,
    bool? hasProteinDeficiency,
    bool? hasHighBloodPressure,
    bool? hasHighCholesterol,
    bool? isUnderweight,
    bool? hasAnxiety,
    bool? hasLowEnergyLevels,
    List<String>? allergies,
    String? activityLevel,
    int? dailyWaterGoal,
    int? dailyStepGoal,
    int? dailyCalorieGoal,
    int? sleepGoalHours,
    int? todaySteps,
    DateTime? memberSince,
    String? profilePicturePath,
    bool? waterReminderEnabled,
    bool? morningWalkReminderEnabled,
    bool? wakeupNotificationEnabled,
    bool? sleepNotificationEnabled,
    bool? prefersCoffee,
    bool? prefersTea,
    int? level,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmr: bmr ?? this.bmr,
      dietPreference: dietPreference ?? this.dietPreference,
      gender: gender ?? this.gender,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeupTime: wakeupTime ?? this.wakeupTime,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      isSkinnyFat: isSkinnyFat ?? this.isSkinnyFat,
      hasProteinDeficiency: hasProteinDeficiency ?? this.hasProteinDeficiency,
      hasHighBloodPressure: hasHighBloodPressure ?? this.hasHighBloodPressure,
      hasHighCholesterol: hasHighCholesterol ?? this.hasHighCholesterol,
      isUnderweight: isUnderweight ?? this.isUnderweight,
      hasAnxiety: hasAnxiety ?? this.hasAnxiety,
      hasLowEnergyLevels: hasLowEnergyLevels ?? this.hasLowEnergyLevels,
      allergies: allergies ?? this.allergies,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      todaySteps: todaySteps ?? this.todaySteps,
      memberSince: memberSince ?? this.memberSince,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      waterReminderEnabled: waterReminderEnabled ?? this.waterReminderEnabled,
      morningWalkReminderEnabled: morningWalkReminderEnabled ?? this.morningWalkReminderEnabled,
      wakeupNotificationEnabled: wakeupNotificationEnabled ?? this.wakeupNotificationEnabled,
      sleepNotificationEnabled: sleepNotificationEnabled ?? this.sleepNotificationEnabled,
      prefersCoffee: prefersCoffee ?? this.prefersCoffee,
      prefersTea: prefersTea ?? this.prefersTea,
      level: level ?? this.level,
    );
  }
}

