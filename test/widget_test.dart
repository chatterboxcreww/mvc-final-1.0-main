// F:\latestmvc\latestmvc\mvc-final-1.0-main\test\widget_test.dart

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added import

import 'package:mvc/main.dart';
import 'package:mvc/core/providers/theme_provider.dart'; // Import ThemeProvider
import 'package:mvc/core/providers/user_data_provider.dart'; // Import UserDataProvider
import 'package:mvc/core/providers/step_counter_provider.dart'; // Import StepCounterProvider
import 'package:mvc/core/providers/leaderboard_provider.dart'; // Import LeaderboardProvider
import 'package:mvc/core/providers/trends_provider.dart'; // Import TrendsProvider
import 'package:mvc/core/providers/activity_provider.dart'; // Import ActivityProvider
import 'package:mvc/core/providers/curated_content_provider.dart'; // Import CuratedContentProvider
import 'package:mvc/core/providers/comment_provider.dart'; // Import CommentProvider
import 'package:mvc/core/providers/experience_provider.dart'; // Import ExperienceProvider
import 'package:mvc/core/providers/achievement_provider.dart'; // Import AchievementProvider
import 'package:mvc/core/services/notification_service.dart'; // Import NotificationService
import 'package:mvc/core/services/adaptive_notification_service.dart'; // Import AdaptiveNotificationService

import 'package:mockito/mockito.dart'; // Import mockito

// Mock classes for flutter_local_notifications
class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}
class MockAndroidFlutterLocalNotificationsPlugin extends Mock implements AndroidFlutterLocalNotificationsPlugin {}
class MockIOSFlutterLocalNotificationsPlugin extends Mock implements IOSFlutterLocalNotificationsPlugin {}
class MockNotificationDetails extends Mock implements NotificationDetails {}
class MockAndroidNotificationDetails extends Mock implements AndroidNotificationDetails {}
class MockDarwinNotificationDetails extends Mock implements DarwinNotificationDetails {}
class MockInitializationSettings extends Mock implements InitializationSettings {}

// Mock the global instance
MockFlutterLocalNotificationsPlugin mockFlutterLocalNotificationsPlugin = MockFlutterLocalNotificationsPlugin();

void main() {
  testWidgets('App starts without ProviderNotFoundException', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProxyProvider<ExperienceProvider, StepCounterProvider>(
            create: (_) => StepCounterProvider(),
            update: (_, experienceProvider, stepCounterProvider) =>
                stepCounterProvider!..setExperienceProvider(experienceProvider),
          ),
          ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
          ChangeNotifierProxyProvider<ExperienceProvider, TrendsProvider>(
            create: (_) => TrendsProvider(),
            update: (_, experienceProvider, trendsProvider) =>
                trendsProvider!..setExperienceProvider(experienceProvider),
          ),
          ChangeNotifierProvider(create: (_) => UserDataProvider()),
          ChangeNotifierProvider(create: (_) => ActivityProvider()),
          ChangeNotifierProvider(create: (_) => CuratedContentProvider()),
          ChangeNotifierProvider(create: (_) => CommentProvider()),
          ChangeNotifierProvider(create: (_) => ExperienceProvider()),
          ChangeNotifierProvider(create: (_) => AchievementProvider()),
          Provider.value(value: NotificationService(mockFlutterLocalNotificationsPlugin)),
          Provider(create: (_) => AdaptiveNotificationService(NotificationService(mockFlutterLocalNotificationsPlugin))),
        ],
        child: const MyApp(),
      ),
    );

    // Expect to find the app's main widget, indicating it started successfully
    expect(find.byType(MyApp), findsOneWidget);
  });
}


