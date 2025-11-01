import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/user_data_provider.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/providers/experience_provider.dart';
import '../../../core/providers/achievement_provider.dart';
import '../../../core/services/step_tracking_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../widgets/step_tracker_card.dart';
import '../widgets/water_tracker_card.dart';
import '../widgets/feed_section.dart';
import '../widgets/progress_section.dart';
import '../widgets/xp_notification_overlay.dart';
import '../widgets/profile_components/experience_card.dart';
import '../widgets/profile_components/achievements_card.dart';
import '../../profile/screens/trends_page.dart';
import '../../profile/screens/achievements_screen.dart';
import '../../profile/screens/leaderboard_screen.dart';
import '../../profile/screens/step_history_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentIndex = 0;
  final StepTrackingService _stepTrackingService = StepTrackingService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    // Add lifecycle observer to handle app closing
    WidgetsBinding.instance.addObserver(this);

    // Initialize providers after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Notify step counter provider about lifecycle changes
    // This is crucial for detecting new days and refreshing step counts
    if (mounted) {
      try {
        context.read<StepCounterProvider>().handleAppLifecycleChange(state);
      } catch (e) {
        print('Error handling step counter lifecycle change: $e');
      }
    }
    
    // Only sync to Firebase when app is closing or going to background
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      print('App closing/backgrounding - Syncing to Firebase...');
      _performFinalFirebaseSync();
    }
  }

  /// Performs a final sync to Firebase when the app is closing
  Future<void> _performFinalFirebaseSync() async {
    try {
      // Get current user data to sync
      final userProvider = context.read<UserDataProvider>();
      final stepProvider = context.read<StepCounterProvider>();
      final achievementProvider = context.read<AchievementProvider>();
      
      // Sync step data to Firebase
      await _stepTrackingService.syncStepsToFirebase();
      
      // Sync user data to Firestore
      await _authService.saveUserDataToFirestore(userProvider.userData);
      
      // Sync achievement data to Firebase
      await achievementProvider.saveToFirebase();
      
      print('Final Firebase sync completed successfully');
    } catch (e) {
      print('Error during final Firebase sync: $e');
    }
  }

  void _initializeProviders() {
    try {
      final userProvider = context.read<UserDataProvider>();
      final stepProvider = context.read<StepCounterProvider>();
      final expProvider = context.read<ExperienceProvider>();

      // Initialize experience provider with current user data
      expProvider.initializeFromUserData(userProvider.userData);

      // Initialize step counter with user data
      stepProvider.initialize(userProvider.userData);
    } catch (e) {
      // print('Error initializing providers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userProvider, child) {
        return Stack(
          children: [
            Scaffold(
              extendBody: true,
              appBar: _currentIndex == 0 ? _buildHomeAppBar(context, userProvider) : null,
              body: GradientBackground(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _HomeTab(),
                    _FeedTab(),
                    _ProgressTab(),
                    _TrendsTab(),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomNavigationBar(context),
            ),
            // XP notification overlay
            const XpNotificationOverlay(),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context, UserDataProvider userProvider) {
    final userData = userProvider.userData;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 80, // Increased height for better proportions
      title: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${userData.name ?? 'User'}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Let\'s track your health today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Notification bell with indicator
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _showNotificationsDialog(context),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Enhanced profile avatar
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: userData.profilePicturePath != null
                    ? NetworkImage(userData.profilePicturePath!)
                    : null,
                child: userData.profilePicturePath == null
                    ? Icon(
                        Icons.person_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _tabController.animateTo(index);
          },
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.feed_outlined),
              activeIcon: Icon(Icons.feed_rounded),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined),
              activeIcon: Icon(Icons.task_alt_rounded),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Trends',
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildMenuTile(
                    context,
                    Icons.emoji_events_rounded,
                    'Achievements',
                    'View your earned badges',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuTile(
                    context,
                    Icons.leaderboard_rounded,
                    'Leaderboard',
                    'See how you rank',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuTile(
                    context,
                    Icons.history_rounded,
                    'Step History',
                    'Track your progress',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StepHistoryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuTile(
                    context,
                    Icons.settings_rounded,
                    'Settings',
                    'Customize your experience',
                    () {
                      Navigator.pop(context);
                      Navigator.of(context).pushFluid(const SettingsScreen());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            HealthGradientCard(
              gradientColors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Progress",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Keep up the great work! Every step counts towards your health goals.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main tracking cards
            const StepTrackerCard(),
            const SizedBox(height: 16),
            const WaterTrackerCard(),
            const SizedBox(height: 24),

            // Quick actions - moved up
            _buildQuickActions(context),
            const SizedBox(height: 20),

            // Progress and achievements section - moved down
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const ExperienceCard(),
            const SizedBox(height: 16),
            const AchievementsCard(),
            const SizedBox(height: 20),
            
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            HealthGradientCard(
              onTap: () => Navigator.of(context).pushFluid(const TrendsPage()),
              gradientColors: [
                Colors.blue.withValues(alpha: 0.1),
                Colors.blue.withValues(alpha: 0.05),
              ],
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'View Trends',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            HealthGradientCard(
              onTap: () => Navigator.of(context).pushFluid(const LeaderboardScreen()),
              gradientColors: [
                Colors.orange.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.05),
              ],
              child: Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Leaderboard',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    return const FeedSection();
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return const ProgressSection();
  }
}

class _TrendsTab extends StatelessWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context) {
    return const TrendsPage();
  }
}
