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
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance optimizations for 60fps
  PerformanceOptimizer.initialize();
  
  await _initializeFirebase();
  runApp(const MyApp());
}

/// Initialize Firebase with offline persistence
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FIX: Only call setPersistence on the web platform.
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    // Enable Firestore offline persistence (this is safe for all platforms)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Enable Realtime Database persistence (this is safe for all platforms)
    FirebaseDatabase.instance.setPersistenceEnabled(true);

  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Don't rethrow, as the app might still function with cached data.
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
              theme: _buildThemeData(_lightColorScheme),
              darkTheme: _buildThemeData(_darkColorScheme),
              themeMode: themeProvider.themeMode,
              home: const AppInitializer(),
            ),
          );
        },
      ),
    );
  }

  /// Build theme data with Material Design 3
  ThemeData _buildThemeData(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      chipTheme: ChipThemeData(
        selectedColor: const Color(0xFFB3D7FF),
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        brightness: colorScheme.brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          elevation: 4,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.5),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 22.0),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 11,
        ),
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
      ),
    );
  }

  /// Light color scheme
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2196F3),
    brightness: Brightness.light,
    primary: const Color(0xFF2196F3),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFD8E6FF), // Light blue highlight
    onPrimaryContainer: const Color(0xFF001B3D),
    secondary: const Color(0xFFE63946),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFFFDAD9),
    onSecondaryContainer: const Color(0xFF410009),
    tertiary: const Color(0xFF06D6A0),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFC1F7E3),
    onTertiaryContainer: const Color(0xFF00382A),
    error: const Color(0xFFFF3D00),
    onError: Colors.white,
    background: const Color(0xFFF9FAFF),
    onBackground: const Color(0xFF121417),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF121417),
    surfaceContainer: const Color(0xFFF0F4FF),
    surfaceContainerHighest: const Color(0xFFE6EDFF),
    surfaceVariant: const Color(0xFFF2F4FF),
    onSurfaceVariant: const Color(0xFF42474F),
    outline: const Color(0xFFD0D8FF),
  );

  /// Dark color scheme
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4361EE),
    brightness: Brightness.dark,
    primary: const Color(0xFF4361EE),
    onPrimary: const Color(0xFF00344D),
    primaryContainer: const Color(0xFF004B6F),
    onPrimaryContainer: const Color(0xFFBEECFF),
    secondary: const Color(0xFFF72585),
    onSecondary: const Color(0xFF3F0022),
    secondaryContainer: const Color(0xFF5C0035),
    onSecondaryContainer: const Color(0xFFFFD9E6),
    tertiary: const Color(0xFF7209B7),
    onTertiary: const Color(0xFFFFD6FA),
    tertiaryContainer: const Color(0xFF560A8A),
    onTertiaryContainer: const Color(0xFFF3CCFF),
    error: const Color(0xFFFF5D8F),
    onError: const Color(0xFF4F0018),
    background: const Color(0xFF0A0E17),
    onBackground: const Color(0xFFE9EEFF),
    surface: const Color(0xFF121824),
    onSurface: const Color(0xFFE9EEFF),
    surfaceContainer: const Color(0xFF1A2130),
    surfaceContainerHighest: const Color(0xFF232A3A),
    surfaceVariant: const Color(0xFF293245),
    onSurfaceVariant: const Color(0xFFCFD5E8),
    outline: const Color(0xFF4A5573),
    shadow: const Color(0xFF000000),
  );
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
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    // This future represents the background initialization work.
    Future<void> initializeServices() async {
      try {
        await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        await notificationService.initializeNotifications(
              (NotificationResponse response) {},
          notificationTapBackgroundHandler,
        );
        StepTrackingService().schedulePeriodicSync();
        AchievementBackgroundService().schedulePeriodicCheck();
        
        // Initialize daily sync service
        final dailySyncService = DailySyncService();
        await dailySyncService.initialize();
        
        // Initialize content filter service for age-appropriate content
        final contentFilterService = ContentFilterService();
        await contentFilterService.initialize();
        
        // Initialize admin analytics service and track user activity
        final adminAnalyticsService = Provider.of<AdminAnalyticsService>(context, listen: false);
        await adminAnalyticsService.trackUserActivity();
        await adminAnalyticsService.updateTotalUsers();
        await adminAnalyticsService.trackUserRetention();
        
        // Initialize auth state manager
        await AuthStateManager().initialize();
      } catch (e) {
        // Log error but don't block navigation, as the app might still be usable.
        debugPrint("Error during background initialization: $e");
      }
    }

    // This future ensures the splash screen is visible for a minimum duration.
    final splashDuration = Future.delayed(const Duration(milliseconds: 3000));

    // Wait for both initialization and the splash duration to complete.
    await Future.wait([
      initializeServices(),
      splashDuration,
    ]);

    // Check if age has been verified with proper error handling
    bool ageVerified = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      ageVerified = prefs.getBool('age_verified') ?? false;
      
      // Additional validation - check if we have a valid birthdate
      if (ageVerified) {
        final birthdate = prefs.getString('user_birthdate');
        if (birthdate == null || birthdate.isEmpty) {
          print('Age verified flag set but no birthdate found, requiring re-verification');
          ageVerified = false;
          await prefs.setBool('age_verified', false);
        }
      }
    } catch (e) {
      print('Error checking age verification: $e');
      ageVerified = false; // Default to false on error
    }
    
    // Navigate to the appropriate screen after everything is done
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              ageVerified ? const PermissionGateScreen() : const AgeGateScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AnimatedSplashScreen();
  }
}