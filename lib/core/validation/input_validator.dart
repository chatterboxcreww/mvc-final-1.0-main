// lib/core/validation/input_validator.dart

import 'package:flutter/material.dart';
import '../models/user_data.dart';

/// Simple input validation system
class InputValidator {
  // Validation constants
  static const int minAge = 13;
  static const int maxAge = 120;
  static const double minHeight = 50.0;
  static const double maxHeight = 300.0;
  static const double minWeight = 20.0;
  static const double maxWeight = 500.0;

  /// Validate name
  static ValidationResult validateName(String? name) {
    final errors = <String, String>{};

    if (name == null || name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Name must be at least 2 characters long';
    } else if (name.trim().length > 50) {
      errors['name'] = 'Name must be less than 50 characters';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate email
  static ValidationResult validateEmail(String email) {
    final errors = <String, String>{};

    if (email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!email.contains('@') || !email.contains('.')) {
      errors['email'] = 'Please enter a valid email address';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate age
  static ValidationResult validateAge(int age) {
    final errors = <String, String>{};

    if (age < minAge) {
      errors['age'] = 'You must be at least $minAge years old';
    } else if (age > maxAge) {
      errors['age'] = 'Age must be less than $maxAge years';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate height
  static ValidationResult validateHeight(double height) {
    final errors = <String, String>{};

    if (height < minHeight) {
      errors['height'] = 'Height must be at least $minHeight cm';
    } else if (height > maxHeight) {
      errors['height'] = 'Height must be less than $maxHeight cm';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate weight
  static ValidationResult validateWeight(double weight) {
    final errors = <String, String>{};

    if (weight < minWeight) {
      errors['weight'] = 'Weight must be at least $minWeight kg';
    } else if (weight > maxWeight) {
      errors['weight'] = 'Weight must be less than $maxWeight kg';
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
    final sleepHours = sleepDurationMinutes / 60;
    if (sleepHours < 3) {
      errors['sleepSchedule'] = 'Sleep duration is too short (less than 3 hours)';
    } else if (sleepHours > 14) {
      errors['sleepSchedule'] = 'Sleep duration is too long (more than 14 hours)';
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Sanitize user input
  static String sanitizeInput(String input) {
    return input.trim();
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  ValidationResult({
    required this.isValid,
    this.errors = const {},
  });

  /// Get first error message
  String? get firstError => errors.isNotEmpty ? errors.values.first : null;

  /// Get all error messages
  List<String> get allErrors => errors.values.toList();

  /// Check if has specific error
  bool hasError(String field) => errors.containsKey(field);

  /// Get error for specific field
  String? getError(String field) => errors[field];

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: $errors)';
  }
}