// lib/main.dart

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb; // <-- IMPORT kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/providers/activity_provider.dart';
import 'core/providers/curated_content_provider.dart';
import 'core/providers/leaderboard_provider.dart';
import 'core/providers/step_counter_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/trends_provider.dart';
import 'core/providers/user_data_provider.dart';
import 'core/providers/comment_provider.dart';
import 'core/providers/experience_provider.dart';
import 'core/providers/achievement_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/step_tracking_service.dart';
import 'core/services/achievement_background_service.dart';
import 'core/services/daily_sync_service.dart';
import 'core/services/admin_analytics_service.dart';
import 'core/services/content_filter_service.dart';
import 'core/services/auth_state_manager.dart';
import 'core/utils/performance_optimizer.dart';
import 'features/auth/screens/permission_gate_screen.dart';
import 'features/auth/screens/age_gate_screen.dart';
import 'features/auth/widgets/animated_splash_screen.dart';
import 'core/services/adaptive_notification_service.dart';
import 'shared/widgets/error_boundary.dart';
import 'core/config/secure_config.dart';
import 'core/services/intelligent_cache_service.dart';
import 'core/services/batch_operations_service.dart';
import 'core/services/offline_manager.dart';
import 'core/services/atomic_water_service.dart';
import 'core/services/persistent_step_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Background entry point for WorkManager tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Firebase in the background isolate
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Execute the step tracking sync
      if (task == StepTrackingConstants.syncTaskName) {
        final stepTrackingService = StepTrackingService();
        await stepTrackingService.syncStepsToFirebase();
      }

      // Execute the achievement check
      if (task == AchievementBackgroundConstants.checkTaskName) {
        final achievementService = AchievementBackgroundService();
        await achievementService.checkAchievementsInBackground();
      }

      // Execute daily sleep sync
      if (task == DailySyncService.sleepSyncTaskName) {
        final dailySyncService = DailySyncService();
        await dailySyncService.initialize();
        await dailySyncService.performSleepTimeSync();
      }

      // Execute daily wakeup sync
      if (task == DailySyncService.wakeupSyncTaskName) {
        final dailySyncService = DailySyncService();
        await dailySyncService.initialize();
        await dailySyncService.performWakeupTimeSync();
      }

      return true;
    } catch (e) {
      // Log error but don't crash the background task
      debugPrint('Background task error: $e');
      return false;
    }
  });
}

/// Background notification tap handler
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse notificationResponse) {
  // Handle notification tap in background
  debugPrint('Notification tapped in background: ${notificationResponse.payload}');
}

/// Main application entry point
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('🚀 Starting app initialization...');
    
    // Initialize performance optimizations for 60fps
    PerformanceOptimizer.initialize();
    debugPrint('✅ Performance optimizer initialized');
    
    // Initialize secure configuration
    await SecureConfig.initialize();
    debugPrint('✅ Secure config initialized');
    
    // Initialize Firebase FIRST (before core services that might need it)
    await _initializeFirebase();
    
    // Initialize core services
    await _initializeCoreServices();
    
    debugPrint('🎉 App initialization complete!');
    runApp(const MyApp());
    
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL: App initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error screen instead of black screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to Initialize App',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please check:\n'
                    '• Internet connection\n'
                    '• Firebase configuration\n'
                    '• google-services.json file',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
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

/// Initialize core services
Future<void> _initializeCoreServices() async {
  try {
    // Initialize intelligent cache service
    try {
      await IntelligentCacheService().initialize();
      debugPrint('✅ IntelligentCacheService initialized');
    } catch (e) {
      debugPrint('⚠️ IntelligentCacheService initialization failed: $e');
    }
    
    // Initialize offline manager
    try {
      await OfflineManager().initialize();
      debugPrint('✅ OfflineManager initialized');
    } catch (e) {
      debugPrint('⚠️ OfflineManager initialization failed: $e');
    }
    
    // Initialize atomic water service
    try {
      await AtomicWaterService().initialize();
      debugPrint('✅ AtomicWaterService initialized');
    } catch (e) {
      debugPrint('⚠️ AtomicWaterService initialization failed: $e');
    }
    
    // Initialize persistent step service
    try {
      await PersistentStepService().initialize();
      debugPrint('✅ PersistentStepService initialized');
    } catch (e) {
      debugPrint('⚠️ PersistentStepService initialization failed: $e');
    }
    
    debugPrint('✅ Core services initialization completed');
  } catch (e) {
    debugPrint('❌ Error during core services initialization: $e');
    // Don't rethrow - allow app to continue
  }
}

