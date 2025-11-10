// lib/features/settings/screens/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
import '../widgets/glass_settings_tile.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  bool _shareDataWithFriends = true;
  bool _showInLeaderboard = true;
  bool _allowAnalytics = true;
  bool _personalizedAds = false;

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
        title: 'Privacy & Security',
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
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: kToolbarHeight + 16, // Add space for app bar
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  _buildSectionTitle(context, 'Data Sharing'),
                  const SizedBox(height: 12),
                  GlassSwitchTile(
                    icon: Icons.people_outline,
                    title: "Share with Friends",
                    subtitle: "Allow friends to see your activity",
                    color: Colors.blue,
                    value: _shareDataWithFriends,
                    onChanged: (value) => setState(() => _shareDataWithFriends = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.leaderboard_outlined,
                    title: "Show in Leaderboard",
                    subtitle: "Appear in public leaderboards",
                    color: Colors.green,
                    value: _showInLeaderboard,
                    onChanged: (value) => setState(() => _showInLeaderboard = value),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Analytics & Ads'),
                  const SizedBox(height: 12),
                  GlassSwitchTile(
                    icon: Icons.analytics_outlined,
                    title: "Usage Analytics",
                    subtitle: "Help improve the app with anonymous data",
                    color: Colors.purple,
                    value: _allowAnalytics,
                    onChanged: (value) => setState(() => _allowAnalytics = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.ad_units_outlined,
                    title: "Personalized Ads",
                    subtitle: "Show ads based on your interests",
                    color: Colors.orange,
                    value: _personalizedAds,
                    onChanged: (value) => setState(() => _personalizedAds = value),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Account Actions'),
                  const SizedBox(height: 12),
                  GlassSettingsTile(
                    icon: Icons.download_outlined,
                    title: "Download My Data",
                    subtitle: "Get a copy of your health data",
                    color: Colors.teal,
                    onTap: () {},
                  ),
                  GlassSettingsTile(
                    icon: Icons.delete_outline,
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    color: Colors.red,
                    onTap: _showDeleteAccountDialog,
                  ),

                  const SizedBox(height: 32),

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
      const SnackBar(content: Text('Privacy settings saved!')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle account deletion
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
