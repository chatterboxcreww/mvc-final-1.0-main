// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\sleep_schedule_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/user_data.dart';
import '../../../../core/providers/user_data_provider.dart';

class SleepScheduleCard extends StatelessWidget {
  const SleepScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userProvider, child) {
        final userData = userProvider.userData;
        final sleepDuration = _calculateSleepDuration(userData);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sleep Schedule',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (userData.sleepTime != null && userData.wakeupTime != null) ...[
                  _buildTimeRow(
                    context,
                    'Bedtime',
                    userData.sleepTime!.format(context),
                    Icons.bedtime,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeRow(
                    context,
                    'Wake-up',
                    userData.wakeupTime!.format(context),
                    Icons.wb_sunny,
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(Theme.of(context).colorScheme.primaryContainer.red, Theme.of(context).colorScheme.primaryContainer.green, Theme.of(context).colorScheme.primaryContainer.blue, 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sleep Duration',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${sleepDuration.toStringAsFixed(1)} hours',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSleepQualityIndicator(sleepDuration),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(Theme.of(context).colorScheme.surfaceContainerHighest.red, Theme.of(context).colorScheme.surfaceContainerHighest.green, Theme.of(context).colorScheme.surfaceContainerHighest.blue, 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No sleep schedule set',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set your bedtime and wake-up time in settings',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeRow(BuildContext context, String label, String time, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepQualityIndicator(double hours) {
    Color color;
    String quality;
    IconData icon;
    
    if (hours >= 7 && hours <= 9) {
      color = Colors.green;
      quality = 'Good';
      icon = Icons.check_circle;
    } else if (hours >= 6 && hours < 7) {
      color = Colors.orange;
      quality = 'Fair';
      icon = Icons.warning;
    } else {
      color = Colors.red;
      quality = 'Poor';
      icon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            quality,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSleepDuration(UserData userData) {
    if (userData.sleepTime == null || userData.wakeupTime == null) {
      return 0.0;
    }
    
    final sleepMinutes = userData.sleepTime!.hour * 60 + userData.sleepTime!.minute;
    final wakeMinutes = userData.wakeupTime!.hour * 60 + userData.wakeupTime!.minute;
    
    int durationMinutes;
    if (wakeMinutes > sleepMinutes) {
      // Same day
      durationMinutes = wakeMinutes - sleepMinutes;
    } else {
      // Next day
      durationMinutes = (24 * 60) - sleepMinutes + wakeMinutes;
    }
    
    return durationMinutes / 60.0;
  }
}
