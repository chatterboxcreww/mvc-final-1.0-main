// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\diet_preferences_card.dart

// lib/features/home/widgets/profile_components/diet_preferences_card.dart
import 'package:flutter/material.dart';

import '../../../../core/models/user_data.dart';
import '../../../../core/models/app_enums.dart';
import '../../../../shared/utils/extensions.dart';
import 'profile_detail_widgets.dart';

class DietPreferencesCard extends StatelessWidget {
  final UserData userData;

  const DietPreferencesCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diet & Preferences',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Divider(height: 20, thickness: 1, color: colorScheme.outline),
            ProfileDetailRow(
              label: 'Diet',
              value: userData.dietPreference?.name.capitalize(),
              icon: Icons.restaurant_menu_outlined,
            ),
            ProfileCheckmarkRow(
              label: 'Prefers Coffee',
              value: userData.prefersCoffee,
              icon: Icons.coffee_outlined,
            ),
            ProfileCheckmarkRow(
              label: 'Prefers Tea',
              value: userData.prefersTea,
              icon: Icons.emoji_food_beverage_outlined,
            ),
            const SizedBox(height: 10),
            Text('Gender',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Divider(height: 20, thickness: 1, color: colorScheme.outline),
            ProfileDetailRow(
              label: 'Identifies as',
              value: userData.gender?.name.capitalize(),
              icon: userData.gender == Gender.male 
                  ? Icons.male 
                  : (userData.gender == Gender.female 
                      ? Icons.female 
                      : Icons.transgender),
            ),
          ],
        ),
      ),
    );
  }
}
