// lib/features/settings/screens/settings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../../profile/widgets/edit_personal_details_dialog.dart';
import '../../profile/widgets/edit_health_info_dialog.dart';
import '../../onboarding/screens/health_goals_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'export_data_screen.dart';
import 'sync_settings_screen.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: [
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          Theme.of(context).colorScheme.surface,
        ],
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Settings",
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Consumer<UserDataProvider>(
                          builder: (context, userProvider, child) {
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                                  backgroundImage: userProvider.userData.profilePicturePath != null
                                      ? NetworkImage(userProvider.userData.profilePicturePath!)
                                      : null,
                                  child: userProvider.userData.profilePicturePath == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          size: 32,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProvider.userData.name ?? "User",
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        userProvider.userData.email ?? 
                                        FirebaseAuth.instance.currentUser?.email ?? 
                                        "user@example.com",
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Section
                          SettingsSection(
                            title: "Profile",
                            children: [
                              SettingsTile(
                                title: "Personal Information",
                                subtitle: "Update your basic details",
                                icon: Icons.person_outline_rounded,
                                color: Colors.blue,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const EditPersonalDetailsDialog(),
                                  );
                                },
                              ),
                              SettingsTile(
                                title: "Health Information",
                                subtitle: "Medical conditions and allergies",
                                icon: Icons.health_and_safety_outlined,
                                color: Colors.red,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const EditHealthInfoDialog(),
                                  );
                                },
                              ),
                              SettingsTile(
                                title: "Goals & Targets",
                                subtitle: "Adjust your daily health goals",
                                icon: Icons.track_changes_rounded,
                                color: Colors.green,
                                onTap: () {
                                  final userData = context.read<UserDataProvider>().userData;
                                  Navigator.of(context).pushFluid(
                                    HealthGoalsScreen(
                                      suggestedSteps: userData.dailyStepGoal ?? 10000,
                                      suggestedWater: userData.dailyWaterGoal ?? 8,
                                      bmr: (userData.bmr ?? 1500).round(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // App Preferences
                          SettingsSection(
                            title: "App Preferences",
                            children: [
                              Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return SettingsTile(
                                    title: "Theme",
                                    subtitle: _getThemeSubtitle(themeProvider.themeMode),
                                    icon: Icons.palette_outlined,
                                    color: Colors.purple,
                                    onTap: () => _showThemeSelector(context, themeProvider),
                                    trailing: Icon(
                                      _getThemeIcon(themeProvider.themeMode),
                                      color: Colors.purple,
                                    ),
                                  );
                                },
                              ),
                              SettingsTile(
                                title: "Notifications",
                                subtitle: "Manage your notification preferences",
                                icon: Icons.notifications_outlined,
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              SettingsTile(
                                title: "Privacy & Security",
                                subtitle: "Data privacy and security settings",
                                icon: Icons.security_rounded,
                                color: Colors.indigo,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacySettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Data & Backup
                          SettingsSection(
                            title: "Data & Backup",
                            children: [
                              SettingsTile(
                                title: "Export Data",
                                subtitle: "Download your health data as PDF",
                                icon: Icons.download_rounded,
                                color: Colors.teal,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ExportDataScreen(),
                                    ),
                                  );
                                },
                              ),
                              SettingsTile(
                                title: "Sync Settings",
                                subtitle: "Manage data synchronization",
                                icon: Icons.sync_rounded,
                                color: Colors.cyan,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SyncSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Support
                          SettingsSection(
                            title: "Support",
                            children: [
                              SettingsTile(
                                title: "Help Center",
                                subtitle: "Get help and support",
                                icon: Icons.help_outline_rounded,
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const HelpCenterScreen(),
                                    ),
                                  );
                                },
                              ),
                              SettingsTile(
                                title: "Contact Us",
                                subtitle: "Send feedback or report issues",
                                icon: Icons.contact_support_outlined,
                                color: Colors.green,
                                onTap: () {
                                  _showContactUsDialog();
                                },
                              ),
                              SettingsTile(
                                title: "About",
                                subtitle: "App version and information",
                                icon: Icons.info_outline_rounded,
                                color: Colors.grey,
                                onTap: () {
                                  _showAboutDialog(context);
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Sign Out Button
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _showSignOutDialog(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Sign Out",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
        ),
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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Choose Theme",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeOption(context, themeProvider, AppThemeMode.system, "System Default", Icons.settings_brightness_rounded),
            _buildThemeOption(context, themeProvider, AppThemeMode.light, "Light Theme", Icons.light_mode_rounded),
            _buildThemeOption(context, themeProvider, AppThemeMode.dark, "Dark Theme", Icons.dark_mode_rounded),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeProvider themeProvider, AppThemeMode mode, String title, IconData icon) {
    final isSelected = themeProvider.themeMode == mode.toThemeMode();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          themeProvider.setThemeMode(mode);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primaryContainer 
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactUsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mail_outline, color: Colors.green),
            SizedBox(width: 12),
            Text("Contact Us"),
          ],
        ),
        content: const Text(
          "We'd love to hear from you! 💚\n\n"
          "📧 Email: support@health-trkd.com\n"
          "📞 Phone: Coming Soon\n"
          "💬 Live Chat: Coming Soon\n"
          "📱 In-App Messaging: Coming Soon\n\n"
          "Response time: 24-48 hours\n"
          "Available: Monday-Friday, 9 AM - 6 PM EST",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enhanced contact features coming soon!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Coming Soon"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("About Health-TRKD"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Version 1.0.0"),
            const SizedBox(height: 8),
            const Text("Your comprehensive health tracking companion."),
            const SizedBox(height: 16),
            const Text("Developed with ❤️ for your wellness journey."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog
              
              // Show loading indicator while signing out
              final loadingDialogCompleter = Completer<BuildContext>();
              
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    // Complete the completer with the dialog context
                    loadingDialogCompleter.complete(dialogContext);
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Signing out..."),
                        ],
                      ),
                    );
                  },
                );
              }
              
              try {
                // Use proper AuthService for complete sign-out with cleanup
                await AuthService().signOut();
                
                // Explicitly close the loading dialog
                if (mounted && loadingDialogCompleter.isCompleted) {
                  final dialogContext = await loadingDialogCompleter.future;
                  Navigator.of(dialogContext).pop();
                }
                
                // Force navigation to auth screen instead of relying on AuthWrapper
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
                
              } catch (e) {
                print('Sign-out error: $e');
                
                // Close loading dialog if still mounted
                if (mounted && loadingDialogCompleter.isCompleted) {
                  final dialogContext = await loadingDialogCompleter.future;
                  Navigator.of(dialogContext).pop();
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: Please try again'),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () => _showSignOutDialog(context),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
