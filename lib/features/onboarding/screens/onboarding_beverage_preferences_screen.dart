// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\onboarding\screens\onboarding_beverage_preferences_screen.dart

// lib/features/onboarding/screens/onboarding_beverage_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_data.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/glass_container.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../../home/screens/home_page.dart';

class OnboardingBeveragePreferencesScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingBeveragePreferencesScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingBeveragePreferencesScreen> createState() => _OnboardingBeveragePreferencesScreenState();
}

class _OnboardingBeveragePreferencesScreenState extends State<OnboardingBeveragePreferencesScreen> {
  bool? _prefersCoffee;
  bool? _prefersTea;
  
  // Error handling
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userData = Provider.of<UserDataProvider>(context, listen: false).userData;
    _prefersCoffee = userData.prefersCoffee;
    _prefersTea = userData.prefersTea;
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userDataProvider =
        Provider.of<UserDataProvider>(context, listen: false);
    final updatedData = UserData.fromJson(userDataProvider.userData.toJson())
      ..prefersCoffee = _prefersCoffee
      ..prefersTea = _prefersTea
      ..memberSince = userDataProvider.userData.memberSince ?? DateTime.now();

    // Validate data before saving
    Map<String, String> validationErrors = updatedData.validate();
    if (validationErrors.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = validationErrors.values.join('\n');
      });
      _showErrorDialog(_errorMessage!);
      return;
    }

    // FIRST TIME ONBOARDING: Save to Firestore first, then local storage
    try {
      // Save to Firestore first (initial onboarding)
      // Update with immediate Firebase sync (isOnboarding flag handles both local and Firebase)
      bool success = await userDataProvider.updateUserData(updatedData, isOnboarding: true);
      
      if (!success) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = userDataProvider.lastError;
          });
          _showErrorDialog(_errorMessage ?? 'Failed to update user data');
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save to cloud: $e';
        });
        _showErrorDialog('Failed to save your data to the cloud. Please check your internet connection and try again.');
      }
      return;
    }

    // Onboarding is now complete, navigate directly to the home page.
    if (mounted) {
      // Also mark onboarding as complete in local storage for persistence.
      await StorageService().setOnboardingComplete(true);

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(), // Navigate directly to HomePage
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
        (route) => false,
      );
    }
  }
  
  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    // For progress indicator
    const int totalSteps = 4; // Personal Info, Lifestyle, Health, Allergies & Beverages
    const int currentProgressStep = 4; // Beverages is the fourth major step
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Beverage Preferences' : 'Beverage Preferences'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const OnboardingProgressIndicator(
              currentStep: currentProgressStep,
              totalSteps: totalSteps,
              stepLabels: ['Personal', 'Lifestyle', 'Health', 'Preferences'],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beverage Preferences',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These preferences help us provide timely reminders and personalized suggestions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Coffee preference card
                    _buildBeverageCard(
                      title: 'Do you enjoy drinking coffee?',
                      icon: Icons.coffee_outlined,
                      currentValue: _prefersCoffee,
                      onChanged: (value) => setState(() => _prefersCoffee = value),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tea preference card
                    _buildBeverageCard(
                      title: 'Do you enjoy drinking tea?',
                      icon: Icons.emoji_food_beverage_outlined,
                      currentValue: _prefersTea,
                      onChanged: (value) => setState(() => _prefersTea = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (Navigator.canPop(context))
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    label: const Text('Back'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                const Spacer(),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  ),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(widget.isEditing ? 'Save & Finish' : 'Complete Setup'),
                  onPressed: (_prefersCoffee != null && _prefersTea != null && !_isLoading)
                      ? _finishOnboarding
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeverageCard({
    required String title,
    required IconData icon,
    required bool? currentValue,
    required ValueChanged<bool> onChanged,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceButton(
                    context: context,
                    text: 'Yes',
                    isSelected: currentValue == true,
                    onTap: () => onChanged(true),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceButton(
                    context: context,
                    text: 'No',
                    isSelected: currentValue == false,
                    onTap: () => onChanged(false),
                    icon: Icons.highlight_off_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? colorScheme.primary
            : colorScheme.surface,
        foregroundColor: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 2 : 0,
      ),
      icon: Icon(icon),
      label: Text(text),
    );
  }
}
