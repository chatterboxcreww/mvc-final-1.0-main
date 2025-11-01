// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\lifestyle_components\diet_preference_section.dart

// lib/features/profile/widgets/lifestyle_components/diet_preference_section.dart
import 'package:flutter/material.dart';
import '../../../../core/models/app_enums.dart';
import '../../../../shared/utils/extensions.dart';
import 'lifestyle_ui_utils.dart';

/// A widget that displays diet preference selection options
class DietPreferenceSection extends StatelessWidget {
  final DietPreference? selectedDiet;
  final ValueChanged<DietPreference> onDietChanged;

  const DietPreferenceSection({
    super.key,
    required this.selectedDiet,
    required this.onDietChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diet Preference',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: DietPreference.values.map((diet) {
            bool isSelected = selectedDiet == diet;
            return ElevatedButton.icon(
              onPressed: () => onDietChanged(diet),
              icon: LifestyleUIUtils.getDietIcon(context, diet),
              label: Text(diet.name.capitalize()),
              style: LifestyleUIUtils.getSelectableButtonStyle(context, isSelected),
            );
          }).toList(),
        ),
      ],
    );
  }
}
