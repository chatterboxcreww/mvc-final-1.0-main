// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\lifestyle_components\sleep_schedule_section.dart

// lib/features/profile/widgets/lifestyle_components/sleep_schedule_section.dart
import 'package:flutter/material.dart';

/// A widget that displays and manages sleep schedule settings
class SleepScheduleSection extends StatelessWidget {
  final TimeOfDay? sleepTime;
  final TimeOfDay? wakeupTime;
  final Function(BuildContext, bool) onTimePick;

  const SleepScheduleSection({
    super.key,
    required this.sleepTime,
    required this.wakeupTime,
    required this.onTimePick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep Schedule',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.bedtime_outlined, color: colorScheme.secondary),
          title: const Text('Sleep Time'),
          subtitle: Text(
            sleepTime?.format(context) ?? 'Tap to set',
            style: TextStyle(
              color: sleepTime == null ? colorScheme.onSurfaceVariant : null,
            ),
          ),
          trailing: Icon(Icons.edit_outlined, color: colorScheme.tertiary, size: 20),
          onTap: () => onTimePick(context, true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.wb_sunny_outlined, color: colorScheme.secondary),
          title: const Text('Wake-up Time'),
          subtitle: Text(
            wakeupTime?.format(context) ?? 'Tap to set',
            style: TextStyle(
              color: wakeupTime == null ? colorScheme.onSurfaceVariant : null,
            ),
          ),
          trailing: Icon(Icons.edit_outlined, color: colorScheme.tertiary, size: 20),
          onTap: () => onTimePick(context, false),
        ),
      ],
    );
  }
}
