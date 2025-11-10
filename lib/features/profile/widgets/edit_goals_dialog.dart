// lib/features/profile/widgets/edit_goals_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_data.dart';
import '../../../core/providers/user_data_provider.dart';

class EditGoalsDialog extends StatefulWidget {
  const EditGoalsDialog({super.key});

  @override
  State<EditGoalsDialog> createState() => _EditGoalsDialogState();
}

class _EditGoalsDialogState extends State<EditGoalsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _stepGoalController;
  late TextEditingController _waterGoalController;
  late TextEditingController _sleepGoalController;

  @override
  void initState() {
    super.initState();
    final userData = Provider.of<UserDataProvider>(context, listen: false).userData;
    _stepGoalController = TextEditingController(text: (userData.dailyStepGoal ?? 10000).toString());
    _waterGoalController = TextEditingController(text: (userData.dailyWaterGoal ?? 8).toString());
    _sleepGoalController = TextEditingController(text: (userData.sleepGoalHours ?? 8).toString());
  }

  @override
  void dispose() {
    _stepGoalController.dispose();
    _waterGoalController.dispose();
    _sleepGoalController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
      final currentData = userDataProvider.userData;

      final updatedData = UserData.fromJson(currentData.toJson())
        ..dailyStepGoal = int.tryParse(_stepGoalController.text.trim())
        ..dailyWaterGoal = int.tryParse(_waterGoalController.text.trim())
        ..sleepGoalHours = int.tryParse(_sleepGoalController.text.trim());

      await userDataProvider.updateUserData(updatedData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.track_changes_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Edit Goals & Targets'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _stepGoalController,
                decoration: const InputDecoration(
                  labelText: 'Daily Step Goal',
                  prefixIcon: Icon(Icons.directions_walk),
                  suffixText: 'steps',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your step goal';
                  final steps = int.tryParse(value);
                  if (steps == null || steps < 1000 || steps > 50000) {
                    return 'Enter a value between 1,000 and 50,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _waterGoalController,
                decoration: const InputDecoration(
                  labelText: 'Daily Water Goal',
                  prefixIcon: Icon(Icons.water_drop),
                  suffixText: 'glasses',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your water goal';
                  final glasses = int.tryParse(value);
                  if (glasses == null || glasses < 1 || glasses > 20) {
                    return 'Enter a value between 1 and 20';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sleepGoalController,
                decoration: const InputDecoration(
                  labelText: 'Sleep Goal',
                  prefixIcon: Icon(Icons.bedtime),
                  suffixText: 'hours',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your sleep goal';
                  final hours = int.tryParse(value);
                  if (hours == null || hours < 4 || hours > 12) {
                    return 'Enter a value between 4 and 12';
                  }
                  return null;
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
