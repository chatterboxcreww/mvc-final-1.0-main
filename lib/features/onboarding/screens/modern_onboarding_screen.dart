// lib/features/onboarding/screens/modern_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/health_info_card.dart';
import 'personal_info_screen.dart';
import 'dart:math' as math;

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
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Welcome to Health-TRKD",
      subtitle: "Your Personal Health & Wellness Companion",
      description: "Start your health journey with our comprehensive tracking platform. Monitor daily activities, set personal goals, and build healthy habits with helpful insights and progress tracking.",
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      benefits: [
        "🚶 Daily step & activity tracking",
        "💧 Water intake monitoring", 
        "🎯 Personal health goal setting",
        "🏆 Achievement & progress system",
        "📊 Health analytics & insights"
      ],
      features: [
        "Track multiple health metrics",
        "Set and monitor personal goals",
        "View progress over time",
        "Secure local data storage"
      ],
    ),
    OnboardingData(
      title: "Activity & Step Tracking",
      subtitle: "Every Step Counts Towards Your Goals",
      description: "Our tracking system monitors your daily activities including steps, water intake, and other health metrics. Stay motivated with progress tracking and helpful reminders.",
      icon: Icons.directions_walk_rounded,
      gradient: [Color(0xFF00c6ff), Color(0xFF0072ff)],
      benefits: [
        "📱 Step counting throughout the day",
        "💧 Hydration tracking & reminders",
        "📈 Progress visualization",
        "⏰ Customizable reminder notifications",
        "📊 Weekly & monthly summaries"
      ],
      features: [
        "Background step tracking",
        "Battery efficient operation",
        "Works without internet connection",
        "Customizable daily goals"
      ],
    ),
    OnboardingData(
      title: "Health Insights & Analytics",
      subtitle: "Understand Your Health Patterns",
      description: "View your health data through charts and trends. Track your progress over time and identify patterns in your daily activities to make informed decisions about your wellness.",
      icon: Icons.insights_rounded,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
      benefits: [
        "📈 Visual progress charts",
        "📅 Daily, weekly, monthly views",
        "🎯 Goal achievement tracking",
        "📋 Health summary reports",
        "🔍 Pattern identification"
      ],
      features: [
        "Interactive charts and graphs",
        "Historical data analysis",
        "Export your health data",
        "Privacy-focused design"
      ],
    ),
    OnboardingData(
      title: "Achievements & Motivation",
      subtitle: "Celebrate Your Health Milestones",
      description: "Stay motivated with our achievement system. Unlock badges, track streaks, and celebrate your health milestones as you build lasting healthy habits.",
      icon: Icons.emoji_events_rounded,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      benefits: [
        "🏅 Achievement badges & rewards",
        "🔥 Daily & weekly streaks",
        "🎉 Milestone celebrations",
        "📈 Progress level system",
        "💪 Personal challenges"
      ],
      features: [
        "Unlock achievements as you progress",
        "Track your longest streaks",
        "Set personal challenges",
        "Celebrate health victories"
      ],
    ),
    OnboardingData(
      title: "Ready to Start Your Journey?",
      subtitle: "Begin Building Healthier Habits Today",
      description: "Start your personalized health journey with Health-TRKD. Track your progress, build healthy habits, and achieve your wellness goals one step at a time.",
      icon: Icons.rocket_launch_rounded,
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
      benefits: [
        "🚀 Quick & easy setup",
        "📱 Works on your device",
        "🔒 Your data stays private",
        "🆓 Free to use",
        "📈 Start tracking immediately"
      ],
      features: [
        "No account required to start",
        "All data stored locally",
        "Simple, intuitive interface",
        "Regular app improvements"
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Set full screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Animated Background with Particles
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return CustomPaint(
                painter: OnboardingBackgroundPainter(
                  animation: _floatingController,
                  colors: _pages[_currentPage].gradient,
                  currentPage: _currentPage,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Main Content
          Column(
            children: [
              // Top Navigation Bar
              Container(
                height: MediaQuery.of(context).padding.top + 60,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                ),
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
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        foregroundColor: Colors.white.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    // Haptic feedback
                    HapticFeedback.lightImpact();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeController,
                      child: _buildPage(_pages[index], screenHeight, screenWidth, isSmallScreen),
                    );
                  },
                ),
              ),
              
              // Bottom Navigation
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  top: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnboardingPageIndicator(
                      currentPage: _currentPage,
                      pageCount: _pages.length,
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _currentPage == _pages.length - 1 ? _pulseAnimation.value : 1.0,
                          child: ModernButton(
                            text: _currentPage == _pages.length - 1 
                                ? "Start Your Health Journey" 
                                : "Continue",
                            icon: _currentPage == _pages.length - 1 
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            onPressed: _nextPage,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data, double screenHeight, double screenWidth, bool isSmallScreen) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: isSmallScreen ? 10 : 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenHeight - 200, // Account for top/bottom navigation
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40),
            
            // Animated Icon with Floating Effect
            AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value),
                  child: Container(
                    width: isSmallScreen ? 100 : 140,
                    height: isSmallScreen ? 100 : 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      data.icon,
                      size: isSmallScreen ? 50 : 70,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: isSmallScreen ? 30 : 50),
            
            // Title with Responsive Typography
            Text(
              data.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                fontSize: isSmallScreen ? 24 : 28,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isSmallScreen ? 8 : 16),
            
            // Subtitle
            Text(
              data.subtitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 16 : 18,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 24),
            
            // Description with Glass Effect
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                data.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 32),
            
            // Benefits Section
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Key Features:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  ...data.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            benefit,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isSmallScreen ? 13 : 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            
            // Additional Features (for comprehensive info)
            if (data.features.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 16 : 24),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Why Choose Health-TRKD:",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    ...data.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isSmallScreen ? 12 : 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
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
  final List<String> features;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.benefits,
    this.features = const [],
  });
}

// Custom Painter for Animated Background
class OnboardingBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;
  final int currentPage;

  OnboardingBackgroundPainter({
    required this.animation,
    required this.colors,
    required this.currentPage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create animated gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: const [0.0, 1.0],
    );

    final backgroundPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw floating particles
    final particles = _generateParticles(size);
    
    for (final particle in particles) {
      final progress = (animation.value + particle.offset) % 1.0;
      final x = particle.x + math.sin(progress * 2 * math.pi) * 20;
      final y = particle.y + math.cos(progress * 2 * math.pi) * 15;
      
      final particlePaint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * (0.5 + 0.5 * math.sin(progress * 2 * math.pi)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(x, y),
        particle.radius,
        particlePaint,
      );
    }

    // Draw decorative shapes
    _drawDecorativeShapes(canvas, size);
  }

  List<Particle> _generateParticles(Size size) {
    final particles = <Particle>[];
    final random = math.Random(currentPage * 42);

    for (int i = 0; i < 20; i++) {
      particles.add(Particle(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        radius: 1 + random.nextDouble() * 3,
        opacity: 0.1 + random.nextDouble() * 0.3,
        offset: random.nextDouble(),
      ));
    }

    return particles;
  }

  void _drawDecorativeShapes(Canvas canvas, Size size) {
    final shapePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw some decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.2),
      50,
      shapePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      30,
      shapePaint,
    );

    // Draw decorative lines
    final path = Path();
    path.moveTo(size.width * 0.8, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.9, size.height * 0.3,
      size.width * 0.7, size.height * 0.4,
    );
    canvas.drawPath(path, shapePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  final double offset;

  Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.offset,
  });
}
