// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\lifestyle_components\gender_selection_section.dart

// lib/features/profile/widgets/lifestyle_components/gender_selection_section.dart
import 'package:flutter/material.dart';
import '../../../../core/models/app_enums.dart';
import '../../../../shared/utils/extensions.dart';
import 'lifestyle_ui_utils.dart';

/// A widget that displays gender selection options
class GenderSelectionSection extends StatelessWidget {
  final Gender? selectedGender;
  final ValueChanged<Gender> onGenderChanged;

  const GenderSelectionSection({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: Gender.values.map((gender) {
            bool isSelected = selectedGender == gender;
            return ElevatedButton.icon(
              onPressed: () => onGenderChanged(gender),
              icon: LifestyleUIUtils.getGenderIcon(context, gender),
              label: Text(gender.name.capitalize()),
              style: LifestyleUIUtils.getSelectableButtonStyle(context, isSelected),
            );
          }).toList(),
        ),
      ],
    );
  }
}
