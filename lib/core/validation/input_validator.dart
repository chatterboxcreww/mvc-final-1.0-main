// lib/core/validation/input_validator.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_data.dart';
import '../models/daily_checkin_data.dart';

/// Comprehensive input validation system for user data and app inputs
class InputValidator {
  // Regular expressions for validation
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z\s\-\'\.]{1,50}$');
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,15}$');
  static final RegExp _alphanumericRegex = RegExp(r'^[a-zA-Z0-9\s]{1,100}$');
  
  // Validation constants
  static const int _minAge = 13;
  static const int _maxAge = 120;
  static const double _minHeight = 50.0; // cm
  static const double _maxHeight = 300.0; // cm
  static const double _minWeight = 20.0; // kg
  static const double _maxWeight = 500.0; // kg
  static const int _minStepGoal = 1000;
  static const int _maxStepGoal = 50000;
  static const int _minWaterGoal = 1;
  static const int _maxWaterGoal = 20;
  static const int _maxNameLength = 50;
  static const int _maxCommentLength = 500;

  /// Validate user data comprehensively
  static ValidationResult validateUserData(UserData userData) {
    final errors = <String, String>{};
    final warnings = <String, String>{};

    // Validate name
    final nameResult = validateName(userData.name);
    if (!nameResult.isValid) {
      errors['name'] = nameResult.errors['name'] ?? 'Invalid name';
    }

    // Validate email if provided
    if (userData.email != null && userData.email!.isNotEmpty) {
      final emailResult = validateEmail(userData.email!);
      if (!emailResult.isValid) {
        errors['email'] = emailResult.errors['email'] ?? 'Invalid email';
      }
    }

    // Validate age
    if (userData.age != null) {
      final ageResult = validateAge(userData.age!);
      if (!ageResult.isValid) {
        errors['age'] = ageResult.errors['age'] ?? 'Invalid age';
      } else if (userData.age! < 18) {
        warnings['age'] = 'Users under 18 have limited features available';
      }
    }

    // Validate height
    if (userData.height != null) {
      final heightResult = validateHeight(userData.height!);
      if (!heightResult.isValid) {
        errors['height'] = heightResult.errors['height'] ?? 'Invalid height';
      }
    }

    // Validate weight
    if (userData.weight != null) {
      final weightResult = validateWeight(userData.weight!);
      if (!weightResult.isValid) {
        errors['weight'] = weightResult.errors['weight'] ?? 'Invalid weight';
      }
    }

    // Validate step goal
    if (userData.dailyStepGoal != null) {
      final stepGoalResult = validateStepGoal(userData.dailyStepGoal!);
      if (!stepGoalResult.isValid) {
        errors['dailyStepGoal'] = stepGoalResult.errors['stepGoal'] ?? 'Invalid step goal';
      }
    }

    // Validate water goal
    if (userData.dailyWaterGoal != null) {
      final waterGoalResult = validateWaterGoal(userData.dailyWaterGoal!);
      if (!waterGoalResult.isValid) {
        errors['dailyWaterGoal'] = waterGoalResult.errors['waterGoal'] ?? 'Invalid water goal';
      }
    }

    // Validate sleep schedule
    if (userData.sleepTime != null && userData.wakeupTime != null) {
      final sleepResult = validateSleepSchedule(userData.sleepTime!, userData.wakeupTime!);
      if (!sleepResult.isValid) {
        errors['sleepSchedule'] = sleepResult.errors['sleepSchedule'] ?? 'Invalid sleep schedule';
      }
    }

    // Validate allergies
    if (userData.allergies != null && userData.allergies!.isNotEmpty) {
      final allergiesResult = validateAllergies(userData.allergies!);
      if (!allergiesResult.isValid) {
        errors['allergies'] = allergiesResult.errors['allergies'] ?? 'Invalid allergies';
      }
    }

    // Cross-field validation
    if (userData.height != null && userData.weight != null) {
      final bmi = userData.bmi;
      if (bmi != null) {
        if (bmi < 15.0 || bmi > 50.0) {
          warnings['bmi'] = 'BMI value seems unusual. Please verify height and weight.';
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate name
  static ValidationResult validateName(String? name) {
    final errors = <String, String>{};

    if (name == null || name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    } else {
      final trimmedName = name.trim();
      
      if (trimmedName.length > _maxNameLength) {
        errors['name'] = 'Name must be less than $_maxNameLength characters';
      } else if (!_nameRegex.hasMatch(trimmedName)) {
        errors['name'] = 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
      } else if (trimmedName.length < 2) {
        errors['name'] = 'Name must be at least 2 characters long';
      } else if (_containsProfanity(trimmedName)) {
        errors['name'] = 'Name contains inappropriate content';
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate email
  static ValidationResult validateEmail(String email) {
    final errors = <String, String>{};

    if (email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!_emailRegex.hasMatch(email.trim())) {
      errors['email'] = 'Please enter a valid email address';
    } else if (email.length > 254) {
      errors['email'] = 'Email address is too long';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate age
  static ValidationResult validateAge(int age) {
    final errors = <String, String>{};

    if (age < _minAge) {
      errors['age'] = 'You must be at least $_minAge years old to use this app';
    } else if (age > _maxAge) {
      errors['age'] = 'Age must be less than $_maxAge years';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate height
  static ValidationResult validateHeight(double height) {
    final errors = <String, String>{};

    if (height < _minHeight) {
      errors['height'] = 'Height must be at least $_minHeight cm';
    } else if (height > _maxHeight) {
      errors['height'] = 'Height must be less than $_maxHeight cm';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate weight
  static ValidationResult validateWeight(double weight) {
    final errors = <String, String>{};

    if (weight < _minWeight) {
      errors['weight'] = 'Weight must be at least $_minWeight kg';
    } else if (weight > _maxWeight) {
      errors['weight'] = 'Weight must be less than $_maxWeight kg';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate step goal
  static ValidationResult validateStepGoal(int stepGoal) {
    final errors = <String, String>{};

    if (stepGoal < _minStepGoal) {
      errors['stepGoal'] = 'Step goal must be at least $_minStepGoal steps';
    } else if (stepGoal > _maxStepGoal) {
      errors['stepGoal'] = 'Step goal must be less than $_maxStepGoal steps';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate water goal
  static ValidationResult validateWaterGoal(int waterGoal) {
    final errors = <String, String>{};

    if (waterGoal < _minWaterGoal) {
      errors['waterGoal'] = 'Water goal must be at least $_minWaterGoal glass';
    } else if (waterGoal > _maxWaterGoal) {
      errors['waterGoal'] = 'Water goal must be less than $_maxWaterGoal glasses';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate sleep schedule
  static ValidationResult validateSleepSchedule(TimeOfDay sleepTime, TimeOfDay wakeupTime) {
    final errors = <String, String>{};

    // Convert to minutes for easier comparison
    final sleepMinutes = sleepTime.hour * 60 + sleepTime.minute;
    final wakeupMinutes = wakeupTime.hour * 60 + wakeupTime.minute;

    // Calculate sleep duration accounting for overnight sleep
    int sleepDurationMinutes;
    if (wakeupMinutes < sleepMinutes) {
      // Sleep crosses midnight
      sleepDurationMinutes = (24 * 60 - sleepMinutes) + wakeupMinutes;
    } else {
      sleepDurationMinutes = wakeupMinutes - sleepMinutes;
    }

    // Check if sleep duration is reasonable (between 3 and 14 hours)
    if (sleepDurationMinutes < 180) {
      errors['sleepSchedule'] = 'Sleep duration is too short (less than 3 hours)';
    } else if (sleepDurationMinutes > 840) {
      errors['sleepSchedule'] = 'Sleep duration is too long (more than 14 hours)';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate allergies list
  static ValidationResult validateAllergies(List<String> allergies) {
    final errors = <String, String>{};

    if (allergies.length > 20) {
      errors['allergies'] = 'Too many allergies listed (maximum 20)';
    } else {
      for (int i = 0; i < allergies.length; i++) {
        final allergy = allergies[i].trim();
        if (allergy.isEmpty) {
          errors['allergies'] = 'Empty allergy entry found';
          break;
        } else if (allergy.length > 50) {
          errors['allergies'] = 'Allergy name too long (maximum 50 characters)';
          break;
        } else if (!_alphanumericRegex.hasMatch(allergy)) {
          errors['allergies'] = 'Allergy names can only contain letters, numbers, and spaces';
          break;
        }
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate daily checkin data
  static ValidationResult validateDailyCheckinData(DailyCheckinData checkinData) {
    final errors = <String, String>{};

    // Validate mood (1-5 scale)
    if (checkinData.mood < 1 || checkinData.mood > 5) {
      errors['mood'] = 'Mood must be between 1 and 5';
    }

    // Validate water intake
    if (checkinData.waterIntake < 0 || checkinData.waterIntake > 30) {
      errors['waterIntake'] = 'Water intake must be between 0 and 30 glasses';
    }

    // Validate weight
    if (checkinData.weight < 0 || checkinData.weight > 1000) {
      errors['weight'] = 'Weight must be between 0 and 1000 kg';
    }

    // Validate sleep hours
    if (checkinData.sleepHours < 0 || checkinData.sleepHours > 24) {
      errors['sleepHours'] = 'Sleep hours must be between 0 and 24';
    }

    // Validate meal count
    if (checkinData.mealCount < 0 || checkinData.mealCount > 10) {
      errors['mealCount'] = 'Meal count must be between 0 and 10';
    }

    // Validate meditation minutes
    if (checkinData.meditationMinutes < 0 || checkinData.meditationMinutes > 1440) {
      errors['meditationMinutes'] = 'Meditation minutes must be between 0 and 1440 (24 hours)';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate comment text
  static ValidationResult validateComment(String comment) {
    final errors = <String, String>{};

    if (comment.trim().isEmpty) {
      errors['comment'] = 'Comment cannot be empty';
    } else if (comment.length > _maxCommentLength) {
      errors['comment'] = 'Comment must be less than $_maxCommentLength characters';
    } else if (_containsProfanity(comment)) {
      errors['comment'] = 'Comment contains inappropriate content';
    } else if (_containsSpam(comment)) {
      errors['comment'] = 'Comment appears to be spam';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate step count input
  static ValidationResult validateStepCount(int steps) {
    final errors = <String, String>{};

    if (steps < 0) {
      errors['steps'] = 'Step count cannot be negative';
    } else if (steps > 100000) {
      errors['steps'] = 'Step count seems unrealistic (maximum 100,000 per day)';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate water glass count
  static ValidationResult validateWaterGlassCount(int glasses) {
    final errors = <String, String>{};

    if (glasses < 0) {
      errors['waterGlasses'] = 'Water glass count cannot be negative';
    } else if (glasses > 30) {
      errors['waterGlasses'] = 'Water glass count seems unrealistic (maximum 30 per day)';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Sanitize user input
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    String sanitized = input
        .replaceAll(RegExp(r'[<>"\']'), '') // Remove HTML/script characters
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control characters
        .trim();

    // Limit length
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }

    return sanitized;
  }

  /// Check for profanity (basic implementation)
  static bool _containsProfanity(String text) {
    // This is a basic implementation. In production, you'd use a comprehensive profanity filter
    final profanityWords = [
      'badword1', 'badword2', // Add actual profanity words
    ];

    final lowerText = text.toLowerCase();
    return profanityWords.any((word) => lowerText.contains(word));
  }

  /// Check for spam patterns
  static bool _containsSpam(String text) {
    // Basic spam detection
    final spamPatterns = [
      RegExp(r'(https?://|www\.)', caseSensitive: false), // URLs
      RegExp(r'(.)\1{4,}'), // Repeated characters
      RegExp(r'[A-Z]{10,}'), // Excessive caps
    ];

    return spamPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Validate JSON input
  static ValidationResult validateJsonInput(String jsonString) {
    final errors = <String, String>{};

    if (jsonString.trim().isEmpty) {
      errors['json'] = 'JSON input cannot be empty';
    } else {
      try {
        jsonDecode(jsonString);
      } catch (e) {
        errors['json'] = 'Invalid JSON format: ${e.toString()}';
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate file upload
  static ValidationResult validateFileUpload(String fileName, int fileSize) {
    final errors = <String, String>{};
    final maxFileSize = 5 * 1024 * 1024; // 5MB
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.pdf'];

    if (fileName.trim().isEmpty) {
      errors['file'] = 'File name cannot be empty';
    } else {
      final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
      if (!allowedExtensions.contains(extension)) {
        errors['file'] = 'File type not allowed. Allowed types: ${allowedExtensions.join(', ')}';
      }
    }

    if (fileSize > maxFileSize) {
      errors['file'] = 'File size too large. Maximum size: ${maxFileSize ~/ (1024 * 1024)}MB';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Batch validate multiple inputs
  static ValidationResult validateBatch(Map<String, dynamic> inputs) {
    final allErrors = <String, String>{};
    final allWarnings = <String, String>{};

    for (final entry in inputs.entries) {
      ValidationResult result;
      
      switch (entry.key) {
        case 'name':
          result = validateName(entry.value as String?);
          break;
        case 'email':
          result = validateEmail(entry.value as String);
          break;
        case 'age':
          result = validateAge(entry.value as int);
          break;
        case 'height':
          result = validateHeight(entry.value as double);
          break;
        case 'weight':
          result = validateWeight(entry.value as double);
          break;
        default:
          continue;
      }

      if (!result.isValid) {
        allErrors.addAll(result.errors);
      }
      allWarnings.addAll(result.warnings);
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
    );
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;
  final Map<String, String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    this.warnings = const {},
  });

  /// Get first error message
  String? get firstError => errors.values.isNotEmpty ? errors.values.first : null;

  /// Get all error messages
  List<String> get allErrors => errors.values.toList();

  /// Get all warning messages
  List<String> get allWarnings => warnings.values.toList();

  /// Check if has warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get formatted error message
  String get formattedErrors => errors.values.join('\n');

  /// Get formatted warning message
  String get formattedWarnings => warnings.values.join('\n');

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}

/// Validation rule class for custom validations
class ValidationRule<T> {
  final String name;
  final bool Function(T value) validator;
  final String errorMessage;

  ValidationRule({
    required this.name,
    required this.validator,
    required this.errorMessage,
  });

  ValidationResult validate(T value) {
    final isValid = validator(value);
    return ValidationResult(
      isValid: isValid,
      errors: isValid ? {} : {name: errorMessage},
    );
  }
}