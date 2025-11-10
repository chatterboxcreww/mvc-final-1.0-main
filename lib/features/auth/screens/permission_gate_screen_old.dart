// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\auth\screens\permission_gate_screen.dart

// lib/features/auth/screens/permission_gate_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_wrapper.dart';
import 'dart:math' as math;

class PermissionGateScreen extends StatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAnimations();
        _handlePermissions();
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handlePermissions() async {
    try {
      print('PermissionGate: Starting permission check process...');

      // First check current permission statuses without requesting
      final Map<Permission, PermissionStatus> currentStatuses = {
        Permission.notification: await Permission.notification.status,
        Permission.activityRecognition: await Permission.activityRecognition.status,
        Permission.scheduleExactAlarm: await Permission.scheduleExactAlarm.status,
      };

      print('PermissionGate: Current Permission Status:');
      currentStatuses.forEach((permission, status) {
        print('  - ${permission.toString().split('.').last}: $status');
      });

      // Check if critical permissions are missing
      final notificationGranted = currentStatuses[Permission.notification]?.isGranted ?? false;
      final activityGranted = currentStatuses[Permission.activityRecognition]?.isGranted ?? false;

      // If critical permissions are missing, request them
      if (!notificationGranted || !activityGranted) {
        print('PermissionGate: Critical permissions missing, requesting...');

        // Show permission request dialog first
        if (mounted) {
          await _showPermissionRequestDialog();
        }

        // Request permissions with better error handling
        final Map<Permission, PermissionStatus> requestResults = {};
        try {
          requestResults.addAll(await [
            Permission.notification,
            Permission.activityRecognition,
            Permission.scheduleExactAlarm,
          ].request());
        } catch (e) {
          print('PermissionGate: Error during permission request: $e');
          // Continue with current statuses if request fails
        }

        print('PermissionGate: Permission Request Results:');
        requestResults.forEach((permission, status) {
          print('  - ${permission.toString().split('.').last}: $status');
        });

        // Check final status after request
        final finalNotificationStatus = requestResults[Permission.notification]?.isGranted ?? currentStatuses[Permission.notification]?.isGranted ?? false;
        final finalActivityStatus = requestResults[Permission.activityRecognition]?.isGranted ?? currentStatuses[Permission.activityRecognition]?.isGranted ?? false;

        if (mounted) {
          if (!finalNotificationStatus || !finalActivityStatus) {
            // Show dialog explaining why permissions are needed
            _showPermissionDeniedDialog();
          } else {
            print('PermissionGate: All critical permissions granted, proceeding...');
            _navigateToAuthWrapper();
          }
        }
      } else {
        print('PermissionGate: All permissions already granted, proceeding...');
        if (mounted) {
          _navigateToAuthWrapper();
        }
      }
    } catch (e) {
      print('PermissionGate: Error handling permissions: $e');
      if (mounted) {
        // Continue to app even if permission request fails
        _navigateToAuthWrapper();
      }
    }
  }

  Future<void> _showPermissionRequestDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Permissions Needed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Health-TRKD needs these permissions for the best experience:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              context,
              Icons.notifications_rounded,
              'Notifications',
              'Health reminders and alerts',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              context,
              Icons.directions_walk_rounded,
              'Activity Recognition',
              'Step counting and activity tracking',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              context,
              Icons.alarm_rounded,
              'Exact Alarms',
              'Precise reminder timing',
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Grant Permissions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(BuildContext context, IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Permissions Denied',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Some permissions were denied. This may affect app functionality:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildIssueItem(context, '• Step tracking may not be accurate'),
                  _buildIssueItem(context, '• Health reminders won\'t be delivered'),
                  _buildIssueItem(context, '• Background sync may not work'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can enable permissions later in:\nSettings > Apps > Health-TRKD > Permissions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToAuthWrapper();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Continue Anyway'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Open Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  void _navigateToAuthWrapper() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isVerySmallScreen = size.height < 600;
    final screenWidth = size.width;
    
    // Responsive sizing
    final logoSize = isVerySmallScreen ? 80.0 : (isSmallScreen ? 100.0 : 120.0);
    final titleFontSize = isVerySmallScreen ? 24.0 : (isSmallScreen ? 28.0 : 32.0);
    final subtitleFontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 15.0 : null);
    final horizontalPadding = screenWidth < 360 ? 16.0 : (screenWidth < 400 ? 20.0 : 24.0);
    final verticalSpacing = isVerySmallScreen ? 20.0 : (isSmallScreen ? 30.0 : 40.0);
    
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
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_pulseController.value * 2 * math.pi + index) * 20,
                        math.cos(_pulseController.value * 2 * math.pi + index) * 20,
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
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isVerySmallScreen ? 12 : 16,
                ),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 
                              MediaQuery.of(context).padding.top - 
                              MediaQuery.of(context).padding.bottom - 
                              (isVerySmallScreen ? 24 : 32),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          // Animated App Icon with pulse effect
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
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
                              );
                            },
                          ),
                          SizedBox(height: verticalSpacing),
                          
                          // App Name
                          Text(
                            'Health-TRKD',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: titleFontSize,
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
                          SizedBox(height: isVerySmallScreen ? 12 : 16),
                          
                          // Subtitle
                          Text(
                            'Your Personal Health Companion',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: subtitleFontSize,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 48)),
                          
                          // Animated Loading Indicator
                          Container(
                            padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: isVerySmallScreen ? 32 : 40,
                                  height: isVerySmallScreen ? 32 : 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: isVerySmallScreen ? 2.5 : 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isVerySmallScreen ? 12 : 16),
                                Text(
                                  'Setting up your health companion...',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 15 : null),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isVerySmallScreen ? 6 : 8),
                                Text(
                                  'Checking and requesting necessary permissions',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : null),
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 40)),
                          
                          // Permission indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildPermissionIndicator(
                                context,
                                Icons.notifications_rounded,
                                'Notifications',
                                isVerySmallScreen,
                              ),
                              _buildPermissionIndicator(
                                context,
                                Icons.directions_walk_rounded,
                                'Activity',
                                isVerySmallScreen,
                              ),
                              _buildPermissionIndicator(
                                context,
                                Icons.alarm_rounded,
                                'Alarms',
                                isVerySmallScreen,
                              ),
                            ],
                          ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionIndicator(BuildContext context, IconData icon, String label, bool isVerySmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(isVerySmallScreen ? 10 : 12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isVerySmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: isVerySmallScreen ? 11 : 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
