// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\lifestyle_components\beverage_preferences_section.dart

// lib/features/profile/widgets/lifestyle_components/beverage_preferences_section.dart
import 'package:flutter/material.dart';
import 'lifestyle_ui_utils.dart';

/// A widget that displays and manages beverage preference settings
class BeveragePreferencesSection extends StatelessWidget {
  final bool? prefersCoffee;
  final bool? prefersTea;
  final ValueChanged<bool?> onCoffeeChanged;
  final ValueChanged<bool?> onTeaChanged;

  const BeveragePreferencesSection({
    super.key,
    required this.prefersCoffee,
    required this.prefersTea,
    required this.onCoffeeChanged,
    required this.onTeaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow(
          context,
          'Do you drink coffee?',
          prefersCoffee,
          onCoffeeChanged,
          Icons.coffee,
          Icons.coffee_maker_outlined,
        ),
        const SizedBox(height: 20),
        _buildToggleRow(
          context,
          'Do you drink tea?',
          prefersTea,
          onTeaChanged,
          Icons.emoji_food_beverage,
          Icons.emoji_food_beverage_outlined,
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    BuildContext context,
    String title,
    bool? currentValue,
    ValueChanged<bool?> onChanged,
    IconData trueIcon,
    IconData falseIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(trueIcon),
                label: const Text('Yes'),
                onPressed: () => onChanged(true),
                style: LifestyleUIUtils.getToggleButtonStyle(context, currentValue == true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(falseIcon),
                label: const Text('No'),
                onPressed: () => onChanged(false),
                style: LifestyleUIUtils.getToggleButtonStyle(context, currentValue == false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
