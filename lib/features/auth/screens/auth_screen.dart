// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\auth\screens\auth_screen.dart

// lib/features/auth/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final String? initialError;
  final bool isChildMode;
  const AuthScreen({super.key, this.initialError, this.isChildMode = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  String _error = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialError != null) {
      _error = widget.initialError!;
    }
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
    // Rely on ThemeData for button styling
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome to TRKD',
          style: TextStyle(
            color: isDark ? colorScheme.onSurface : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? colorScheme.onSurface : Colors.white,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [
              // Dark theme gradient - darker colors with better contrast
              Color.fromRGBO(33, 37, 52, 1.0),  // Dark blue-gray
              Color.fromRGBO(24, 31, 47, 1.0),  // Darker blue-gray  
              Color.fromRGBO(18, 24, 36, 1.0),  // Very dark blue
              colorScheme.surface,
            ] : [
              // Light theme gradient - teal gradient for better visual appeal
              const Color(0xFF00796B),     // Deep teal
              const Color(0xFF26A69A),     // Medium teal  
              const Color(0xFF4DB6AC),     // Light teal
              const Color(0xFFE0F2F1),     // Very light teal
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.healing_outlined, 
                      size: 80, 
                      color: isDark ? colorScheme.primary : const Color(0xFF00796B),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Health-TRKD',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? colorScheme.onSurface : Colors.white,
                      fontSize: 32,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(isDark ? 0.1 : 0.4),
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? colorScheme.surfaceContainer.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Your personal health and activity tracker.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark 
                            ? colorScheme.onSurface 
                            : const Color(0xFF2E2E2E),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 60),
                  _isLoading
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark ? [
                                colorScheme.primaryContainer,
                                colorScheme.primaryContainer.withValues(alpha: 0.8),
                              ] : [
                                Colors.white,
                                Colors.white.withValues(alpha: 0.95),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: isDark 
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _signInWithGoogle,
                            // Apply specific overrides for Google button if needed, but M3 defaults are good
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: isDark ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                              minimumSize: const Size(double.infinity, 56),
                              elevation: 0,
                            ),
                            icon: Image.asset('assets/google_logo.png', height: 24.0), // Ensure asset exists
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  if (_error.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(colorScheme.errorContainer.red, colorScheme.errorContainer.green, colorScheme.errorContainer.blue, 0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer, 
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? colorScheme.surfaceContainer.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ) : null,
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'By signing in, you agree to our ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: colorScheme.primary, // Use primary color for links
                              decoration: TextDecoration.underline,
                              fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                              fontWeight: FontWeight.w600,
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
    );
  }
}
