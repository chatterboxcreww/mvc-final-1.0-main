// lib/features/settings/screens/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _shareHealthData = false;
  bool _allowAnalytics = true;
  bool _personalizedAds = false;
  bool _shareWithFriends = true;
  bool _publicProfile = false;

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
                      Colors.indigo,
                      Colors.indigo.withValues(alpha: 0.8),
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
                        "Privacy & Security",
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
                      // Privacy Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Your Privacy Matters",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "We are committed to protecting your personal health data. All information is encrypted and stored securely. You have full control over what data is shared and with whom.",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Data Sharing
                      SettingsSection(
                        title: "Data Sharing",
                        children: [
                          _buildSwitchTile(
                            title: "Share Health Data",
                            subtitle: "Allow sharing anonymized health data for research",
                            icon: Icons.health_and_safety_outlined,
                            color: Colors.red,
                            value: _shareHealthData,
                            onChanged: (value) => setState(() => _shareHealthData = value),
                          ),
                          _buildSwitchTile(
                            title: "Allow Analytics",
                            subtitle: "Help improve the app with usage analytics",
                            icon: Icons.analytics_outlined,
                            color: Colors.blue,
                            value: _allowAnalytics,
                            onChanged: (value) => setState(() => _allowAnalytics = value),
                          ),
                          _buildSwitchTile(
                            title: "Personalized Ads",
                            subtitle: "Show relevant health and wellness advertisements",
                            icon: Icons.ads_click_outlined,
                            color: Colors.orange,
                            value: _personalizedAds,
                            onChanged: (value) => setState(() => _personalizedAds = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social Features
                      SettingsSection(
                        title: "Social Features",
                        children: [
                          _buildSwitchTile(
                            title: "Share with Friends",
                            subtitle: "Allow friends to see your progress and achievements",
                            icon: Icons.people_outline,
                            color: Colors.green,
                            value: _shareWithFriends,
                            onChanged: (value) => setState(() => _shareWithFriends = value),
                          ),
                          _buildSwitchTile(
                            title: "Public Profile",
                            subtitle: "Make your profile visible in leaderboards",
                            icon: Icons.public_outlined,
                            color: Colors.purple,
                            value: _publicProfile,
                            onChanged: (value) => setState(() => _publicProfile = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Privacy Actions
                      SettingsSection(
                        title: "Privacy Actions",
                        children: [
                          SettingsTile(
                            title: "View Privacy Policy",
                            subtitle: "Read our complete privacy policy",
                            icon: Icons.description_outlined,
                            color: Colors.blue,
                            onTap: () => _showPrivacyPolicy(),
                          ),
                          SettingsTile(
                            title: "Data Usage Report",
                            subtitle: "See what data we collect and how it's used",
                            icon: Icons.pie_chart_outline,
                            color: Colors.teal,
                            onTap: () => _showDataUsageReport(),
                          ),
                          SettingsTile(
                            title: "Delete My Data",
                            subtitle: "Permanently delete all your data",
                            icon: Icons.delete_forever_outlined,
                            color: Colors.red,
                            onTap: () => _showDeleteDataDialog(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Security Features Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Your Data is Secure",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "• End-to-end encryption\n• Regular security audits\n• GDPR compliant\n• Local data processing when possible",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Health-TRKD Privacy Policy\n\n"
            "1. Data Collection: We collect only the health data you choose to share.\n\n"
            "2. Data Storage: All data is encrypted and stored securely on our servers.\n\n"
            "3. Data Sharing: We never sell your personal data to third parties.\n\n"
            "4. Your Rights: You can export, modify, or delete your data at any time.\n\n"
            "5. Contact: For privacy concerns, contact us at privacy@health-trkd.com",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showDataUsageReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Data Usage Report"),
        content: const SingleChildScrollView(
          child: Text(
            "What data we collect:\n\n"
            "• Health metrics (steps, water intake, mood)\n"
            "• Usage analytics (app interactions)\n"
            "• Profile information (name, email)\n\n"
            "How we use it:\n\n"
            "• Provide personalized health insights\n"
            "• Improve app functionality\n"
            "• Send relevant notifications\n\n"
            "Data retention: Stored until you delete your account.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete All Data"),
        content: const Text(
          "Are you sure you want to permanently delete all your data? "
          "This action cannot be undone and you will lose all your health history, "
          "achievements, and progress.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement data deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data deletion request submitted. You will receive a confirmation email.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              "Delete Data",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
