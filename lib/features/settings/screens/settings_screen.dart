// lib/features/settings/screens/settings_screen_glass.dart
// Glass-themed settings screen - Complete implementation

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../profile/widgets/edit_personal_details_dialog.dart';
import '../../profile/widgets/edit_health_info_comprehensive_dialog.dart';
import '../../profile/widgets/edit_goals_dialog.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
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
        title: 'Settings',
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
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: kToolbarHeight + 16, // Add space for app bar
                bottom: MediaQuery.of(context).size.height < 700 ? 100.0 : 80.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // User Profile Card
                  Consumer<UserDataProvider>(
                    builder: (context, userProvider, child) {
                      return GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            GlassContainer(
                              padding: const EdgeInsets.all(4),
                              borderRadius: 30,
                              shape: BoxShape.circle,
                              gradientColors: [
                                colorScheme.primary.withOpacity(0.2),
                                colorScheme.primary.withOpacity(0.1),
                              ],
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 2,
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: userProvider.userData.profilePicturePath != null
                                    ? NetworkImage(userProvider.userData.profilePicturePath!)
                                    : null,
                                child: userProvider.userData.profilePicturePath == null
                                    ? Icon(
                                        Icons.person_rounded,
                                        color: colorScheme.onPrimaryContainer,
                                        size: 32,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userProvider.userData.name ?? "User",
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    userProvider.userData.email ?? 
                                    FirebaseAuth.instance.currentUser?.email ?? 
                                    "user@example.com",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
                  
                  const SizedBox(height: 24),
                  
                  // Profile Section
                  _buildSectionTitle(context, 'Profile'),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    context,
                    Icons.person_outline_rounded,
                    'Personal Information',
                    'Update your basic details',
                    Colors.blue,
                    () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditPersonalDetailsDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    Icons.health_and_safety_outlined,
                    'Health Information',
                    'Medical conditions and allergies',
                    Colors.red,
                    () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditHealthInfoComprehensiveDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    Icons.track_changes_rounded,
                    'Goals & Targets',
                    'Adjust your daily health goals',
                    Colors.green,
                    () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditGoalsDialog(),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App Preferences
                  _buildSectionTitle(context, 'App Preferences'),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildSettingsTile(
                        context,
                        _getThemeIcon(themeProvider.themeMode),
                        'Theme',
                        _getThemeSubtitle(themeProvider.themeMode),
                        Colors.purple,
                        () => _showThemeSelector(context, themeProvider),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Support
                  _buildSectionTitle(context, 'Support'),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    context,
                    Icons.help_outline_rounded,
                    'Help Center',
                    'Get help and support',
                    Colors.blue,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpCenterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    Icons.contact_support_outlined,
                    'Contact Us',
                    'Send feedback or report issues',
                    Colors.green,
                    () => _openEmailClient('Contact Us'),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    Icons.info_outline_rounded,
                    'About',
                    'App version and information',
                    Colors.grey,
                    () => _showAboutDialog(context),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Out Button
                  GlassButton(
                    text: 'Sign Out',
                    icon: Icons.logout_rounded,
                    onPressed: () => _showSignOutDialog(context),
                    isPrimary: false,
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

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _getThemeSubtitle(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return "Light mode";
      case ThemeMode.dark:
        return "Dark mode";
      case ThemeMode.system:
        return "Follow system";
    }
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.settings_brightness_rounded;
    }
  }

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: EdgeInsets.zero,
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Choose Theme",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeOption(context, themeProvider, AppThemeMode.system, "System Default", Icons.settings_brightness_rounded),
            const SizedBox(height: 12),
            _buildThemeOption(context, themeProvider, AppThemeMode.light, "Light Theme", Icons.light_mode_rounded),
            const SizedBox(height: 12),
            _buildThemeOption(context, themeProvider, AppThemeMode.dark, "Dark Theme", Icons.dark_mode_rounded),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeProvider themeProvider, AppThemeMode mode, String title, IconData icon) {
    final isSelected = themeProvider.themeMode == mode.toThemeMode();
    final colorScheme = Theme.of(context).colorScheme;
    
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.of(context).pop();
      },
      gradientColors: isSelected
          ? [
              colorScheme.primary.withOpacity(0.2),
              colorScheme.primary.withOpacity(0.1),
            ]
          : null,
      border: Border.all(
        color: isSelected 
            ? colorScheme.primary.withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        width: isSelected ? 2 : 1,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: colorScheme.primary,
            ),
        ],
      ),
    );
  }

  void _openEmailClient(String subject) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'chatterboxcreww@gmail.com',
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client. Please email us at chatterboxcreww@gmail.com'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening email client. Please email us at chatterboxcreww@gmail.com'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About Health-TRKD'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version 1.0.0+5',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Health-TRKD is your comprehensive health and wellness companion designed to help you track, monitor, and improve your daily health habits.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Key Features:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(context, '📊', 'Step tracking with daily goals'),
              _buildFeatureItem(context, '💧', 'Water intake monitoring'),
              _buildFeatureItem(context, '🎯', 'Personalized health goals'),
              _buildFeatureItem(context, '🏆', 'Achievements and leveling system'),
              _buildFeatureItem(context, '📈', 'Detailed analytics and trends'),
              _buildFeatureItem(context, '🍎', 'Nutrition tips and recipes'),
              _buildFeatureItem(context, '🔔', 'Smart reminders'),
              _buildFeatureItem(context, '☁️', 'Cloud sync across devices'),
              const SizedBox(height: 16),
              Text(
                'Developed with ❤️ by the Health-TRKD Team',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '© 2024 Health-TRKD. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performSignOut(context);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performSignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }
}
