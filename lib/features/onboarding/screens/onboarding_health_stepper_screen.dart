// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\onboarding\screens\onboarding_health_stepper_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/screens/auth_wrapper.dart';

class OnboardingHealthStepperScreen extends StatefulWidget {
  const OnboardingHealthStepperScreen({super.key, this.isEditing = false});
  final bool isEditing;

  @override
  State<OnboardingHealthStepperScreen> createState() =>
      _OnboardingHealthStepperScreenState();
}

class _OnboardingHealthStepperScreenState
    extends State<OnboardingHealthStepperScreen> {
  int _step = 0;
  bool _loading = false;
  bool _navigated = false;

  // health flags (only a subset shown for brevity)
  bool? _hasDiabetes, _isSkinnyFat, _hasProteinDeficiency;

  Future<void> _complete() async {
    if (_navigated) return;
    setState(() => _loading = true);

    final prov = context.read<UserDataProvider>();
    final ok = await prov.updateUserData(
      prov.userData.copyWith(
        hasDiabetes: _hasDiabetes,
        isSkinnyFat: _isSkinnyFat,
        hasProteinDeficiency: _hasProteinDeficiency,
      ),
      isOnboarding: true, // Immediate Firebase sync during onboarding
    );

    if (!mounted) return;
    if (ok) {
      _navigated = true;
      await StorageService().setOnboardingComplete(true);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (_) => false,
      );
    } else {
      _error('Save failed. Try again');
    }
    setState(() => _loading = false);
  }

  void _error(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title:
      Text(widget.isEditing ? 'Edit Health Info' : 'Health Information'),
    ),
    body: Stepper(
      currentStep: _step,
      onStepTapped: (s) => setState(() => _step = s),
      onStepContinue: () {
        if (_step < 2) {
          setState(() => _step++);
        } else {
          _complete();
        }
      },
      onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
      controlsBuilder: (ctx, details) => Row(
        children: [
          if (_step < 2)
            ElevatedButton(
              onPressed: details.onStepContinue,
              child: const Text('Next'),
            ),
          if (_step == 2)
            ElevatedButton(
              onPressed: _loading ? null : _complete,
              child: _loading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(widget.isEditing ? 'Save' : 'Finish'),
            ),
          const SizedBox(width: 8),
          if (_step > 0)
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Back'),
            ),
        ],
      ),
      steps: [
        Step(
          title: const Text('Diabetes'),
          content: CheckboxListTile(
            title: const Text('Do you have diabetes?'),
            value: _hasDiabetes,
            tristate: true,
            onChanged: (v) => setState(() => _hasDiabetes = v),
          ),
        ),
        Step(
          title: const Text('Body Composition'),
          content: CheckboxListTile(
            title: const Text('Do you have skinny fat?'),
            value: _isSkinnyFat,
            tristate: true,
            onChanged: (v) => setState(() => _isSkinnyFat = v),
          ),
        ),
        Step(
          title: const Text('Nutrition'),
          content: CheckboxListTile(
            title: const Text('Do you have protein deficiency?'),
            value: _hasProteinDeficiency,
            tristate: true,
            onChanged: (v) => setState(() => _hasProteinDeficiency = v),
          ),
        ),
      ],
    ),
  );
}

