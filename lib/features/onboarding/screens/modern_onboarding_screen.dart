// lib/features/onboarding/screens/modern_onboarding_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/health_info_card.dart';
import 'personal_info_screen.dart';

class ModernOnboardingScreen extends StatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  State<ModernOnboardingScreen> createState() => _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState extends State<ModernOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Welcome to Health-TRKD",
      subtitle: "Your Personal Health Journey Starts Here",
      description: "Track your daily activities, monitor your progress, and achieve your health goals with our comprehensive wellness platform.",
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      benefits: [
        "Real-time step tracking",
        "Personalized health insights",
        "Achievement system",
        "Social challenges"
      ],
    ),
    OnboardingData(
      title: "Smart Activity Tracking",
      subtitle: "Every Step Counts Towards Your Goals",
      description: "Our advanced tracking system monitors your daily activities automatically. From steps to water intake, we help you stay on top of your health metrics.",
      icon: Icons.directions_walk_rounded,
      gradient: [Color(0xFF00c6ff), Color(0xFF0072ff)],
      benefits: [
        "Automatic step counting",
        "Water intake reminders",
        "Sleep pattern analysis",
        "Workout recommendations"
      ],
    ),
    OnboardingData(
      title: "Personalized Health Insights",
      subtitle: "Data-Driven Wellness Recommendations",
      description: "Get personalized recommendations based on your health data, lifestyle, and goals. Our AI analyzes your patterns to provide actionable insights.",
      icon: Icons.insights_rounded,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
      benefits: [
        "Custom health reports",
        "Trend analysis",
        "Goal adjustments",
        "Health predictions"
      ],
    ),
    OnboardingData(
      title: "Community & Motivation",
      subtitle: "Achieve More Together",
      description: "Join a community of health enthusiasts. Share your progress, participate in challenges, and stay motivated with friends and family.",
      icon: Icons.groups_rounded,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      benefits: [
        "Social challenges",
        "Leaderboards",
        "Share achievements",
        "Find workout buddies"
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _slideController.forward().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _slideController.reset();
      });
    } else {
      _startPersonalization();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startPersonalization() {
    Navigator.of(context).pushFluid(const PersonalInfoScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: _pages[_currentPage].gradient,
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      ModernButton(
                        text: "Back",
                        isSecondary: true,
                        onPressed: _previousPage,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      )
                    else
                      const SizedBox(width: 80),
                    TextButton(
                      onPressed: _startPersonalization,
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeController,
                      child: _buildPage(_pages[index]),
                    );
                  },
                ),
              ),
              
              // Page indicator and navigation
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    OnboardingPageIndicator(
                      currentPage: _currentPage,
                      pageCount: _pages.length,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ModernButton(
                            text: _currentPage == _pages.length - 1 
                                ? "Get Started" 
                                : "Continue",
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _nextPage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Benefits
          HealthInfoCard(
            benefits: data.benefits,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<String> benefits;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.benefits,
  });
}
