import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen>
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
        title: 'User Guide',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // Welcome Section
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome to Health-TRKD!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your personal health and activity tracker designed to help you achieve your wellness goals.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Getting Started
                  _buildSectionTitle(context, 'Getting Started'),
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.person_add_rounded,
                    'Set Up Your Profile',
                    'Complete your personal information, health details, and set your daily goals for steps, water intake, and calories.',
                    Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.track_changes_rounded,
                    'Track Your Progress',
                    'Monitor your daily steps, water consumption, and calorie intake. The app automatically tracks your steps using your device sensors.',
                    Colors.green,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Main Features
                  _buildSectionTitle(context, 'Main Features'),
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.home_rounded,
                    'Home Dashboard',
                    'View your daily progress at a glance. See step count, water intake, experience points, and achievements.',
                    Colors.purple,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.restaurant_rounded,
                    'Feed Section',
                    'Discover personalized meal recommendations, recipes, and nutrition tips based on your dietary preferences and health goals.',
                    Colors.orange,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.task_alt_rounded,
                    'Progress Tracking',
                    'Monitor your weekly and monthly progress. View detailed statistics and charts of your health journey.',
                    Colors.teal,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.analytics_rounded,
                    'Trends & Analytics',
                    'Analyze your health trends over time. Identify patterns and make informed decisions about your wellness.',
                    Colors.indigo,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Gamification
                  _buildSectionTitle(context, 'Gamification & Rewards'),
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.stars_rounded,
                    'Experience Points (XP)',
                    'Earn XP by completing daily goals, maintaining streaks, and achieving milestones. Level up to unlock new features!',
                    Colors.amber,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.emoji_events_rounded,
                    'Achievements & Badges',
                    'Unlock special badges and achievements as you reach health milestones. Collect them all!',
                    Colors.yellow,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.leaderboard_rounded,
                    'Leaderboard',
                    'Compete with friends and other users. See how you rank globally and stay motivated!',
                    Colors.red,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Settings & Customization
                  _buildSectionTitle(context, 'Settings & Customization'),
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.notifications_rounded,
                    'Reminders',
                    'Set custom reminders for water intake, steps, sleep, and wake-up times to stay on track.',
                    Colors.pink,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.palette_rounded,
                    'Themes & Accessibility',
                    'Choose between light, dark, or system theme. Adjust font size and enable high contrast mode for better visibility.',
                    Colors.deepPurple,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.straighten_rounded,
                    'Units Preference',
                    'Switch between Metric (km, kg) and Imperial (miles, lbs) measurement systems.',
                    Colors.cyan,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.link_rounded,
                    'Integrations',
                    'Connect with Google Fit, Apple Health, and Fitbit to sync your health data across platforms.',
                    Colors.lightBlue,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Data & Privacy
                  _buildSectionTitle(context, 'Data & Privacy'),
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.cloud_upload_rounded,
                    'Cloud Sync',
                    'Your data is automatically synced to the cloud. You can also manually sync anytime from settings.',
                    Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildGuideCard(
                    context,
                    Icons.storage_rounded,
                    'Data Management',
                    'View your storage usage and clear cache to free up space. Your personal data remains safe.',
                    Colors.deepOrange,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tips Section
                  _buildSectionTitle(context, 'Pro Tips'),
                  const SizedBox(height: 12),
                  
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTipItem('💧', 'Drink water regularly throughout the day'),
                        const SizedBox(height: 12),
                        _buildTipItem('🚶', 'Take short walks every hour to reach your step goal'),
                        const SizedBox(height: 12),
                        _buildTipItem('😴', 'Maintain consistent sleep schedule for better health'),
                        const SizedBox(height: 12),
                        _buildTipItem('🎯', 'Set realistic goals and gradually increase them'),
                        const SizedBox(height: 12),
                        _buildTipItem('📊', 'Check your progress regularly to stay motivated'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Need Help
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Need More Help?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If you have questions or need assistance, feel free to contact our support team.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'catterboxcreww@gmail.com',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
