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
      'High Blood Pressure',
      'High Cholesterol',
      'Underweight',
      'Anxiety',
      'Low Energy Levels',
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
        icon: Icons.bloodtype_outlined,
        shouldShow: (_) => true,
      ),
      
      // High Blood Pressure Question
      HealthQuestion(
        question: 'Do you have high blood pressure (hypertension)?',
        description: 'Control blood pressure through diet, exercise, stress management, and medication if prescribed.',
        icon: Icons.favorite_outlined,
        shouldShow: (_) => true,
      ),
      
      // High Cholesterol Question
      HealthQuestion(
        question: 'Do you have high cholesterol?',
        description: 'Manage cholesterol with a heart-healthy diet, regular exercise, and medications if needed.',
        icon: Icons.monitor_heart_outlined,
        shouldShow: (_) => true,
      ),
      
      // Underweight Question
      HealthQuestion(
        question: 'Are you underweight?',
        description: 'Gain weight healthily through nutrient-dense foods, strength training, and regular meals.',
        icon: Icons.trending_up_outlined,
        shouldShow: (_) => true,
      ),
      
      // Anxiety Question
      HealthQuestion(
        question: 'Do you experience anxiety?',
        description: 'Manage anxiety through breathing exercises, mindfulness, therapy, and lifestyle changes.',
        icon: Icons.psychology_outlined,
        shouldShow: (_) => true,
      ),
      
      // Low Energy Levels Question
      HealthQuestion(
        question: 'Do you have low energy levels or chronic fatigue?',
        description: 'Boost energy through proper sleep, hydration, balanced nutrition, and regular exercise.',
        icon: Icons.battery_charging_full_outlined,
        shouldShow: (_) => true,
      ),
      
      // Skinny Fat Question
      HealthQuestion(
        question: 'Do you have a skinny fat body composition (low muscle mass despite normal weight)?',
        description: 'Improve body composition with strength training and adequate protein intake.',
        icon: Icons.fitness_center_outlined,
        shouldShow: (_) => true,
      ),
      
      // Protein Deficiency Question
      HealthQuestion(
        question: 'Do you have protein deficiency?',
        description: 'Ensure adequate protein intake through lean meats, legumes, dairy, and protein supplements if needed.',
        icon: Icons.food_bank_outlined,
        shouldShow: (_) => true,
      ),
    ];
  }
}
