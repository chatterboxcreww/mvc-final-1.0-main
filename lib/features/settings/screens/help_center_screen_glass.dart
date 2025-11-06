// lib/features/settings/screens/help_center_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<FAQ> _filteredFAQs = [];
  
  final List<FAQ> _allFAQs = [
    FAQ(
      question: "How do I track my daily steps?",
      answer: "The app automatically tracks your steps using your device's built-in step counter. Make sure location permissions are enabled for accurate tracking.",
      category: "Tracking",
      icon: Icons.directions_walk,
      color: Colors.green,
    ),
    FAQ(
      question: "Why isn't my water intake saving?",
      answer: "Ensure you have a stable internet connection and try syncing your data manually from Settings > Sync & Backup.",
      category: "Data",
      icon: Icons.water_drop,
      color: Colors.blue,
    ),
    FAQ(
      question: "How do I change my daily goals?",
      answer: "Go to your Profile, tap on 'Health Goals', and adjust your daily targets for steps, water, and other activities.",
      category: "Goals",
      icon: Icons.track_changes,
      color: Colors.orange,
    ),
    FAQ(
      question: "Can I export my health data?",
      answer: "Yes! Go to Settings > Export Data to generate a comprehensive PDF report of your health journey.",
      category: "Data",
      icon: Icons.download,
      color: Colors.teal,
    ),
    FAQ(
      question: "How do achievements and levels work?",
      answer: "You earn experience points (XP) by completing daily goals and maintaining streaks. Level up to unlock new achievements and badges!",
      category: "Achievements",
      icon: Icons.emoji_events,
      color: Colors.amber,
    ),
    FAQ(
      question: "My notifications aren't working",
      answer: "Check your device's notification settings and ensure Health-TRKD has permission to send notifications. You can also customize notification times in Settings.",
      category: "Notifications",
      icon: Icons.notifications,
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _filteredFAQs = _allFAQs;
    _searchController.addListener(_filterFAQs);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFAQs = _allFAQs.where((faq) {
        return faq.question.toLowerCase().contains(query) ||
               faq.answer.toLowerCase().contains(query) ||
               faq.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Help Center',
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
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for help...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // FAQ List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFAQs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFAQs[index];
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: faq.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(faq.icon, color: faq.color, size: 24),
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
                              color: faq.color,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                faq.answer,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Contact Support Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassButton(
                    text: 'Contact Support',
                    icon: Icons.support_agent,
                    onPressed: _contactSupport,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Email: support@health-trkd.com\n\nWe typically respond within 24 hours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
  final IconData icon;
  final Color color;

  FAQ({
    required this.question,
    required this.answer,
    required this.category,
    required this.icon,
    required this.color,
  });
}
