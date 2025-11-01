// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\onboarding\screens\onboarding_health_questions_screen.dart

// lib/features/onboarding/screens/onboarding_health_questions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_data.dart';
import '../../../core/models/app_enums.dart';
import '../../../core/providers/user_data_provider.dart';
import 'onboarding_allergies_screen.dart';
import 'onboarding_beverage_preferences_screen.dart';

// A generic "question" widget to reduce code duplication
class _QuestionScreenTemplate extends StatelessWidget {
  final String title;
  final String description;
  final bool? currentValue;
  final ValueChanged<bool> onSelection;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isEditing;
  final String pageTitle;

  const _QuestionScreenTemplate({
    required this.title,
    required this.description,
    required this.currentValue,
    required this.onSelection,
    required this.onNext,
    required this.onBack,
    required this.isEditing,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top section with question
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        
                        // Middle section with choices
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            children: [
                              // Visual divider above choices
                              Divider(
                                color: colorScheme.outlineVariant,
                                thickness: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              const SizedBox(height: 24),
                              
                              // Yes/No buttons with improved spacing
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildChoiceButton(context, 'Yes',
                                      isSelected: currentValue == true,
                                      onTap: () => onSelection(true)),
                                  const SizedBox(width: 16), // Add space between buttons
                                  _buildChoiceButton(context, 'No',
                                      isSelected: currentValue == false,
                                      onTap: () => onSelection(false)),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              // Visual divider below choices
                              Divider(
                                color: colorScheme.outlineVariant,
                                thickness: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                            ],
                          ),
                        ),
                        
                        // Bottom section with navigation
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (Navigator.canPop(context))
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.arrow_back_ios_new),
                                  label: const Text('Back'),
                                  onPressed: onBack,
                                )
                              else
                                const SizedBox(width: 100), // Placeholder for spacing
                              
                              ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward_ios_rounded),
                                label: Text(isEditing ? 'Save & Next' : 'Next'),
                                onPressed: currentValue != null ? onNext : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChoiceButton(BuildContext context, String text,
      {required bool isSelected, required VoidCallback onTap}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Color.fromRGBO(colorScheme.shadow.red, colorScheme.shadow.green, colorScheme.shadow.blue, 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              foregroundColor: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // Increased vertical padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isSelected
                  ? BorderSide.none
                  : BorderSide(color: Color.fromRGBO(colorScheme.outline.red, colorScheme.outline.green, colorScheme.outline.blue, 0.3)),
              ),
              elevation: isSelected ? 4 : 1,
              minimumSize: const Size(120, 70), // Increased minimum height
            ),
            icon: Icon(
              text == 'Yes'
                  ? Icons.check_circle_outline_rounded
                  : Icons.highlight_off_rounded,
              size: 28, // Increased icon size
            ),
            label: Text(
              text,
              style: TextStyle(
                fontSize: 18, // Increased font size
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Diabetes Question Screen ---
class OnboardingDiabetesQuestionScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingDiabetesQuestionScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingDiabetesQuestionScreen> createState() =>
      _OnboardingDiabetesQuestionScreenState();
}

class _OnboardingDiabetesQuestionScreenState
    extends State<OnboardingDiabetesQuestionScreen> {
  bool? _hasDiabetes;

  @override
  void initState() {
    super.initState();
    _hasDiabetes =
        Provider.of<UserDataProvider>(context, listen: false).userData.hasDiabetes;
  }

  void _nextPage() async {
    final userDataProvider =
    Provider.of<UserDataProvider>(context, listen: false);
    final updatedData = UserData.fromJson(userDataProvider.userData.toJson())
      ..hasDiabetes = _hasDiabetes;
    await userDataProvider.updateUserData(updatedData);

    if (mounted) {
      final nextRoute = MaterialPageRoute(
        settings: RouteSettings(
            name: 'OnboardingSkinnyFatQuestionScreen${widget.isEditing ? "_Edit" : ""}}'),
        builder: (context) =>
            OnboardingSkinnyFatQuestionScreen(isEditing: widget.isEditing),
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
    return _QuestionScreenTemplate(
      title: 'Do you have diabetes?',
      description:
      'This information helps us tailor health advice. Diabetes is a chronic condition that affects how your body turns food into energy.',
      currentValue: _hasDiabetes,
      onSelection: (value) => setState(() => _hasDiabetes = value),
      onNext: _nextPage,
      onBack: () => Navigator.of(context).pop(),
      isEditing: widget.isEditing,
      pageTitle:
      widget.isEditing ? 'Edit: Diabetes Status' : 'Health Details (1/3)',
    );
  }
}

// --- Skinny Fat Question Screen ---
class OnboardingSkinnyFatQuestionScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingSkinnyFatQuestionScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingSkinnyFatQuestionScreen> createState() =>
      _OnboardingSkinnyFatQuestionScreenState();
}

class _OnboardingSkinnyFatQuestionScreenState
    extends State<OnboardingSkinnyFatQuestionScreen> {
  bool? _isSkinnyFat;

  @override
  void initState() {
    super.initState();
    _isSkinnyFat =
        Provider.of<UserDataProvider>(context, listen: false).userData.isSkinnyFat;
  }

  void _nextPage() async {
    final userDataProvider =
    Provider.of<UserDataProvider>(context, listen: false);
    final updatedData = UserData.fromJson(userDataProvider.userData.toJson())
      ..isSkinnyFat = _isSkinnyFat;
    await userDataProvider.updateUserData(updatedData);

    if (mounted) {
      final nextRoute = MaterialPageRoute(
        settings: RouteSettings(
            name:
            'OnboardingProteinDeficiencyQuestionScreen${widget.isEditing ? "_Edit" : ""}}'),
        builder: (context) =>
            OnboardingProteinDeficiencyQuestionScreen(isEditing: widget.isEditing),
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
    return _QuestionScreenTemplate(
      title: 'Do you consider yourself "skinny fat"?',
      description:
      'This typically means having a normal or low BMI but a higher body fat percentage and lower muscle mass.',
      currentValue: _isSkinnyFat,
      onSelection: (value) => setState(() => _isSkinnyFat = value),
      onNext: _nextPage,
      onBack: () => Navigator.of(context).pop(),
      isEditing: widget.isEditing,
      pageTitle:
      widget.isEditing ? 'Edit: Body Composition' : 'Health Details (2/3)',
    );
  }
}

// --- Protein Deficiency Question Screen ---
class OnboardingProteinDeficiencyQuestionScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingProteinDeficiencyQuestionScreen(
      {super.key, this.isEditing = false});

  @override
  State<OnboardingProteinDeficiencyQuestionScreen> createState() =>
      _OnboardingProteinDeficiencyQuestionScreenState();
}

class _OnboardingProteinDeficiencyQuestionScreenState
    extends State<OnboardingProteinDeficiencyQuestionScreen> {
  bool? _hasProteinDeficiency;

  @override
  void initState() {
    super.initState();
    _hasProteinDeficiency = Provider.of<UserDataProvider>(context, listen: false)
        .userData
        .hasProteinDeficiency;
  }

  void _nextPage() async {
    final userDataProvider =
    Provider.of<UserDataProvider>(context, listen: false);
    final updatedData = UserData.fromJson(userDataProvider.userData.toJson())
      ..hasProteinDeficiency = _hasProteinDeficiency;
    await userDataProvider.updateUserData(updatedData);

    if (mounted) {
      final nextRoute = MaterialPageRoute(
        settings: RouteSettings(
            name:
            'OnboardingBeveragePreferencesScreen${widget.isEditing ? "_Edit" : ""}}'),
        builder: (context) =>
            OnboardingBeveragePreferencesScreen(isEditing: widget.isEditing),
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
    return _QuestionScreenTemplate(
      title: 'Do you suspect a protein deficiency?',
      description:
      'Protein is essential for muscle repair, immune function, and overall wellness.',
      currentValue: _hasProteinDeficiency,
      onSelection: (value) => setState(() => _hasProteinDeficiency = value),
      onNext: _nextPage,
      onBack: () => Navigator.of(context).pop(),
      isEditing: widget.isEditing,
      pageTitle:
      widget.isEditing ? 'Edit: Protein Intake' : 'Health Details (3/3)',
    );
  }
}
