// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\edit_health_info_dialog.dart

// lib/features/profile/widgets/edit_health_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/user_data_provider.dart';
import 'health_components/allergies_question.dart';
import 'health_components/boolean_question.dart';
import 'health_components/health_data_manager.dart';
import 'health_components/health_questions_provider.dart';
import 'health_components/question_navigator.dart';

class EditHealthInfoDialog extends StatefulWidget {
  const EditHealthInfoDialog({super.key});

  @override
  State<EditHealthInfoDialog> createState() => _EditHealthInfoDialogState();
}

class _EditHealthInfoDialogState extends State<EditHealthInfoDialog> {
  late HealthData _healthData;
  int _currentQuestionIndex = 0;
  final List<String> _questionTitles = HealthQuestionsProvider.getQuestionTitles();

  @override
  void initState() {
    super.initState();
    _healthData = HealthDataManager.loadHealthData(context);
  }

  void _goToNextQuestion() {
    if (mounted) {
      setState(() {
        if (_currentQuestionIndex < _questionTitles.length - 1) {
          _currentQuestionIndex++;
        } else {
          _saveChanges();
        }
      });
    }
  }

  void _goToPreviousQuestion() {
    if (mounted) {
      setState(() {
        if (_currentQuestionIndex > 0) _currentQuestionIndex--;
      });
    }
  }

  void _saveChanges() async {
    await HealthDataManager.saveHealthData(
      context: context,
      hasDiabetes: _healthData.hasDiabetes,
      isSkinnyFat: _healthData.isSkinnyFat,
      hasProteinDeficiency: _healthData.hasProteinDeficiency,
      allergies: _healthData.allergies,
    );

    if (mounted) {
      Navigator.pop(context);
      HealthDataManager.showSuccessMessage(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigator = QuestionNavigator(
      currentIndex: _currentQuestionIndex,
      totalQuestions: _questionTitles.length,
      onNext: _goToNextQuestion,
      onPrevious: _goToPreviousQuestion,
      onSave: _saveChanges,
    );

    return AlertDialog(
      title: Text(navigator.getDialogTitle()),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.3,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: _buildQuestionContent(context),
        ),
      ),
      actions: navigator.buildNavigationActions(context),
    );
  }

  Widget _buildQuestionContent(BuildContext context) {
    final questions = HealthQuestionsProvider.getQuestions();
    final userData = Provider.of<UserDataProvider>(context, listen: false).userData;
    
    // Skip questions that shouldn't be shown based on gender
    if (_currentQuestionIndex < questions.length &&
        !questions[_currentQuestionIndex].shouldShow(userData.gender)) {
      _goToNextQuestion();
      return const SizedBox.shrink();
    }

    switch (_currentQuestionIndex) {
      case 0:
        return BooleanQuestion(
          question: questions[0].question,
          description: questions[0].description,
          currentValue: _healthData.hasDiabetes,
          onChanged: (value) {
            if (mounted) setState(() => _healthData.hasDiabetes = value);
          },
          questionIcon: questions[0].icon,
        );
      case 1:
        return BooleanQuestion(
          question: questions[1].question,
          description: questions[1].description,
          currentValue: _healthData.isSkinnyFat,
          onChanged: (value) {
            if (mounted) setState(() => _healthData.isSkinnyFat = value);
          },
          questionIcon: questions[1].icon,
        );
      case 2:
        return BooleanQuestion(
          question: questions[2].question,
          description: questions[2].description,
          currentValue: _healthData.hasProteinDeficiency,
          onChanged: (value) {
            if (mounted) setState(() => _healthData.hasProteinDeficiency = value);
          },
          questionIcon: questions[2].icon,
        );
      case 3:
        return AllergiesQuestion(
          allergies: _healthData.allergies,
          onAllergiesChanged: (allergies) {
            if (mounted) setState(() => _healthData.allergies = allergies);
          },
        );
      default:
        return const Text('Error: Unknown question index.');
    }
  }
}
