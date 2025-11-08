// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\auth\screens\auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/models/user_data.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../home/screens/home_page.dart';
import '../../onboarding/screens/modern_onboarding_screen.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthService _authService;
  late final NotificationService _notificationService;
  late final StorageService _storageService;
  final Connectivity _connectivity = Connectivity();
  
  bool _hasShownOfflineMessage = false;
  bool _hasAttemptedSilentSignIn = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _notificationService = NotificationService();
    _storageService = StorageService();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (mounted) {
        _handleConnectivityChange(result);
      }
    });
    
    // Attempt silent sign-in on app startup
    _attemptSilentSignIn();
  }

  Future<void> _attemptSilentSignIn() async {
    if (_hasAttemptedSilentSignIn) return;
    _hasAttemptedSilentSignIn = true;
    
    try {
      print('AuthWrapper: Attempting silent sign-in on app startup...');
      final user = await _authService.silentSignIn();
      if (user != null) {
        print('AuthWrapper: Silent sign-in successful');
        // StreamBuilder will automatically rebuild when the user stream updates
      } else {
        print('AuthWrapper: Silent sign-in returned null');
      }
    } catch (e) {
      print('AuthWrapper: Silent sign-in failed: $e');
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (result == ConnectivityResult.none && !_hasShownOfflineMessage) {
      _hasShownOfflineMessage = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Some features may be limited.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (result != ConnectivityResult.none && _hasShownOfflineMessage) {
      _hasShownOfflineMessage = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection restored.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataProvider = context.read<UserDataProvider>();
    
    return StreamBuilder<User?>(
      stream: _authService.user,
      builder: (_, AsyncSnapshot<User?> userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen('Checking authentication...');
        }

        if (userSnapshot.hasError) {
          return const AuthScreen(
            initialError: "Authentication error occurred. Please try again.",
            isChildMode: false,
          );
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          _notificationService.cancelAllNotifications();
          return const AuthScreen(isChildMode: false);
        }

        return FutureBuilder<List<dynamic>>(
          future: _loadUserDataWithRetry(userDataProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen('Loading your health data...');
            }

            if (snapshot.hasError) {
              // Check if it's a network error vs authentication error
              final errorMessage = snapshot.error.toString();
              if (errorMessage.contains('timeout') || errorMessage.contains('network') ||
                  errorMessage.contains('connection') || errorMessage.contains('Failed host lookup')) {
                return _buildRetryScreen(
                  'Connection Problem',
                  'Unable to connect to our servers. Please check your internet connection and try again.',
                  () => setState(() {}), // Trigger rebuild to retry
                );
              } else {
                // For non-network errors, try to continue with cached data
                print('AuthWrapper: Non-network error, attempting to continue with cached data: $errorMessage');
                final userData = userDataProvider.userData;

                // If we have cached user data, proceed to home
                if (userData.name != null && userData.name!.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _navigateToPage(context, const HomePage(), 'HomePage');
                  });
                  return _buildLoadingScreen('Loading from cache...');
                } else {
                  // No cached data, show auth screen
                  return const AuthScreen(
                    initialError: "Unable to load your data. Please sign in again.",
                    isChildMode: false,
                  );
                }
              }
            }

            final bool firestoreDataExists = snapshot.data?[0] ?? false;
            final bool isLocallyOnboarded = snapshot.data?[1] ?? false;
            final userData = userDataProvider.userData;

            // Debug information to help diagnose onboarding issues
            print('AuthWrapper: firestoreDataExists=$firestoreDataExists, isLocallyOnboarded=$isLocallyOnboarded');
            print('AuthWrapper: userData.isProfileComplete=${userData.isProfileComplete}');
            print('AuthWrapper: userData has name=${userData.name != null}, age=${userData.age != null}, height=${userData.height != null}, weight=${userData.weight != null}');
            print('AuthWrapper: userData has dailyStepGoal=${userData.dailyStepGoal != null}, dailyWaterGoal=${userData.dailyWaterGoal != null}');

            // Initialize services if we have user data
            if (userData.name != null && userData.name!.isNotEmpty) {
              _initializeServices(context, userData);
            }

            // Check if we should show homepage or onboarding
            bool shouldShowHomePage = false;

            // Option 1: User has completed onboarding locally
            if (isLocallyOnboarded && userData.isProfileComplete) {
              print('AUTH WRAPPER DEBUG: Both local onboarding complete and profile is complete');
              shouldShowHomePage = true;
            }
            // Option 2: User has all required data in Firestore
            else if (firestoreDataExists && userData.isProfileComplete) {
              print('AUTH WRAPPER DEBUG: Profile complete in Firestore but local flag not set');
              // If we have complete data but onboarding flag not set, set it now
              if (!isLocallyOnboarded) {
                print('AUTH WRAPPER DEBUG: Setting local onboarding flag to true');
                _storageService.setOnboardingComplete(true);
              }
              shouldShowHomePage = true;
            } else {
              print('AUTH WRAPPER DEBUG: Showing onboarding - localOnboarded=$isLocallyOnboarded, profileComplete=${userData.isProfileComplete}');
            }

            // Use post-frame callback for navigation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (shouldShowHomePage) {
                _navigateToPage(context, const HomePage(), 'HomePage');
              } else {
                _navigateToPage(
                  context,
                  const ModernOnboardingScreen(),
                  'ModernOnboardingScreen',
                  useTransition: true
                );
              }
            });

            return _buildLoadingScreen('Preparing your dashboard...');
          },
        );
      },
    );
  }

  Future<List<dynamic>> _loadUserDataWithRetry(UserDataProvider userDataProvider) async {
    int maxRetries = 3;
    int currentAttempt = 0;

    while (currentAttempt < maxRetries) {
      try {
        print('AuthWrapper: Loading user data, attempt ${currentAttempt + 1}');
        
        // Defer the data loading to avoid setState during build
        await Future.delayed(Duration.zero);
        
        final results = await Future.wait<dynamic>([
          userDataProvider.loadUserData(),
          StorageService().isOnboardingComplete(),
        ]).timeout(
          Duration(seconds: 30 + (currentAttempt * 10)), // Increase timeout with each retry
          onTimeout: () => throw Exception('Data loading timeout on attempt ${currentAttempt + 1}'),
        );

        print('AuthWrapper: Data loaded successfully on attempt ${currentAttempt + 1}');
        return results;
      } catch (e) {
        currentAttempt++;
        print('AuthWrapper: Load attempt $currentAttempt failed: $e');
        
        if (currentAttempt >= maxRetries) {
          rethrow;
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(seconds: 2 * currentAttempt));
      }
    }
    
    throw Exception('Failed to load data after $maxRetries attempts');
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryScreen(String title, String message, VoidCallback onRetry) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeServices(BuildContext context, UserData data) {
    try {
      _synchronizeNotifications(context, data);
      context.read<StepCounterProvider>().initialize(data);
    } catch (e) {
      print("AuthWrapper: Error initializing services: $e");
    }
  }

  void _synchronizeNotifications(BuildContext context, UserData data) {
    try {
      if (data.morningWalkReminderEnabled) {
        _notificationService.scheduleMorningWalkReminder(context: context, userData: data);
      } else {
        _notificationService.cancelMorningWalkReminder();
      }

      if (data.waterReminderEnabled) {
        _notificationService.scheduleWaterReminders(context: context, userData: data);
      } else {
        _notificationService.cancelWaterReminders();
      }

      if (data.wakeupNotificationEnabled) {
        _notificationService.scheduleWakeupNotification(context: context, userData: data);
      } else {
        _notificationService.cancelWakeupNotification();
      }

      if (data.sleepNotificationEnabled) {
        _notificationService.scheduleSleepNotification(context: context, userData: data);
      } else {
        _notificationService.cancelSleepNotification();
      }

      if (data.prefersCoffee == true) {
        _notificationService.scheduleCoffeeReminder(context: context);
      } else {
        _notificationService.cancelCoffeeReminder();
      }

      if (data.prefersTea == true) {
        _notificationService.scheduleTeaReminder(context: context);
      } else {
        _notificationService.cancelTeaReminder();
      }

      _notificationService.scheduleBreakfastFeedReminder(context: context);
      _notificationService.scheduleLunchFeedReminder(context: context);
      _notificationService.scheduleDinnerFeedReminder(context: context);
    } catch (e) {
      print("AuthWrapper: Error synchronizing notifications: $e");
    }
  }

  void _navigateToPage(BuildContext context, Widget screen, String routeName, {bool useTransition = false}) {
    print('AuthWrapper: Attempting to navigate to $routeName');
    if (!mounted) return;

    final currentRoute = ModalRoute.of(context)?.settings.name;
    // print('AuthWrapper: Current route: $currentRoute');

    if (currentRoute != routeName) {
      if (useTransition) {
        Navigator.of(context).pushAndRemoveUntil(
          FluidPageRoute(
            settings: RouteSettings(name: routeName),
            page: screen,
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: RouteSettings(name: routeName),
            builder: (context) => screen
          ),
          (route) => false,
        );
      }
    }
  }
}
