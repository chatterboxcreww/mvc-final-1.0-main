import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
import '../../../core/providers/user_data_provider.dart';

class RemindersSettingsScreen extends StatefulWidget {
  const RemindersSettingsScreen({super.key});

  @override
  State<RemindersSettingsScreen> createState() => _RemindersSettingsScreenState();
}

class _RemindersSettingsScreenState extends State<RemindersSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Reminders',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: _controller,
                colorScheme: colorScheme,
              ),
            ),
          ),
          SafeArea(
            child: Consumer<UserDataProvider>(
              builder: (context, userProvider, child) {
                final userData = userProvider.userData;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Water Reminder
                      _buildReminderTile(
                        context,
                        Icons.water_drop_rounded,
                        'Water Reminder',
                        'Get reminded to drink water',
                        Colors.blue,
                        userData.waterReminderEnabled,
                        userData.waterReminderTime,
                        (enabled) => _updateWaterReminder(context, userProvider, enabled),
                        () => _selectTime(context, userProvider, 'water'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Step Reminder
                      _buildReminderTile(
                        context,
                        Icons.directions_walk_rounded,
                        'Step Reminder',
                        'Get reminded to reach your step goal',
                        Colors.green,
                        userData.morningWalkReminderEnabled,
                        userData.stepReminderTime,
                        (enabled) => _updateStepReminder(context, userProvider, enabled),
                        () => _selectTime(context, userProvider, 'step'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Sleep Reminder
                      _buildReminderTile(
                        context,
                        Icons.bedtime_rounded,
                        'Sleep Reminder',
                        'Get reminded when it\'s time to sleep',
                        Colors.purple,
                        userData.sleepNotificationEnabled,
                        userData.sleepTime,
                        (enabled) => _updateSleepReminder(context, userProvider, enabled),
                        () => _selectTime(context, userProvider, 'sleep'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Wake Up Reminder
                      _buildReminderTile(
                        context,
                        Icons.wb_sunny_rounded,
                        'Wake Up Reminder',
                        'Get reminded when it\'s time to wake up',
                        Colors.orange,
                        userData.wakeupNotificationEnabled,
                        userData.wakeupTime,
                        (enabled) => _updateWakeupReminder(context, userProvider, enabled),
                        () => _selectTime(context, userProvider, 'wakeup'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info Card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Reminders help you stay on track with your health goals. Make sure notifications are enabled in your device settings.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool enabled,
    TimeOfDay? time,
    Function(bool) onToggle,
    VoidCallback onTimeSelect,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled && time != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTimeSelect,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reminder Time',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Text(
                      time.format(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    UserDataProvider userProvider,
    String reminderType,
  ) async {
    final userData = userProvider.userData;
    TimeOfDay? initialTime;
    
    switch (reminderType) {
      case 'water':
        initialTime = userData.waterReminderTime ?? const TimeOfDay(hour: 9, minute: 0);
        break;
      case 'step':
        initialTime = userData.stepReminderTime ?? const TimeOfDay(hour: 18, minute: 0);
        break;
      case 'sleep':
        initialTime = userData.sleepTime ?? const TimeOfDay(hour: 22, minute: 0);
        break;
      case 'wakeup':
        initialTime = userData.wakeupTime ?? const TimeOfDay(hour: 7, minute: 0);
        break;
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime!,
    );
    
    if (picked != null && context.mounted) {
      switch (reminderType) {
        case 'water':
          await userProvider.updateUserData(
            userData.copyWith(waterReminderTime: picked),
          );
          break;
        case 'step':
          await userProvider.updateUserData(
            userData.copyWith(stepReminderTime: picked),
          );
          break;
        case 'sleep':
          await userProvider.updateUserData(
            userData.copyWith(sleepTime: picked),
          );
          break;
        case 'wakeup':
          await userProvider.updateUserData(
            userData.copyWith(wakeupTime: picked),
          );
          break;
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Reminder time updated to ${picked.format(context)}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateWaterReminder(
    BuildContext context,
    UserDataProvider userProvider,
    bool enabled,
  ) async {
    await userProvider.updateUserData(
      userProvider.userData.copyWith(waterReminderEnabled: enabled),
    );
  }

  Future<void> _updateStepReminder(
    BuildContext context,
    UserDataProvider userProvider,
    bool enabled,
  ) async {
    await userProvider.updateUserData(
      userProvider.userData.copyWith(morningWalkReminderEnabled: enabled),
    );
  }

  Future<void> _updateSleepReminder(
    BuildContext context,
    UserDataProvider userProvider,
    bool enabled,
  ) async {
    await userProvider.updateUserData(
      userProvider.userData.copyWith(sleepNotificationEnabled: enabled),
    );
  }

  Future<void> _updateWakeupReminder(
    BuildContext context,
    UserDataProvider userProvider,
    bool enabled,
  ) async {
    await userProvider.updateUserData(
      userProvider.userData.copyWith(wakeupNotificationEnabled: enabled),
    );
  }
}
