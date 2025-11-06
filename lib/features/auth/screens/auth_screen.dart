// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\auth\screens\auth_screen.dart

// lib/features/auth/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';

class AuthScreen extends StatefulWidget {
  final String? initialError;
  final bool isChildMode;
  const AuthScreen({super.key, this.initialError, this.isChildMode = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String _error = '';
  bool _isLoading = false;
  
  late AnimationController _bubbleController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialError != null) {
      _error = widget.initialError!;
    }
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isLoading) {
      print('AuthScreen: Sign-in already in progress, ignoring duplicate request');
      return;
    }
    
    if(mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }
    
    try {
      print('AuthScreen: Starting Google Sign-In...');
      User? user = await _authService.signInWithGoogle();
      if (user == null) {
        if(mounted){
          setState(() {
            _error = 'Google Sign In was cancelled. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        print('AuthScreen: Google Sign-In successful for user: ${user.email}');
        
        // After successful sign-in, we need to ensure navigation happens
        // Since AuthWrapper should handle this, we'll show loading state
        // but also set a timeout that will force navigation if needed
        if (mounted) {
          setState(() {
            _error = '';
            _isLoading = true;
          });
        }
        
        // Wait briefly for the AuthWrapper's StreamBuilder to detect the auth state change
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // After waiting, if we're still mounted and still loading, 
        // the AuthWrapper might need more time to process the state change
        // But in most cases, the StreamBuilder should have triggered navigation by now
        print('AuthScreen: Google Sign-In completed, expecting AuthWrapper to handle navigation');
      }
    } catch (e) {
      print('AuthScreen: Google Sign-In error: $e');
      if(mounted){
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchTermsAndConditions() async {
    final Uri url = Uri.parse('https://health-trkd-termsandconditions.netlify.app');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Terms and Conditions')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome to TRKD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated Background with Bubbles
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, child) {
              return CustomPaint(
                painter: BubbleBackgroundPainter(
                  animation: _bubbleController,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon with Glass Effect
                        GlassContainer(
                          padding: const EdgeInsets.all(24),
                          borderRadius: 30,
                          blur: 20,
                          opacity: 0.2,
                          gradientColors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // App Title with Gradient Text
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.8),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Health-TRKD',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 36,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtitle with Glass Effect
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          borderRadius: 30,
                          blur: 15,
                          opacity: 0.15,
                          gradientColors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          child: Text(
                            'Your personal health and activity tracker.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                        ),
                        const SizedBox(height: 60),
                        
                        // Sign In Button or Loading
                        _isLoading
                            ? GlassContainer(
                                padding: const EdgeInsets.all(24),
                                borderRadius: 20,
                                blur: 15,
                                opacity: 0.15,
                                gradientColors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Signing you in...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  GlassButton(
                                    text: 'Sign in with Google',
                                    icon: Icons.g_mobiledata_rounded,
                                    onPressed: _signInWithGoogle,
                                    isPrimary: false,
                                    borderRadius: 20,
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                                  ),
                                  const SizedBox(height: 16),
                                  GlassContainer(
                                    padding: const EdgeInsets.all(16),
                                    borderRadius: 16,
                                    blur: 10,
                                    opacity: 0.1,
                                    gradientColors: [
                                      Colors.blue.withOpacity(0.2),
                                      Colors.blue.withOpacity(0.1),
                                    ],
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'No internet? The app will work in demo mode.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),
                        
                        // Error Display
                        if (_error.isNotEmpty)
                          GlassContainer(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            borderRadius: 16,
                            blur: 10,
                            opacity: 0.15,
                            gradientColors: [
                              Colors.red.withOpacity(0.3),
                              Colors.red.withOpacity(0.2),
                            ],
                            border: Border.all(
                              color: Colors.red.withOpacity(0.4),
                              width: 1.5,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Terms & Conditions
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 16,
                          blur: 10,
                          opacity: 0.1,
                          gradientColors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: 'By signing in, you agree to our ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _launchTermsAndConditions,
                                ),
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
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Animated Bubble Background
class BubbleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  BubbleBackgroundPainter({
    required this.animation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create health-themed gradient background
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark ? [
        const Color(0xFF0D3B47),  // Deep teal
        const Color(0xFF1A4D5C),  // Dark cyan
        const Color(0xFF0F5257),  // Medical teal
        const Color(0xFF1B6B6F),  // Turquoise
      ] : [
        const Color(0xFF4ECDC4),  // Medical turquoise
        const Color(0xFF44A08D),  // Healing green
        const Color(0xFF56CCF2),  // Healthcare blue
        const Color(0xFF2D9CDB),  // Medical blue
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final backgroundPaint = Paint()
      ..shader = backgroundGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw animated medical icons (replacing bubbles)
    final medicalIcons = _generateMedicalIcons(size);
    
    for (final icon in medicalIcons) {
      final progress = (animation.value + icon.offset) % 1.0;
      final y = size.height + icon.radius - (size.height + icon.radius * 2) * progress;
      
      // Create icon glow gradient
      final iconGradient = RadialGradient(
        colors: [
          icon.color.withOpacity(0.3),
          icon.color.withOpacity(0.1),
          icon.color.withOpacity(0.05),
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final iconPaint = Paint()
        ..shader = iconGradient.createShader(
          Rect.fromCircle(
            center: Offset(icon.x, y),
            radius: icon.radius,
          ),
        );

      // Draw icon glow effect
      canvas.drawCircle(
        Offset(icon.x, y),
        icon.radius,
        iconPaint,
      );

      // Draw medical cross or heart shape
      if (icon.type == MedicalIconType.cross) {
        _drawMedicalCross(canvas, Offset(icon.x, y), icon.radius * 0.5, icon.color);
      } else if (icon.type == MedicalIconType.heart) {
        _drawHeartbeat(canvas, Offset(icon.x, y), icon.radius * 0.6, icon.color);
      } else {
        _drawPill(canvas, Offset(icon.x, y), icon.radius * 0.5, icon.color);
      }
    }
  }

  void _drawMedicalCross(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size * 0.4, height: size * 1.2),
        Radius.circular(size * 0.1),
      ),
      paint,
    );

    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size * 1.2, height: size * 0.4),
        Radius.circular(size * 0.1),
      ),
      paint,
    );
  }

  void _drawHeartbeat(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.15
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.5, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.4);
    path.lineTo(center.dx, center.dy + size * 0.2);
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.6);
    path.lineTo(center.dx + size * 0.5, center.dy);
    path.lineTo(center.dx + size, center.dy);

    canvas.drawPath(path, paint);
  }

  void _drawPill(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw capsule shape
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size * 1.5, height: size * 0.8),
        Radius.circular(size * 0.4),
      ),
      paint,
    );

    // Draw dividing line
    final linePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08;

    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.4),
      Offset(center.dx, center.dy + size * 0.4),
      linePaint,
    );
  }

  List<MedicalIcon> _generateMedicalIcons(Size size) {
    final icons = <MedicalIcon>[];
    final random = math.Random(42); // Fixed seed for consistent animation

    // Generate different medical icons
    for (int i = 0; i < 15; i++) {
      icons.add(MedicalIcon(
        x: random.nextDouble() * size.width,
        radius: 20 + random.nextDouble() * 60,
        color: _getMedicalIconColor(i),
        offset: random.nextDouble(),
        type: MedicalIconType.values[i % MedicalIconType.values.length],
      ));
    }

    return icons;
  }

  Color _getMedicalIconColor(int index) {
    final colors = isDark ? [
      const Color(0xFF4ECDC4),  // Medical turquoise
      const Color(0xFF56CCF2),  // Healthcare blue
      const Color(0xFF6FCF97),  // Healing green
      const Color(0xFF5DADE2),  // Medical blue
      const Color(0xFF48C9B0),  // Mint green
    ] : [
      const Color(0xFFFFFFFF),  // White
      const Color(0xFFF0F8FF),  // Alice blue
      const Color(0xFFE8F8F5),  // Mint cream
      const Color(0xFFEBF5FB),  // Light blue
      const Color(0xFFE8F6F3),  // Light mint
    ];
    
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum MedicalIconType {
  cross,
  heart,
  pill,
}

class MedicalIcon {
  final double x;
  final double radius;
  final Color color;
  final double offset;
  final MedicalIconType type;

  MedicalIcon({
    required this.x,
    required this.radius,
    required this.color,
    required this.offset,
    required this.type,
  });
}
