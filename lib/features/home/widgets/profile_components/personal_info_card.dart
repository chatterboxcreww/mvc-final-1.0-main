// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\personal_info_card.dart

// lib/features/home/widgets/profile_components/personal_info_card.dart
import 'package:flutter/material.dart';

import '../../../../core/models/user_data.dart';
import 'package:mvc/core/models/app_enums.dart';

class PersonalInfoCard extends StatelessWidget {
  final UserData userData;
  
  const PersonalInfoCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_rounded, 
                     color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (userData.name != null && userData.name!.isNotEmpty) ...[
              _buildInfoRow(context, 'Name', userData.name!),
              const SizedBox(height: 12),
            ],
            
            if (userData.age != null) ...[
              _buildInfoRow(context, 'Age', '${userData.age} years'),
              const SizedBox(height: 12),
            ],
            
            if (userData.gender != null) ...[
              _buildInfoRow(context, 'Gender', _getGenderDisplayName(userData.gender!)),
              const SizedBox(height: 12),
            ],
            
            if (userData.height != null) ...[
              _buildInfoRow(context, 'Height', '${userData.height!.toStringAsFixed(1)} cm'),
              const SizedBox(height: 12),
            ],
            
            if (userData.weight != null) ...[
              _buildInfoRow(context, 'Weight', '${userData.weight!.toStringAsFixed(1)} kg'),
              const SizedBox(height: 12),
            ],
            
            if (userData.bmi != null) ...[
              _buildInfoRow(
                context, 
                'BMI', 
                '${userData.bmi!.toStringAsFixed(1)} (${userData.bmiCategory})',
                valueColor: _getBMIColor(userData.bmi!)
              ),
              const SizedBox(height: 12),
            ],
            
            if (userData.dailyStepGoal != null) ...[
              _buildInfoRow(context, 'Daily Step Goal', '${userData.dailyStepGoal!.toStringAsFixed(0)} steps'),
              const SizedBox(height: 12),
            ],
            
            if (userData.memberSince != null) ...[
              _buildInfoRow(
                context, 
                'Member Since', 
                '${userData.memberSince!.day}/${userData.memberSince!.month}/${userData.memberSince!.year}'
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getGenderDisplayName(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;     // Underweight
    if (bmi < 25) return Colors.green;      // Normal
    if (bmi < 30) return Colors.orange;     // Overweight
    return Colors.red;                      // Obese
  }
}

