// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\edit_lifestyle_dialog.dart

// lib/features/profile/widgets/edit_lifestyle_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_enums.dart';
import '../../../core/models/user_data.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/notification_service.dart';
import 'lifestyle_components/beverage_preferences_section.dart';
import 'lifestyle_components/diet_preference_section.dart';
import 'lifestyle_components/gender_selection_section.dart';
import 'lifestyle_components/notification_manager.dart';
import 'lifestyle_components/sleep_schedule_section.dart';
import 'lifestyle_components/step_goal_section.dart';

class EditLifestyleDialog extends StatefulWidget {
  const EditLifestyleDialog({super.key});

  @override
  State<EditLifestyleDialog> createState() => _EditLifestyleDialogState();
}

class _EditLifestyleDialogState extends State<EditLifestyleDialog> {
  final _formKey = GlobalKey<FormState>();
  DietPreference? _selectedDiet;
  Gender? _selectedGender;
  TimeOfDay? _selectedSleepTime;
  TimeOfDay? _selectedWakeupTime;
  bool? _prefersCoffee;
  bool? _prefersTea;
  late TextEditingController _stepGoalController;

  @override
  void initState() {
    super.initState();
    final userData = Provider.of<UserDataProvider>(context, listen: false).userData;
    _selectedDiet = userData.dietPreference;
    _selectedGender = userData.gender;
    _selectedSleepTime = userData.sleepTime;
    _selectedWakeupTime = userData.wakeupTime;
    _prefersCoffee = userData.prefersCoffee;
    _prefersTea = userData.prefersTea;
    _stepGoalController =
        TextEditingController(text: (userData.dailyStepGoal ?? 10000).toString());
  }

  @override
  void dispose() {
    _stepGoalController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, bool isSleepTime) async {
    final initialTime = isSleepTime
        ? (_selectedSleepTime ?? TimeOfDay.now())
        : (_selectedWakeupTime ?? TimeOfDay.now());
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      if (mounted) {
        setState(() {
          if (isSleepTime) {
            _selectedSleepTime = picked;
          } else {
            _selectedWakeupTime = picked;
          }
        });
      }
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userDataProvider =
    Provider.of<UserDataProvider>(context, listen: false);
    final currentData = userDataProvider.userData;

    final updatedData = UserData.fromJson(currentData.toJson())
      ..dietPreference = _selectedDiet
      ..gender = _selectedGender
      ..sleepTime = _selectedSleepTime
      ..wakeupTime = _selectedWakeupTime
      ..prefersCoffee = _prefersCoffee
      ..prefersTea = _prefersTea
      ..dailyStepGoal = int.tryParse(_stepGoalController.text.trim()) ?? 10000;

    await userDataProvider.updateUserData(updatedData);

    final notificationService = NotificationService();
    
    final success = await NotificationManager.updateNotifications(
      context,
      notificationService,
      updatedData
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lifestyle info updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Lifestyle & Preferences'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diet Preference Section
              DietPreferenceSection(
                selectedDiet: _selectedDiet,
                onDietChanged: (diet) {
                  if (mounted) setState(() => _selectedDiet = diet);
                },
              ),
              const SizedBox(height: 20),
              
              // Gender Selection Section
              GenderSelectionSection(
                selectedGender: _selectedGender,
                onGenderChanged: (gender) {
                  if (mounted) setState(() => _selectedGender = gender);
                },
              ),
              const SizedBox(height: 20),
              
              // Step Goal Section
              StepGoalSection(
                controller: _stepGoalController,
              ),
              const SizedBox(height: 20),
              
              // Sleep Schedule Section
              SleepScheduleSection(
                sleepTime: _selectedSleepTime,
                wakeupTime: _selectedWakeupTime,
                onTimePick: _pickTime,
              ),
              const SizedBox(height: 20),
              
              // Beverage Preferences Section
              BeveragePreferencesSection(
                prefersCoffee: _prefersCoffee,
                prefersTea: _prefersTea,
                onCoffeeChanged: (val) {
                  if (mounted) setState(() => _prefersCoffee = val);
                },
                onTeaChanged: (val) {
                  if (mounted) setState(() => _prefersTea = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
