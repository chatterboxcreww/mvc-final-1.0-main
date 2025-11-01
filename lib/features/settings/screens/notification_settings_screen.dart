// lib/features/settings/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _waterReminders = true;
  bool _stepGoalReminders = true;
  bool _moodCheckIns = true;
  bool _weeklyReports = true;
  bool _achievementNotifications = true;
  bool _levelUpNotifications = true;
  
  TimeOfDay _morningReminderTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _afternoonReminderTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _eveningReminderTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _bedtimeReminderTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: [
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          Theme.of(context).colorScheme.surface,
        ],
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange,
                      Colors.orange.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Notification Settings",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // General Notifications
                      SettingsSection(
                        title: "General Notifications",
                        children: [
                          _buildSwitchTile(
                            title: "Water Reminders",
                            subtitle: "Get reminded to drink water throughout the day",
                            icon: Icons.water_drop_outlined,
                            color: Colors.blue,
                            value: _waterReminders,
                            onChanged: (value) => setState(() => _waterReminders = value),
                          ),
                          _buildSwitchTile(
                            title: "Step Goal Reminders",
                            subtitle: "Motivation to reach your daily step goal",
                            icon: Icons.directions_walk_outlined,
                            color: Colors.green,
                            value: _stepGoalReminders,
                            onChanged: (value) => setState(() => _stepGoalReminders = value),
                          ),
                          _buildSwitchTile(
                            title: "Mood Check-ins",
                            subtitle: "Daily reminders to log your mood",
                            icon: Icons.mood_outlined,
                            color: Colors.orange,
                            value: _moodCheckIns,
                            onChanged: (value) => setState(() => _moodCheckIns = value),
                          ),
                          _buildSwitchTile(
                            title: "Weekly Reports",
                            subtitle: "Summary of your weekly progress",
                            icon: Icons.assessment_outlined,
                            color: Colors.purple,
                            value: _weeklyReports,
                            onChanged: (value) => setState(() => _weeklyReports = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Achievement Notifications
                      SettingsSection(
                        title: "Achievement Notifications",
                        children: [
                          _buildSwitchTile(
                            title: "Achievement Unlocked",
                            subtitle: "Celebrate when you unlock new achievements",
                            icon: Icons.emoji_events_outlined,
                            color: Colors.amber,
                            value: _achievementNotifications,
                            onChanged: (value) => setState(() => _achievementNotifications = value),
                          ),
                          _buildSwitchTile(
                            title: "Level Up",
                            subtitle: "Get notified when you reach a new level",
                            icon: Icons.star_outline,
                            color: Colors.indigo,
                            value: _levelUpNotifications,
                            onChanged: (value) => setState(() => _levelUpNotifications = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Notification Times
                      SettingsSection(
                        title: "Notification Times",
                        children: [
                          _buildTimeTile(
                            title: "Morning Reminder",
                            subtitle: "Start your day with health goals",
                            icon: Icons.wb_sunny_outlined,
                            color: Colors.orange,
                            time: _morningReminderTime,
                            onTimeChanged: (time) => setState(() => _morningReminderTime = time),
                          ),
                          _buildTimeTile(
                            title: "Afternoon Check-in",
                            subtitle: "Midday hydration and activity reminder",
                            icon: Icons.light_mode_outlined,
                            color: Colors.blue,
                            time: _afternoonReminderTime,
                            onTimeChanged: (time) => setState(() => _afternoonReminderTime = time),
                          ),
                          _buildTimeTile(
                            title: "Evening Reminder",
                            subtitle: "Evening health check and goal review",
                            icon: Icons.wb_twilight_outlined,
                            color: Colors.deepOrange,
                            time: _eveningReminderTime,
                            onTimeChanged: (time) => setState(() => _eveningReminderTime = time),
                          ),
                          _buildTimeTile(
                            title: "Bedtime Reminder",
                            subtitle: "Wind down and prepare for sleep",
                            icon: Icons.bedtime_outlined,
                            color: Colors.indigo,
                            time: _bedtimeReminderTime,
                            onTimeChanged: (time) => setState(() => _bedtimeReminderTime = time),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text("Save Settings"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: color,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SettingsTile(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        onTap: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) {
            onTimeChanged(newTime);
          }
        },
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            time.format(context),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save notification settings to persistent storage/Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