/// Initialize Firebase with offline persistence and improved error handling
Future<void> _initializeFirebase() async {
  try {
    debugPrint('🔥 Starting Firebase initialization...');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Firebase initialization timeout after 20 seconds');
      },
    );
    
    debugPrint('✅ Firebase initialized successfully');

    // FIX: Only call setPersistence on the web platform.
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
        debugPrint('✅ Firebase Auth persistence enabled (web)');
      } catch (e) {
        debugPrint('⚠️ Firebase Auth persistence setup failed: $e');
      }
    }

    // Enable Firestore offline persistence with better settings
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('✅ Firestore offline persistence enabled with enhanced settings');
    } catch (e) {
      debugPrint('⚠️ Firestore settings setup failed: $e');
    }

    // Enable Realtime Database persistence with timeout
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      debugPrint('✅ Realtime Database persistence enabled');
    } catch (e) {
      debugPrint('⚠️ Realtime Database persistence setup failed: $e');
    }
    
    debugPrint('🎉 Firebase initialization complete!');

  } catch (e, stackTrace) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Don't throw - allow app to continue in offline mode
    debugPrint('⚠️ Continuing app initialization without Firebase connection');
  }
}

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => CuratedContentProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => ExperienceProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),

        // Proxy providers with dependencies
        ChangeNotifierProxyProvider<UserDataProvider, StepCounterProvider>(
          create: (_) => StepCounterProvider(),
          update: (_, userDataProvider, stepCounterProvider) =>
          stepCounterProvider!..initialize(userDataProvider.userData),
        ),
        ChangeNotifierProxyProvider<UserDataProvider, TrendsProvider>(
          create: (_) => TrendsProvider(),
          update: (_, userDataProvider, trendsProvider) =>
          trendsProvider!..loadCheckinHistory(),
        ),
        ChangeNotifierProxyProvider4<UserDataProvider, StepCounterProvider,
            TrendsProvider, CommentProvider, AchievementProvider>(
          create: (_) => AchievementProvider(),
          update: (_, userData, steps, trends, comments, achievementProvider) {
            if (achievementProvider == null) return AchievementProvider();
            achievementProvider.checkAchievements(
              userData.userData,
              steps.weeklyStepData,
              trends.checkinHistory,
              comments.totalCommentCount,
            );
            return achievementProvider;
          },
        ),

        // Service providers
        Provider<NotificationService>(create: (_) => NotificationService(flutterLocalNotificationsPlugin)),
        ProxyProvider<NotificationService, AdaptiveNotificationService>(
          update: (_, notificationService, __) => AdaptiveNotificationService(notificationService),
        ),
        Provider<AdminAnalyticsService>(create: (_) => AdminAnalyticsService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ErrorBoundary(
            errorTitle: 'App Error',
            errorMessage: 'Something went wrong with the Health-TRKD app. Please restart the app.',
            showReportButton: true,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Health-TRKD',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const AppInitializer(),
            ),
          );
        },
      ),
    );
  }

}

