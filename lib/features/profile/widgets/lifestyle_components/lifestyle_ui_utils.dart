// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\lifestyle_components\lifestyle_ui_utils.dart

// lib/features/profile/widgets/lifestyle_components/lifestyle_ui_utils.dart
import 'package:flutter/material.dart';
import '../../../../core/models/app_enums.dart';

/// Utility class for lifestyle dialog UI components
class LifestyleUIUtils {
  /// Returns a button style for toggle buttons (Yes/No)
  static ButtonStyle getToggleButtonStyle(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      foregroundColor: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  /// Returns a button style for selectable option buttons
  static ButtonStyle getSelectableButtonStyle(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      foregroundColor: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );
  }

  /// Returns an icon for diet preference
  static Icon getDietIcon(BuildContext context, DietPreference diet) {
    Color iconColor = Theme.of(context).colorScheme.onPrimaryContainer;
    switch (diet) {
      case DietPreference.vegetarian:
        return Icon(Icons.eco_outlined, color: iconColor);
      case DietPreference.nonVegetarian:
        return Icon(Icons.kebab_dining_outlined, color: iconColor);
      case DietPreference.vegan:
        return Icon(Icons.spa_outlined, color: iconColor);
      case DietPreference.pescatarian:
        return Icon(Icons.set_meal_outlined, color: iconColor);
    }
  }

  /// Returns an icon for gender
  static Icon getGenderIcon(BuildContext context, Gender gender) {
    Color iconColor = Theme.of(context).colorScheme.onPrimaryContainer;
    switch (gender) {
      case Gender.male:
        return Icon(Icons.male_rounded, color: iconColor);
      case Gender.female:
        return Icon(Icons.female_rounded, color: iconColor);
      case Gender.other:
        return Icon(Icons.transgender_rounded, color: iconColor);
    }
  }
}
