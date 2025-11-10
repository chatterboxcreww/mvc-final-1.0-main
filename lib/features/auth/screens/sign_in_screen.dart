// lib/features/auth/screens/sign_in_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignIn;

  const SignInScreen({super.key, required this.onSignIn});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    try {
      widget.onSignIn();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isVerySmallScreen = size.height < 600;
    final screenWidth = size.width;
    
    // Responsive sizing
    final logoSize = isVerySmallScreen ? 80.0 : (isSmallScreen ? 100.0 : 120.0);
    final titleFontSize = isVerySmallScreen ? 32.0 : (isSmallScreen ? 36.0 : 42.0);
    final subtitleFontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final verticalSpacing = isVerySmallScreen ? 20.0 : (isSmallScreen ? 30.0 : 40.0);
    final horizontalPadding = screenWidth < 360 ? 16.0 : (screenWidth < 400 ? 24.0 : 32.0);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF833AB4), // Instagram purple
              const Color(0xFFFD1D1D), // Instagram red
              const Color(0xFFFCAF45), // Instagram orange/yellow
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated medical icons background
            ...List.generate(6, (index) {
              final iconTypes = [
                Icons.favorite_rounded,
                Icons.local_hospital_rounded,
                Icons.medical_services_rounded,
                Icons.health_and_safety_rounded,
                Icons.monitor_heart_rounded,
                Icons.medication_rounded,
              ];
              return Positioned(
                left: (index % 3) * size.width / 3,
                top: (index ~/ 3) * size.height / 2,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_animationController.value * 2 * math.pi + index) * 20,
                        math.cos(_animationController.value * 2 * math.pi + index) * 20,
                      ),
                      child: Opacity(
                        opacity: 0.15,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: Icon(
                            iconTypes[index],
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            
            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isVerySmallScreen ? 16 : 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App logo/icon - Instagram themed
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF833AB4),
                                  const Color(0xFFFD1D1D),
                                  const Color(0xFFFCAF45),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.health_and_safety_rounded,
                              size: logoSize * 0.5,
                              color: Colors.white,
                            ),
                          ),
                          
                          SizedBox(height: verticalSpacing),
                          
                          // App title
                          Text(
                            'Health-TRKD',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 8 : 16),
                          
                          // Subtitle
                          Text(
                            'Track Your Health Journey',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 60)),
                          
                          // Sign in button
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(maxWidth: screenWidth > 600 ? 400 : double.infinity),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: _isLoading ? null : _handleSignIn,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isVerySmallScreen ? 14 : 18,
                                    horizontal: isVerySmallScreen ? 20 : 32,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isLoading)
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation(
                                              const Color(0xFF833AB4),
                                            ),
                                          ),
                                        )
                                      else ...[
                                        Image.asset(
                                          'assets/google_logo.png',
                                          width: 24,
                                          height: 24,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.login_rounded,
                                              color: const Color(0xFF833AB4),
                                              size: 24,
                                            );
                                          },
                                        ),
                                        SizedBox(width: isVerySmallScreen ? 12 : 16),
                                        Flexible(
                                          child: Text(
                                            'Sign in with Google',
                                            style: TextStyle(
                                              fontSize: isVerySmallScreen ? 16 : 18,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF833AB4),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 40)),
                          
                          // Features list
                          Container(
                            constraints: BoxConstraints(maxWidth: screenWidth > 600 ? 400 : double.infinity),
                            child: Column(
                              children: [
                                _buildFeatureItem(
                                  Icons.track_changes_rounded,
                                  'Track daily health metrics',
                                  isVerySmallScreen,
                                ),
                                SizedBox(height: isVerySmallScreen ? 12 : 16),
                                _buildFeatureItem(
                                  Icons.insights_rounded,
                                  'Get personalized insights',
                                  isVerySmallScreen,
                                ),
                                SizedBox(height: isVerySmallScreen ? 12 : 16),
                                _buildFeatureItem(
                                  Icons.emoji_events_rounded,
                                  'Achieve your health goals',
                                  isVerySmallScreen,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isVerySmallScreen) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isVerySmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isVerySmallScreen ? 18 : 20,
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 12 : 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isVerySmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ),
      ],
    );
  }
}

