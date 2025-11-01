// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\onboarding\screens\onboarding_beverage_questions_screen.dart

// lib/features/onboarding/screens/onboarding_beverage_questions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_data.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/screens/auth_wrapper.dart'; // Import the AuthWrapper

// _BeverageQuestionTemplate widget remains the same...
class _BeverageQuestionTemplate extends StatelessWidget {
  final String title;
  final String description;
  final bool? currentValue;
  final IconData choiceIcon;
  final ValueChanged<bool> onSelection;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isEditing;
  final bool isFinalQuestion;
  final String pageTitle;

  const _BeverageQuestionTemplate({
    required this.title,
    required this.description,
    required this.currentValue,
    required this.choiceIcon,
    required this.onSelection,
    required this.onNext,
    required this.onBack,
    required this.isEditing,
    required this.isFinalQuestion,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        leading: isEditing || Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChoiceButton(context, 'Yes',
                    isSelected: currentValue == true,
                    onTap: () => onSelection(true),
                    icon: choiceIcon),
                _buildChoiceButton(context, 'No',
                    isSelected: currentValue == false,
                    onTap: () => onSelection(false),
                    icon: Icons.no_drinks_outlined),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (Navigator.canPop(context))
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    label: const Text('Back'),
                    onPressed: onBack,
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: Icon(isFinalQuestion
                      ? Icons.check_circle_outline_rounded
                      : Icons.arrow_forward_ios_rounded),
                  label: Text(isFinalQuestion
                      ? (isEditing ? 'Save & Finish' : 'Finish Setup')
                      : (isEditing ? 'Save & Next' : 'Next')),
                  onPressed: currentValue != null ? onNext : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(BuildContext context, String text,
      {required bool isSelected,
        required VoidCallback onTap,
        required IconData icon}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            foregroundColor: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: isSelected ? 3 : 0,
          ),
          icon: Icon(icon),
          label: Text(text),
        ),
      ),
    );
  }
}


// OnboardingCoffeeQuestionScreen remains the same...
class OnboardingCoffeeQuestionScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingCoffeeQuestionScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingCoffeeQuestionScreen> createState() =>
      _OnboardingCoffeeQuestionScreenState();
}

class _OnboardingCoffeeQuestionScreenState
    extends State<OnboardingCoffeeQuestionScreen> {
  bool? _prefersCoffee;

  @override
  void initState() {
    super.initState();
    _prefersCoffee = context.read<UserDataProvider>().userData.prefersCoffee;
  }

  void _nextPage() async {
    final userDataProvider = context.read<UserDataProvider>();
    final updatedData = UserData.fromJson(userDataProvider.userData.toJson())
      ..prefersCoffee = _prefersCoffee;
    await userDataProvider.updateUserData(updatedData);

    if (mounted) {
      final nextRoute = MaterialPageRoute(
        settings: RouteSettings(
            name: 'OnboardingTeaQuestionScreen${widget.isEditing ? "_Edit" : ""}}'),
        builder: (context) =>
            OnboardingTeaQuestionScreen(isEditing: widget.isEditing),
      );
      if (widget.isEditing) {
        Navigator.of(context).pushReplacement(nextRoute);
      } else {
        Navigator.of(context).push(nextRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BeverageQuestionTemplate(
      title: 'Do you enjoy drinking coffee?',
      description: 'This helps us schedule relevant reminders for you.',
      currentValue: _prefersCoffee,
      choiceIcon: Icons.coffee_outlined,
      onSelection: (value) => setState(() => _prefersCoffee = value),
      onNext: _nextPage,
      onBack: () => Navigator.of(context).pop(),
      isEditing: widget.isEditing,
      isFinalQuestion: false,
      pageTitle: widget.isEditing
          ? 'Edit: Coffee Preference'
          : 'Beverage Preferences (1/2)',
    );
  }
}


// --- Tea Question Screen (Final Onboarding Screen) ---
class OnboardingTeaQuestionScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingTeaQuestionScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingTeaQuestionScreen> createState() =>
      _OnboardingTeaQuestionScreenState();
}

class _OnboardingTeaQuestionScreenState
    extends State<OnboardingTeaQuestionScreen> {
  bool? _prefersTea;

  @override
  void initState() {
    super.initState();
    _prefersTea = context.read<UserDataProvider>().userData.prefersTea;
  }

  // This is the final step. It saves all data and handles navigation.
  void _finishOnboarding() async {
    final userDataProvider = context.read<UserDataProvider>();
    final updatedData = UserData.fromJson(userDataProvider.userData.toJson())
      ..prefersTea = _prefersTea
      ..memberSince = userDataProvider.userData.memberSince ?? DateTime.now();
    await userDataProvider.updateUserData(updatedData);

    // This is now the ONLY responsibility of this method after saving data:
    // 1. Mark onboarding as complete in local storage.
    // 2. Navigate to the AuthWrapper to let it handle the next step.
    if (!widget.isEditing) {
      await StorageService().setOnboardingComplete(true);
    }

    if (mounted) {
      // FIX: Always navigate to AuthWrapper to re-evaluate the state cleanly.
      // This solves the "stuck" screen issue.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BeverageQuestionTemplate(
      title: 'How about tea? Do you enjoy it?',
      description:
      'Knowing your beverage preferences helps in providing timely suggestions.',
      currentValue: _prefersTea,
      choiceIcon: Icons.emoji_food_beverage_outlined,
      onSelection: (value) => setState(() => _prefersTea = value),
      onNext: _finishOnboarding,
      onBack: () => Navigator.of(context).pop(),
      isEditing: widget.isEditing,
      isFinalQuestion: true,
      pageTitle: widget.isEditing
          ? 'Edit: Tea Preference'
          : 'Beverage Preferences (2/2)',
    );
  }
}
