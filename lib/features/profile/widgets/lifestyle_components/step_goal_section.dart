// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\lifestyle_components\step_goal_section.dart

// lib/features/profile/widgets/lifestyle_components/step_goal_section.dart
import 'package:flutter/material.dart';

/// A widget that displays and manages the daily step goal input
class StepGoalSection extends StatelessWidget {
  final TextEditingController controller;

  const StepGoalSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Step Goal',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Steps per day',
            prefixIcon: Icon(Icons.directions_walk_outlined),
          ),
          validator: (value) {
            if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
              return 'Enter a valid goal';
            }
            return null;
          },
        ),
      ],
    );
  }
}
