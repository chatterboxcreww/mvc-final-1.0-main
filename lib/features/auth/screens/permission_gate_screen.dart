// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\auth\screens\permission_gate_screen.dart

// lib/features/auth/screens/permission_gate_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_wrapper.dart';

class PermissionGateScreen extends StatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen> {
  @override
  void initState() {
    super.initState();
    _handlePermissions();
  }

  Future<void> _handlePermissions() async {
    try {
      print('PermissionGate: Starting permission check process...');
      
      // First check current permission statuses without requesting
      final Map<Permission, PermissionStatus> currentStatuses = {
        Permission.notification: await Permission.notification.status,
        Permission.activityRecognition: await Permission.activityRecognition.status,
        Permission.scheduleExactAlarm: await Permission.scheduleExactAlarm.status,
        Permission.sensors: await Permission.sensors.status,
        Permission.location: await Permission.location.status,
        Permission.locationWhenInUse: await Permission.locationWhenInUse.status,
        Permission.ignoreBatteryOptimizations: await Permission.ignoreBatteryOptimizations.status,
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
        
        // Request permissions
        final Map<Permission, PermissionStatus> requestResults = await [
          Permission.notification,
          Permission.activityRecognition,
          Permission.scheduleExactAlarm,
          Permission.sensors,
          Permission.location,
          Permission.locationWhenInUse,
          Permission.ignoreBatteryOptimizations,
        ].request();

        print('PermissionGate: Permission Request Results:');
        requestResults.forEach((permission, status) {
          print('  - ${permission.toString().split('.').last}: $status');
        });

        // Check final status after request
        final finalNotificationStatus = requestResults[Permission.notification]?.isGranted ?? false;
        final finalActivityStatus = requestResults[Permission.activityRecognition]?.isGranted ?? false;

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
        title: Row(
          children: [
            Icon(
              Icons.security_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Permissions Needed'),
          ],
        ),
        content: const Text(
            'Health-TRKD needs the following permissions to provide you with the best health tracking experience:\n\n'
            '🔔 Notifications - Health reminders and alerts\n'
            '🚶 Activity Recognition - Step counting and activity tracking\n'
            '📱 Sensors - Accurate health monitoring\n'
            '📍 Location - Activity context (optional)\n'
            '🔋 Battery Optimization - Background tracking\n\n'
            'These permissions help us track your health data accurately and send you helpful reminders.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Grant Permissions'),
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
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Permissions Denied'),
          ],
        ),
        content: const Text(
            'Some critical permissions were denied. Health-TRKD may not work properly without them:\n\n'
            '• Step tracking may not be accurate\n'
            '• Health reminders won\'t be delivered\n'
            '• Background sync may not work\n\n'
            'You can grant these permissions later in Settings > Apps > Health-TRKD > Permissions.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAuthWrapper();
            },
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
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
    // Show a loading screen while permissions are being checked
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Name
              Text(
                'Health-TRKD',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Loading Indicator
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              
              // Status Text
              Text(
                'Setting up your health companion...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Checking and requesting necessary permissions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
