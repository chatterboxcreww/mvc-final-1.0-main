// lib/features/onboarding/screens/first_time_tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';

class FirstTimeTutorialScreen extends StatefulWidget {
  const FirstTimeTutorialScreen({super.key});

  @override
  State<FirstTimeTutorialScreen> createState() => _FirstTimeTutorialScreenState();
}

class _FirstTimeTutorialScreenState extends State<FirstTimeTutorialScreen> 
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;

  final List<TutorialStep> _steps = [
    TutorialStep(
      title: '👋 Welcome to Health-TRKD!',
      description: 'Your personal health and wellness companion. Let\'s take a quick tour of the app features.',
      icon: Icons.waving_hand_rounded,
      color: Colors.blue,
    ),
    TutorialStep(
      title: '🚶 Step Tracker',
      description: 'Automatically tracks your daily steps, distance, and calories burned. Tap the card to view detailed history and build your streak!',
      icon: Icons.directions_walk_rounded,
      color: Colors.green,
    ),
    TutorialStep(
      title: '💧 Water Tracker',
      description: 'Log your water intake with a tap. Watch the animated glass fill up and earn XP for staying hydrated throughout the day.',
      icon: Icons.water_drop_rounded,
      color: Colors.blue,
    ),
    TutorialStep(
      title: '⭐ Experience & Levels',
      description: 'Earn XP for healthy activities and level up! Complete tasks, drink water, hit step goals, and unlock achievements.',
      icon: Icons.emoji_events_rounded,
      color: Colors.amber,
    ),
    TutorialStep(
      title: '🍽️ Personalized Feed',
      description: 'Get meal suggestions tailored to your dietary preferences, health conditions, and allergies. Tap recipes for detailed instructions!',
      icon: Icons.restaurant_menu_rounded,
      color: Colors.orange,
    ),
    TutorialStep(
      title: '✅ Daily Progress',
      description: 'Track your mood, sleep, and custom activities. Set reminders for healthy habits and watch your completion percentage grow!',
      icon: Icons.task_alt_rounded,
      color: Colors.purple,
    ),
    TutorialStep(
      title: '📊 Trends & Insights',
      description: 'Visualize your health data over time. Get AI-powered insights and understand your patterns to make better decisions.',
      icon: Icons.analytics_rounded,
      color: Colors.teal,
    ),
    TutorialStep(
      title: '🎯 You\'re All Set!',
      description: 'Start your health journey today! Log water, track steps, complete check-ins, and explore all features. Every small step counts! 🌟',
      icon: Icons.celebration_rounded,
      color: Colors.pink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _completeTutorial,
            child: Text(
              'Skip',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: _animationController,
                colorScheme: colorScheme,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Page indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Tutorial pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return _buildTutorialPage(_steps[index]);
                    },
                  ),
                ),
                
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        GlassButton(
                          text: 'Back',
                          icon: Icons.arrow_back,
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          isPrimary: false,
                        )
                      else
                        const SizedBox(width: 100),
                      
                      GlassButton(
                        text: _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                        icon: _currentPage == _steps.length - 1 
                            ? Icons.check_circle 
                            : Icons.arrow_forward,
                        onPressed: () {
                          if (_currentPage == _steps.length - 1) {
                            _completeTutorial();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage(TutorialStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          GlassContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: 40,
            shape: BoxShape.circle,
            gradientColors: [
              step.color.withOpacity(0.2),
              step.color.withOpacity(0.1),
            ],
            border: Border.all(
              color: step.color.withOpacity(0.3),
              width: 2,
            ),
            child: Icon(
              step.icon,
              size: 80,
              color: step.color,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Description
          GlassCard(
            child: Text(
              step.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
