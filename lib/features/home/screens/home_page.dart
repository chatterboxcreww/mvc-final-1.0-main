import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../../../core/providers/user_data_provider.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/providers/experience_provider.dart';
import '../../../core/providers/achievement_provider.dart';
import '../../../core/services/step_tracking_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentIndex = 0;
  final StepTrackingService _stepTrackingService = StepTrackingService();
  final AuthService _authService = AuthService();
  final List<Map<String, dynamic>> _notifications = [];
  
  bool _hasNewNotifications() {
    // Check if there are any unread notifications
    return _notifications.any((notification) => notification['isRead'] == false);
  }

  @override
  void initState() {
    super.initState();
    // Set full screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _initializeAnimations();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentIndex = _tabController.index;
        });
        // Add haptic feedback on tab change
        HapticFeedback.selectionClick();
      }
    });

    // Add lifecycle observer to handle app closing
    WidgetsBinding.instance.addObserver(this);

    // Initialize providers after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeAnimations() {
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(() {});
    _tabController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
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
            // Animated Background
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return CustomPaint(
                  painter: HomeBackgroundPainter(
                    animation: _floatingController,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
            // Main Content
            Scaffold(
              extendBody: true,
              extendBodyBehindAppBar: true,
              backgroundColor: Colors.transparent,
              appBar: _currentIndex == 0 ? _buildEnhancedHomeAppBar(context, userProvider) : null,
              body: SlideTransition(
                position: _slideAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _HomeTab(
                      floatingAnimation: _floatingAnimation,
                      pulseAnimation: _pulseAnimation,
                    ),
                    const _FeedTab(),
                    const _ProgressTab(),
                    const _TrendsTab(),
                  ],
                ),
              ),
              bottomNavigationBar: _buildEnhancedBottomNavigationBar(context),
            ),
            
            // XP notification overlay
            const XpNotificationOverlay(),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildEnhancedHomeAppBar(BuildContext context, UserDataProvider userProvider) {
    final userData = userProvider.userData;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: isSmallScreen ? 80 : 90,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.8),
              colorScheme.secondaryContainer.withOpacity(0.6),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
      ),
      title: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatingAnimation.value * 0.3),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + (isSmallScreen ? 8.0 : 12.0),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.waving_hand_rounded,
                      color: colorScheme.onPrimary,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${userData.name ?? 'User'}!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                            fontSize: isSmallScreen ? 18 : 22,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          'Let\'s track your health today',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [

        // Enhanced notification bell
        Padding(
          padding: const EdgeInsets.only(
            top: 0,
            right: 12,
          ),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _hasNewNotifications() ? _pulseAnimation.value : 1.0,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _hasNewNotifications() 
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_outlined,
                          color: _hasNewNotifications() 
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showEnhancedNotificationsDialog(context);
                        },
                      ),
                    ),
                    // Animated notification indicator
                    if (_hasNewNotifications()) 
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.error,
                                colorScheme.error.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.error.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Enhanced profile avatar
        Padding(
          padding: const EdgeInsets.only(
            top: 0,
            right: 16.0,
          ),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pushFluid(const SettingsScreen());
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.3),
                          colorScheme.secondary.withOpacity(0.2),
                        ],
                      ),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: userData.profilePicturePath != null
                          ? NetworkImage(userData.profilePicturePath!)
                          : null,
                      child: userData.profilePicturePath == null
                          ? Icon(
                              Icons.person_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 26,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedBottomNavigationBar(BuildContext context) {
    return GlassBottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        _tabController.animateTo(index);
        HapticFeedback.selectionClick();
      },
      items: [
        _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
        _buildNavItem(Icons.restaurant_rounded, Icons.restaurant, 'Feed', 1),
        _buildNavItem(Icons.task_alt_outlined, Icons.task_alt_rounded, 'Progress', 2),
        _buildNavItem(Icons.analytics_outlined, Icons.analytics_rounded, 'Trends', 3),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      activeIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }

  void _showEnhancedNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notifications'),
            if (_notifications.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var notification in _notifications) {
                      notification['isRead'] = true;
                    }
                  });
                },
                child: const Text('Mark all as read'),
              ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _notifications.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No notifications yet',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['isRead'] ?? false;
                    return Card(
                      color: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      child: ListTile(
                        leading: Icon(
                          notification['icon'] ?? Icons.notifications,
                          color: isRead ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notification['message'] ?? ''),
                        trailing: Text(
                          notification['time'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () {
                          setState(() {
                            notification['isRead'] = true;
                          });
                        },
                      ),
                    );
                  },
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

  void _showEnhancedProfileMenu(BuildContext context) {
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
              color: Colors.black.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
  final Animation<double> floatingAnimation;
  final Animation<double> pulseAnimation;
  
  const _HomeTab({
    required this.floatingAnimation,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final horizontalPadding = screenWidth * 0.04;
    
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = screenWidth < 360;
    
    // Dynamic bottom padding based on screen height to prevent footer overlap
    final bottomPadding = screenHeight < 700 ? 140.0 : 120.0;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 20, // Account for status bar + app bar + spacing
        bottom: bottomPadding, // Dynamic padding to prevent footer overlap
      ),
      child: AnimatedBuilder(
        animation: floatingAnimation,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enhanced Welcome Card
              Transform.translate(
                offset: Offset(0, floatingAnimation.value * 0.5),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withOpacity(0.8),
                        colorScheme.secondaryContainer.withOpacity(0.6),
                        colorScheme.tertiaryContainer.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: colorScheme.onPrimary,
                          size: isSmallScreen ? 24 : 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Progress",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onPrimaryContainer,
                                fontSize: isSmallScreen ? 18 : 22,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              "Keep up the great work! Every step counts towards your health goals.",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                fontSize: isSmallScreen ? 13 : 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Animated Main tracking cards
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: pulseAnimation.value,
                    child: const StepTrackerCard(),
                  );
                },
              ),
              const SizedBox(height: 8),
              const WaterTrackerCard(),
              const SizedBox(height: 16),

              // Progress section header
              Transform.translate(
                offset: Offset(0, floatingAnimation.value * 0.3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Progress cards
              const ExperienceCard(),
              const SizedBox(height: 8),
              const AchievementsCard(),
              const SizedBox(height: 16),
            ],
          );
        },
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

// Custom Painter for Animated Background
class HomeBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final ColorScheme colorScheme;

  HomeBackgroundPainter({
    required this.animation,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create subtle gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.surface,
        colorScheme.surfaceContainer.withOpacity(0.5),
        colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final backgroundPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw floating health-themed elements
    final shapePaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final progress = animation.value;
    
    // Animated health elements
    _drawHealthElements(canvas, size, shapePaint, progress);
  }

  void _drawHealthElements(Canvas canvas, Size size, Paint paint, double progress) {
    // Floating hearts (for health)
    for (int i = 0; i < 3; i++) {
      final heartX = size.width * (0.2 + i * 0.3) + math.sin(progress * 2 * math.pi + i) * 20;
      final heartY = size.height * (0.1 + i * 0.2) + math.cos(progress * 2 * math.pi + i) * 15;
      
      _drawHeart(canvas, Offset(heartX, heartY), 15, paint);
    }

    // Floating step icons
    for (int i = 0; i < 4; i++) {
      final stepX = size.width * (0.1 + i * 0.25) + math.cos(progress * 2 * math.pi + i * 0.5) * 15;
      final stepY = size.height * (0.6 + i * 0.1) + math.sin(progress * 2 * math.pi + i * 0.5) * 10;
      
      _drawFootprint(canvas, Offset(stepX, stepY), 12, paint);
    }

    // Floating water drops
    for (int i = 0; i < 5; i++) {
      final dropX = size.width * (0.15 + i * 0.15) + math.sin(progress * 2 * math.pi + i * 0.8) * 12;
      final dropY = size.height * (0.8 + i * 0.05) + math.cos(progress * 2 * math.pi + i * 0.8) * 8;
      
      _drawWaterDrop(canvas, Offset(dropX, dropY), 8, paint);
    }

    // Decorative circles
    for (int i = 0; i < 6; i++) {
      final circleX = size.width * (0.05 + i * 0.18) + math.sin(progress * 2 * math.pi + i * 0.3) * 8;
      final circleY = size.height * (0.05 + i * 0.15) + math.cos(progress * 2 * math.pi + i * 0.3) * 6;
      
      canvas.drawCircle(Offset(circleX, circleY), 3, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 0.5, center.dy - size * 0.1,
      center.dx - size * 0.5, center.dy + size * 0.3,
      center.dx, center.dy + size * 0.7,
    );
    path.cubicTo(
      center.dx + size * 0.5, center.dy + size * 0.3,
      center.dx + size * 0.5, center.dy - size * 0.1,
      center.dx, center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  void _drawFootprint(Canvas canvas, Offset center, double size, Paint paint) {
    // Main foot
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 0.6, height: size),
      paint,
    );
    
    // Toes
    for (int i = 0; i < 5; i++) {
      final toeX = center.dx - size * 0.2 + i * size * 0.1;
      final toeY = center.dy - size * 0.4;
      canvas.drawCircle(Offset(toeX, toeY), size * 0.08, paint);
    }
  }

  void _drawWaterDrop(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(
      center.dx + size * 0.5, center.dy - size * 0.5,
      center.dx + size * 0.5, center.dy,
    );
    path.quadraticBezierTo(
      center.dx + size * 0.5, center.dy + size * 0.5,
      center.dx, center.dy + size * 0.5,
    );
    path.quadraticBezierTo(
      center.dx - size * 0.5, center.dy + size * 0.5,
      center.dx - size * 0.5, center.dy,
    );
    path.quadraticBezierTo(
      center.dx - size * 0.5, center.dy - size * 0.5,
      center.dx, center.dy - size,
    );
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced Gradient Card Widget
class HealthGradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final EdgeInsets? padding;

  const HealthGradientCard({
    super.key,
    required this.child,
    required this.gradientColors,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
