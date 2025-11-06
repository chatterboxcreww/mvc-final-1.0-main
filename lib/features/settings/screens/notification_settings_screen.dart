// lib/features/settings/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
import '../widgets/glass_settings_tile.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  bool _waterReminders = true;
  bool _stepGoalReminders = true;
  bool _moodCheckIns = true;
  bool _weeklyReports = true;
  bool _achievementNotifications = true;
  bool _levelUpNotifications = true;

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
        title: 'Notification Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Glass background
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: _controller,
                colorScheme: colorScheme,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // General Notifications
                  _buildSectionTitle(context, 'General Notifications'),
                  const SizedBox(height: 12),
                  GlassSwitchTile(
                    icon: Icons.water_drop_outlined,
                    title: "Water Reminders",
                    subtitle: "Get reminded to drink water throughout the day",
                    color: Colors.blue,
                    value: _waterReminders,
                    onChanged: (value) => setState(() => _waterReminders = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.directions_walk_outlined,
                    title: "Step Goal Reminders",
                    subtitle: "Motivation to reach your daily step goal",
                    color: Colors.green,
                    value: _stepGoalReminders,
                    onChanged: (value) => setState(() => _stepGoalReminders = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.mood_outlined,
                    title: "Mood Check-ins",
                    subtitle: "Daily reminders to log your mood",
                    color: Colors.orange,
                    value: _moodCheckIns,
                    onChanged: (value) => setState(() => _moodCheckIns = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.assessment_outlined,
                    title: "Weekly Reports",
                    subtitle: "Summary of your weekly progress",
                    color: Colors.purple,
                    value: _weeklyReports,
                    onChanged: (value) => setState(() => _weeklyReports = value),
                  ),

                  const SizedBox(height: 24),

                  // Achievement Notifications
                  _buildSectionTitle(context, 'Achievement Notifications'),
                  const SizedBox(height: 12),
                  GlassSwitchTile(
                    icon: Icons.emoji_events_outlined,
                    title: "Achievement Unlocked",
                    subtitle: "Celebrate when you unlock new achievements",
                    color: Colors.amber,
                    value: _achievementNotifications,
                    onChanged: (value) => setState(() => _achievementNotifications = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.star_outline,
                    title: "Level Up",
                    subtitle: "Get notified when you reach a new level",
                    color: Colors.indigo,
                    value: _levelUpNotifications,
                    onChanged: (value) => setState(() => _levelUpNotifications = value),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  GlassButton(
                    text: 'Save Settings',
                    icon: Icons.save_outlined,
                    onPressed: _saveSettings,
                    isPrimary: true,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings saved!')),
    );
  }
}
