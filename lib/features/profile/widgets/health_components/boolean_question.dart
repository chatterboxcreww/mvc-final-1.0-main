// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\health_components\boolean_question.dart

// lib/features/profile/widgets/health_components/boolean_question.dart
import 'package:flutter/material.dart';

class BooleanQuestion extends StatelessWidget {
  final String question;
  final String description;
  final bool? currentValue;
  final ValueChanged<bool> onChanged;
  final IconData questionIcon;

  const BooleanQuestion({
    super.key,
    required this.question,
    required this.description,
    required this.currentValue,
    required this.onChanged,
    required this.questionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(questionIcon, color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface
                )
              ),
            ),
          ]
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant
          )
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Yes'),
                onPressed: () => onChanged(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentValue == true 
                    ? colorScheme.primary 
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  foregroundColor: currentValue == true 
                    ? colorScheme.onPrimary 
                    : colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  elevation: currentValue == true ? 3 : 0,
                ),
              )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.highlight_off_outlined),
                label: const Text('No'),
                onPressed: () => onChanged(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentValue == false 
                    ? colorScheme.primary 
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  foregroundColor: currentValue == false 
                    ? colorScheme.onPrimary 
                    : colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  elevation: currentValue == false ? 3 : 0,
                ),
              )
            ),
          ]
        ),
      ]
    );
  }
}