// NEW WIDGET to handle the initialization process robustly
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    debugPrint('🚀 AppInitializer: initState called');
    
    // Use WidgetsBinding to ensure the widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚀 AppInitializer: PostFrameCallback triggered');
      _initializeAppAndNavigate();
    });
  }

  Future<void> _initializeAppAndNavigate() async {
    debugPrint('🚀 AppInitializer: Starting _initializeAppAndNavigate');
    
    // Add a safety timeout for the entire initialization process
    try {
      await _performInitialization().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Initialization timed out after 10 seconds, proceeding anyway');
        },
      );
    } catch (e) {
      debugPrint('❌ Initialization failed: $e, proceeding anyway');
    }
  }

  Future<void> _performInitialization() async {
    // This future represents the background initialization work.
    Future<void> initializeServices() async {
      try {
        // Initialize Workmanager with better error handling
        try {
          await Workmanager().initialize(callbackDispatcher, isInDebugMode: false).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ Workmanager initialization timed out - continuing anyway');
            },
          );
          debugPrint('✅ Workmanager initialized');
        } catch (e) {
          debugPrint('⚠️ Workmanager initialization failed: $e');
        }

        // Initialize timezone with error handling
        try {
          tz.initializeTimeZones();
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
          debugPrint('✅ Timezone initialized');
        } catch (e) {
          debugPrint('⚠️ Timezone initialization failed: $e');
        }

        // Initialize notification service with better error handling
        try {
          final notificationService = Provider.of<NotificationService>(context, listen: false);
          await notificationService.initializeNotifications(
                (NotificationResponse response) {},
            notificationTapBackgroundHandler,
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ Notification initialization timed out - continuing anyway');
            },
          );
          debugPrint('✅ Notification service initialized');
        } catch (e) {
          debugPrint('⚠️ Notification service initialization failed: $e');
        }

        // Initialize background services with error handling
        try {
          StepTrackingService().schedulePeriodicSync();
          AchievementBackgroundService().schedulePeriodicCheck();
          debugPrint('✅ Background services scheduled');
        } catch (e) {
          debugPrint('⚠️ Background service scheduling failed: $e');
        }

        // Initialize daily sync service with timeout
        try {
          final dailySyncService = DailySyncService();
          await dailySyncService.initialize().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ DailySyncService initialization timed out - continuing anyway');
            },
          );
          debugPrint('✅ DailySyncService initialized');
        } catch (e) {
          debugPrint('⚠️ DailySyncService initialization failed: $e');
        }

        // Initialize content filter service with timeout
        try {
          final contentFilterService = ContentFilterService();
          await contentFilterService.initialize().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ ContentFilterService initialization timed out - continuing anyway');
            },
          );
          debugPrint('✅ ContentFilterService initialized');
        } catch (e) {
          debugPrint('⚠️ ContentFilterService initialization failed: $e');
        }

        // Initialize admin analytics service with timeout (these require network)
        try {
          final adminAnalyticsService = Provider.of<AdminAnalyticsService>(context, listen: false);
          await adminAnalyticsService.trackUserActivity().timeout(const Duration(seconds: 1));
          await adminAnalyticsService.updateTotalUsers().timeout(const Duration(seconds: 1));
          await adminAnalyticsService.trackUserRetention().timeout(const Duration(seconds: 1));
          debugPrint('✅ Admin analytics initialized');
        } catch (e) {
          debugPrint('⚠️ Admin analytics timed out (offline mode): $e');
        }

        // Initialize auth state manager with timeout
        try {
          await AuthStateManager().initialize().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ AuthStateManager initialization timed out - continuing anyway');
            },
          );
          debugPrint('✅ AuthStateManager initialized');
        } catch (e) {
          debugPrint('⚠️ AuthStateManager initialization failed: $e');
        }
      } catch (e) {
        // Log error but don't block navigation, as the app might still be usable.
        debugPrint("Error during background initialization: $e");
      }
    }

    // This future ensures the splash screen is visible for a minimum duration.
    final splashDuration = Future.delayed(const Duration(milliseconds: 2000));

    // Wait for both initialization and the splash duration to complete with overall timeout
    await Future.wait([
      initializeServices(),
      splashDuration,
    ]).timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        debugPrint('⚠️ Overall initialization timed out - proceeding to app');
        return [];
      },
    );

    // Check if age has been verified with proper error handling
    bool ageVerified = false;
    try {
      debugPrint('🔍 Checking age verification status...');
      final prefs = await SharedPreferences.getInstance();
      ageVerified = prefs.getBool('age_verified') ?? false;
      debugPrint('🔍 Age verified from prefs: $ageVerified');
      
      // Additional validation - check if we have a valid birthdate
      if (ageVerified) {
        final birthdate = prefs.getString('user_birthdate');
        debugPrint('🔍 Stored birthdate: $birthdate');
        if (birthdate == null || birthdate.isEmpty) {
          debugPrint('Age verified flag set but no birthdate found, requiring re-verification');
          ageVerified = false;
          await prefs.setBool('age_verified', false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking age verification: $e');
      ageVerified = false; // Default to false on error
    }
    
    debugPrint('🔍 Final age verification status: $ageVerified');
    
    // Navigate to the appropriate screen after everything is done
    debugPrint('🚀 Navigation check: mounted=$mounted, ageVerified=$ageVerified');
    
    if (mounted) {
      debugPrint('🚀 Navigating to ${ageVerified ? "PermissionGateScreen" : "AgeGateScreen"}');
      
      // Add a small delay to ensure the widget tree is fully built
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        try {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                  ageVerified ? const PermissionGateScreen() : const AgeGateScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
          debugPrint('✅ Navigation completed successfully');
        } catch (e) {
          debugPrint('❌ Navigation error: $e');
          // Fallback navigation without animation
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ageVerified ? const PermissionGateScreen() : const AgeGateScreen(),
            ),
          );
          debugPrint('✅ Fallback navigation completed');
        }
      } else {
        debugPrint('❌ Widget unmounted during navigation delay');
      }
    } else {
      debugPrint('❌ Widget not mounted, cannot navigate');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AnimatedSplashScreen();
  }
  
  // Add a safety mechanism to prevent infinite splash screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safety timeout - if navigation hasn't happened in 15 seconds, force navigate
    Timer(const Duration(seconds: 15), () {
      if (mounted) {
        debugPrint('⚠️ Safety timeout triggered - forcing navigation to AgeGateScreen');
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AgeGateScreen()),
          );
        } catch (e) {
          debugPrint('❌ Safety navigation failed: $e');
        }
      }
    });
  }
}