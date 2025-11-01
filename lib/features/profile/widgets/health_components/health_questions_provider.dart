// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\health_components\health_questions_provider.dart

// lib/features/profile/widgets/health_components/health_questions_provider.dart
import 'package:flutter/material.dart';

import '../../../../core/models/app_enums.dart';

/// Represents a health question with its metadata
class HealthQuestion {
  final String question;
  final String description;
  final IconData icon;
  final bool Function(Gender?) shouldShow;

  HealthQuestion({
    required this.question,
    required this.description,
    required this.icon,
    required this.shouldShow,
  });
}

/// Provides access to all health-related questions
class HealthQuestionsProvider {
  /// Returns a list of all question titles
  static List<String> getQuestionTitles() {
    return [
      'Diabetes',
      'Skinny Fat',
      'Protein Deficiency',
      'Allergies',
    ];
  }

  /// Returns a list of all health questions with their metadata
  static List<HealthQuestion> getQuestions() {
    return [
      // Diabetes Question
      HealthQuestion(
        question: 'Do you have diabetes?',
        description: 'Managing diabetes involves proper diet, regular exercise, and monitoring blood sugar levels.',
        icon: Icons.medical_services_outlined,
        shouldShow: (_) => true, // Show for all genders
      ),
      
      // Skinny Fat Question
      HealthQuestion(
        question: 'Do you have a skinny fat body composition (low muscle mass despite normal weight)?',
        description: 'Improve body composition with strength training and adequate protein intake.',
        icon: Icons.fitness_center_outlined,
        shouldShow: (_) => true, // Show for all genders
      ),
      
      // Protein Deficiency Question
      HealthQuestion(
        question: 'Do you have protein deficiency?',
        description: 'Ensure adequate protein intake through lean meats, legumes, dairy, and protein supplements if needed.',
        icon: Icons.restaurant_outlined,
        shouldShow: (_) => true, // Show for all genders
      ),
    ];
  }
}
