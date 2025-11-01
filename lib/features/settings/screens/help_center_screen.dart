// lib/features/settings/screens/help_center_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FAQ> _filteredFAQs = [];
  final List<FAQ> _allFAQs = [
    FAQ(
      question: "How do I track my daily steps?",
      answer: "The app automatically tracks your steps using your device's built-in step counter. Make sure location permissions are enabled for accurate tracking.",
      category: "Tracking",
    ),
    FAQ(
      question: "Why isn't my water intake saving?",
      answer: "Ensure you have a stable internet connection and try syncing your data manually from Settings > Sync & Backup.",
      category: "Data",
    ),
    FAQ(
      question: "How do I change my daily goals?",
      answer: "Go to your Profile, tap on 'Health Goals', and adjust your daily targets for steps, water, and other activities.",
      category: "Goals",
    ),
    FAQ(
      question: "Can I export my health data?",
      answer: "Yes! Go to Settings > Export Data to generate a comprehensive PDF report of your health journey.",
      category: "Data",
    ),
    FAQ(
      question: "How do achievements and levels work?",
      answer: "You earn experience points (XP) by completing daily goals and maintaining streaks. Level up to unlock new achievements and badges!",
      category: "Achievements",
    ),
    FAQ(
      question: "My notifications aren't working",
      answer: "Check your device's notification settings and ensure Health-TRKD has permission to send notifications. You can also customize notification times in Settings.",
      category: "Notifications",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFAQs = _allFAQs;
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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple,
                      Colors.deepPurple.withValues(alpha: 0.8),
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
                        "Help Center",
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
                      // Welcome Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.support_agent_rounded,
                              color: Colors.deepPurple,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "How can we help you?",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Find answers to common questions or contact our support team for personalized assistance.",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.deepPurple.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search for help...",
                            prefixIcon: Icon(Icons.search_rounded),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          onChanged: _filterFAQs,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      SettingsSection(
                        title: "Quick Actions",
                        children: [
                          SettingsTile(
                            title: "Contact Support",
                            subtitle: "Get personalized help from our team",
                            icon: Icons.headset_mic_outlined,
                            color: Colors.blue,
                            onTap: () => _showContactSupportDialog(),
                          ),
                          SettingsTile(
                            title: "Feature Request",
                            subtitle: "Suggest new features for the app",
                            icon: Icons.lightbulb_outline,
                            color: Colors.amber,
                            onTap: () => _showFeatureRequestDialog(),
                          ),
                          SettingsTile(
                            title: "Report a Bug",
                            subtitle: "Help us fix issues you've encountered",
                            icon: Icons.bug_report_outlined,
                            color: Colors.red,
                            onTap: () => _showBugReportDialog(),
                          ),
                          SettingsTile(
                            title: "User Guide",
                            subtitle: "Complete guide to using Health-TRKD",
                            icon: Icons.menu_book_outlined,
                            color: Colors.green,
                            onTap: () => _showUserGuideDialog(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // FAQ Section
                      SettingsSection(
                        title: "Frequently Asked Questions",
                        children: _filteredFAQs.map((faq) => _buildFAQTile(faq)).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Support Information
                      SettingsSection(
                        title: "Support Information",
                        children: [
                          SettingsTile(
                            title: "App Version",
                            subtitle: "1.0.0 (Build 100)",
                            icon: Icons.info_outline,
                            color: Colors.grey,
                          ),
                          SettingsTile(
                            title: "System Status",
                            subtitle: "All services operational",
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            onTap: () => _showSystemStatusDialog(),
                          ),
                          SettingsTile(
                            title: "Privacy Policy",
                            subtitle: "Read our privacy policy",
                            icon: Icons.policy_outlined,
                            color: Colors.blue,
                            onTap: () => _showPrivacyPolicyDialog(),
                          ),
                          SettingsTile(
                            title: "Terms of Service",
                            subtitle: "View terms and conditions",
                            icon: Icons.description_outlined,
                            color: Colors.purple,
                            onTap: () => _showTermsOfServiceDialog(),
                          ),
                        ],
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

  Widget _buildFAQTile(FAQ faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(faq.category).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(faq.category),
            color: _getCategoryColor(faq.category),
            size: 20,
          ),
        ),
        title: Text(
          faq.question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          faq.category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _getCategoryColor(faq.category),
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Tracking":
        return Colors.green;
      case "Data":
        return Colors.blue;
      case "Goals":
        return Colors.purple;
      case "Achievements":
        return Colors.orange;
      case "Notifications":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Tracking":
        return Icons.track_changes_outlined;
      case "Data":
        return Icons.data_usage_outlined;
      case "Goals":
        return Icons.flag_outlined;
      case "Achievements":
        return Icons.emoji_events_outlined;
      case "Notifications":
        return Icons.notifications_outlined;
      default:
        return Icons.help_outline;
    }
  }

  void _filterFAQs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFAQs = _allFAQs;
      } else {
        _filteredFAQs = _allFAQs.where((faq) =>
          faq.question.toLowerCase().contains(query.toLowerCase()) ||
          faq.answer.toLowerCase().contains(query.toLowerCase()) ||
          faq.category.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text("Contact Support"),
          ],
        ),
        content: const Text(
          "Our support team is here to help! 🎯\n\n"
          "📧 Email: support@health-trkd.com\n"
          "⏰ Response time: 24-48 hours\n"
          "🌍 Available: Monday-Friday, 9 AM - 6 PM EST\n\n"
          "Live chat and phone support coming soon!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open email client or contact form
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening email client...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text("Send Email"),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber),
            SizedBox(width: 12),
            Text("Feature Request"),
          ],
        ),
        content: const Text(
          "Have an awesome idea? We'd love to hear it! 💡\n\n"
          "Feature request portal coming soon where you can:\n"
          "• Submit new feature ideas\n"
          "• Vote on community suggestions\n"
          "• Track development progress\n"
          "• Get updates on releases\n\n"
          "For now, send your ideas to: features@health-trkd.com",
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
                  content: Text('Feature request portal coming soon!'),
                  backgroundColor: Colors.amber,
                ),
              );
            },
            child: const Text("Coming Soon"),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report_outlined, color: Colors.red),
            SizedBox(width: 12),
            Text("Report a Bug"),
          ],
        ),
        content: const Text(
          "Found a bug? Help us squash it! 🐛\n\n"
          "Automated bug reporting system coming soon:\n"
          "• One-tap bug reports with logs\n"
          "• Screenshot capture\n"
          "• Device info auto-collection\n"
          "• Real-time status updates\n\n"
          "Current bugs can be reported at: bugs@health-trkd.com",
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
                  content: Text('Advanced bug reporting coming soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Coming Soon"),
          ),
        ],
      ),
    );
  }

  void _showUserGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.menu_book_outlined, color: Colors.green),
            SizedBox(width: 12),
            Text("User Guide"),
          ],
        ),
        content: const Text(
          "Interactive user guide coming soon! 📚\n\n"
          "Will include:\n"
          "• Step-by-step tutorials\n"
          "• Video walkthroughs\n"
          "• Interactive demos\n"
          "• Best practices\n"
          "• Pro tips and tricks\n\n"
          "For now, explore the app and check out the FAQ section above!",
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
                  content: Text('Interactive guide coming soon!'),
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

  void _showSystemStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("System Status"),
        content: const Text(
          "All Health-TRKD services are operational:\n\n"
          "✅ Data Sync: Online\n"
          "✅ Authentication: Online\n"
          "✅ Notifications: Online\n"
          "✅ Cloud Backup: Online\n"
          "✅ Analytics: Online\n\n"
          "Last updated: Just now",
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

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Health-TRKD Privacy Policy\n\n"
            "Your privacy is important to us. This policy explains how we collect, use, and protect your health data.\n\n"
            "Data Collection:\n"
            "• Health metrics you choose to track\n"
            "• Usage analytics to improve the app\n"
            "• Profile information for personalization\n\n"
            "Data Usage:\n"
            "• Provide health insights\n"
            "• Sync across your devices\n"
            "• Send relevant notifications\n\n"
            "Your Rights:\n"
            "• Export your data anytime\n"
            "• Delete your account and data\n"
            "• Control sharing preferences\n\n"
            "Contact: privacy@health-trkd.com",
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

  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Terms of Service"),
        content: const SingleChildScrollView(
          child: Text(
            "Health-TRKD Terms of Service\n\n"
            "By using Health-TRKD, you agree to these terms:\n\n"
            "1. Service Usage:\n"
            "• Use the app for personal health tracking\n"
            "• Provide accurate information\n"
            "• Respect other users in social features\n\n"
            "2. Health Disclaimer:\n"
            "• This app is for wellness tracking only\n"
            "• Not a substitute for medical advice\n"
            "• Consult healthcare providers for medical decisions\n\n"
            "3. Account Responsibilities:\n"
            "• Keep your login credentials secure\n"
            "• Report any security issues\n"
            "• Update your information as needed\n\n"
            "Questions? Contact: legal@health-trkd.com",
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
}

class FAQ {
  final String question;
  final String answer;
  final String category;

  FAQ({
    required this.question,
    required this.answer,
    required this.category,
  });
}
