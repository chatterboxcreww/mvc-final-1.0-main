// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\health_components\question_navigator.dart

// lib/features/profile/widgets/health_components/question_navigator.dart
import 'package:flutter/material.dart';

class QuestionNavigator {
  final int currentIndex;
  final int totalQuestions;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSave;

  QuestionNavigator({
    required this.currentIndex,
    required this.totalQuestions,
    required this.onNext,
    required this.onPrevious,
    required this.onSave,
  });

  /// Returns the formatted dialog title with current question index
  String getDialogTitle() {
    return 'Edit Health Info (${currentIndex + 1}/$totalQuestions)';
  }

  /// Determines if this is the last question
  bool get isLastQuestion => currentIndex == totalQuestions - 1;

  /// Builds the navigation action buttons for the dialog
  List<Widget> buildNavigationActions(BuildContext context) {
    return [
      if (currentIndex > 0)
        TextButton(
          onPressed: onPrevious,
          child: const Text('Back'),
        ),
      const Spacer(),
      ElevatedButton(
        onPressed: onNext,
        child: Text(isLastQuestion ? 'Save Changes' : 'Next'),
      ),
    ];
  }

  /// Returns the appropriate button text based on current position
  String getNextButtonText() {
    return isLastQuestion ? 'Save Changes' : 'Next';
  }

  /// Returns the appropriate action based on current position
  VoidCallback getNextAction() {
    return isLastQuestion ? onSave : onNext;
  }
}
