// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\health_info_card.dart

// lib/features/home/widgets/profile_components/health_info_card.dart
import 'package:flutter/material.dart';

import '../../../../core/models/user_data.dart';
import '../../../../shared/utils/extensions.dart';
import 'profile_detail_widgets.dart';

class HealthInfoCard extends StatelessWidget {
  final UserData userData;

  const HealthInfoCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health Conditions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Divider(height: 20, thickness: 1, color: colorScheme.outline),
            ProfileCheckmarkRow(
              label: 'Diabetes',
              value: userData.hasDiabetes,
              icon: Icons.bloodtype_outlined,
            ),
            ProfileCheckmarkRow(
              label: 'Protein Deficiency',
              value: userData.hasProteinDeficiency,
              icon: Icons.set_meal_outlined,
            ),
            ProfileCheckmarkRow(
              label: 'Identifies "Skinny Fat"',
              value: userData.isSkinnyFat,
              icon: Icons.accessibility_new_outlined,
            ),
            const SizedBox(height: 10),
            Text('Allergies Reported',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            if (userData.allergies != null && userData.allergies!.isNotEmpty)
              ...userData.allergies!
                  .map((allergy) => Padding(
                        padding: const EdgeInsets.only(
                            left: 24.0, top: 2.0, bottom: 2.0),
                        child: Text('• ${allergy.capitalize()}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ))
                  
            else
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Text('No allergies reported.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8))),
              ),
          ],
        ),
      ),
    );
  }
}
