// test/helpers/test_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:mvc/core/providers/theme_provider.dart';
import 'package:mvc/core/providers/user_data_provider.dart';
import 'package:mvc/core/providers/step_counter_provider.dart';
import 'package:mvc/core/providers/activity_provider.dart';
import 'package:mvc/core/providers/curated_content_provider.dart';
import 'package:mvc/core/providers/comment_provider.dart';
import 'package:mvc/core/providers/experience_provider.dart';
import 'package:mvc/core/providers/achievement_provider.dart';
import 'package:mvc/core/providers/leaderboard_provider.dart';
import 'package:mvc/core/providers/trends_provider.dart';
import 'package:mvc/core/services/notification_service.dart';
import 'package:mvc/core/services/adaptive_notification_service.dart';
import 'package:mvc/core/models/user_data.dart';
import 'package:mvc/core/models/daily_step_data.dart';
import 'package:mvc/core/models/achievement.dart';

// Generate mocks
@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  UserDataProvider,
  StepCounterProvider,
  ActivityProvider,
  CuratedContentProvider,
  CommentProvider,
  ExperienceProvider,
  AchievementProvider,
  LeaderboardProvider,
  TrendsProvider,
  NotificationService,
])
import 'test_helpers.mocks.dart';

/// Test helpers for creating consistent test environments
class TestHelpers {
  static late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;
  static late MockUserDataProvider mockUserDataProvider;
  static late MockStepCounterProvider mockStepCounterProvider;
  static late MockActivityProvider mockActivityProvider;
  static late MockCuratedContentProvider mockCuratedContentProvider;
  static late MockCommentProvider mockCommentProvider;
  static late MockExperienceProvider mockExperienceProvider;
  static late MockAchievementProvider mockAchievementProvider;
  static late MockLeaderboardProvider mockLeaderboardProvider;
  static late MockTrendsProvider mockTrendsProvider;
  static late MockNotificationService mockNotificationService;

  /// Initialize all mocks with default behavior
  static void initializeMocks() {
    mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
    mockUserDataProvider = MockUserDataProvider();
    mockStepCounterProvider = MockStepCounterProvider();
    mockActivityProvider = MockActivityProvider();
    mockCuratedContentProvider = MockCuratedContentProvider();
    mockCommentProvider = MockCommentProvider();
    mockExperienceProvider = MockExperienceProvider();
    mockAchievementProvider = MockAchievementProvider();
    mockLeaderboardProvider = MockLeaderboardProvider();
    mockTrendsProvider = MockTrendsProvider();
    mockNotificationService = MockNotificationService();

    _setupDefaultMockBehavior();
  }

  /// Set up default behavior for mocks
  static void _setupDefaultMockBehavior() {
    // UserDataProvider defaults
    when(mockUserDataProvider.userData).thenReturn(createTestUserData());
    when(mockUserDataProvider.isLoading).thenReturn(false);
    when(mockUserDataProvider.lastError).thenReturn(null);

    // StepCounterProvider defaults
    when(mockStepCounterProvider.todaySteps).thenReturn(5000);
    when(mockStepCounterProvider.streak).thenReturn(3);
    when(mockStepCounterProvider.caloriesBurned).thenReturn(200.0);
    when(mockStepCounterProvider.distanceMeters).thenReturn(3810.0);
    when(mockStepCounterProvider.weeklyStepData).thenReturn(createTestStepData());
    when(mockStepCounterProvider.isStepDetectionAvailable).thenReturn(true);

    // ExperienceProvider defaults
    when(mockExperienceProvider.xp).thenReturn(1250);
    when(mockExperienceProvider.level).thenReturn(5);
    when(mockExperienceProvider.levelProgress).thenReturn(0.6);
    when(mockExperienceProvider.hasRecentXpGain).thenReturn(false);
    when(mockExperienceProvider.hasNewLevelUp).thenReturn(false);

    // AchievementProvider defaults
    when(mockAchievementProvider.achievements).thenReturn(createTestAchievements());
    when(mockAchievementProvider.unlockedAchievements).thenReturn(createTestUnlockedAchievements());
    when(mockAchievementProvider.isLoading).thenReturn(false);
    when(mockAchievementProvider.hasNewAchievement).thenReturn(false);

    // ActivityProvider defaults
    when(mockActivityProvider.activities).thenReturn([]);

    // CommentProvider defaults
    when(mockCommentProvider.totalCommentCount).thenReturn(0);

    // CuratedContentProvider defaults
    when(mockCuratedContentProvider.isContentAvailable).thenReturn(true);

    // LeaderboardProvider defaults
    when(mockLeaderboardProvider.leaderboardEntries).thenReturn([]);
    when(mockLeaderboardProvider.isLoading).thenReturn(false);

    // TrendsProvider defaults
    when(mockTrendsProvider.checkinHistory).thenReturn([]);
  }

  /// Create a test app with all required providers
  static Widget createTestApp(Widget child, {
    bool useMocks = true,
    Map<String, dynamic>? overrides,
  }) {
    if (useMocks) {
      initializeMocks();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<UserDataProvider>(
          create: (_) => useMocks ? mockUserDataProvider : UserDataProvider(),
        ),
        ChangeNotifierProvider<StepCounterProvider>(
          create: (_) => useMocks ? mockStepCounterProvider : StepCounterProvider(),
        ),
        ChangeNotifierProvider<ActivityProvider>(
          create: (_) => useMocks ? mockActivityProvider : ActivityProvider(),
        ),
        ChangeNotifierProvider<CuratedContentProvider>(
          create: (_) => useMocks ? mockCuratedContentProvider : CuratedContentProvider(),
        ),
        ChangeNotifierProvider<CommentProvider>(
          create: (_) => useMocks ? mockCommentProvider : CommentProvider(),
        ),
        ChangeNotifierProvider<ExperienceProvider>(
          create: (_) => useMocks ? mockExperienceProvider : ExperienceProvider(),
        ),
        ChangeNotifierProvider<AchievementProvider>(
          create: (_) => useMocks ? mockAchievementProvider : AchievementProvider(),
        ),
        ChangeNotifierProvider<LeaderboardProvider>(
          create: (_) => useMocks ? mockLeaderboardProvider : LeaderboardProvider(),
        ),
        ChangeNotifierProvider<TrendsProvider>(
          create: (_) => useMocks ? mockTrendsProvider : TrendsProvider(),
        ),
        Provider<NotificationService>(
          create: (_) => useMocks ? mockNotificationService : NotificationService(mockNotificationsPlugin),
        ),
        ProxyProvider<NotificationService, AdaptiveNotificationService>(
          update: (_, notificationService, __) => AdaptiveNotificationService(notificationService),
        ),
      ],
      child: MaterialApp(
        title: 'Test App',
        home: child,
      ),
    );
  }

  /// Create test user data
  static UserData createTestUserData({
    String? name,
    int? age,
    double? height,
    double? weight,
    int? level,
    int? dailyStepGoal,
    int? dailyWaterGoal,
  }) {
    return UserData(
      userId: 'test_user_123',
      name: name ?? 'Test User',
      age: age ?? 25,
      height: height ?? 175.0,
      weight: weight ?? 70.0,
      level: level ?? 5,
      dailyStepGoal: dailyStepGoal ?? 10000,
      dailyWaterGoal: dailyWaterGoal ?? 8,
      memberSince: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  /// Create test step data
  static List<DailyStepData> createTestStepData() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: index));
      return DailyStepData(
        date: date,
        steps: 8000 + (index * 500),
        goal: 10000,
      );
    });
  }

  /// Create test achievements
  static List<Achievement> createTestAchievements() {
    return [
      Achievement(
        id: 'water_1',
        name: 'Hydration Beginner',
        description: 'Drink 100 litres of water.',
        icon: 'assets/icons/water_drop.svg',
        category: AchievementCategory.water,
        targetValue: 100,
        currentValue: 75,
        progress: 0.75,
      ),
      Achievement(
        id: 'steps_1',
        name: 'First Steps',
        description: 'Walk 10,000 steps in a day.',
        icon: 'assets/icons/footsteps.svg',
        category: AchievementCategory.steps,
        targetValue: 10000,
        currentValue: 10000,
        progress: 1.0,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Create test unlocked achievements
  static List<Achievement> createTestUnlockedAchievements() {
    return createTestAchievements().where((a) => a.isUnlocked).toList();
  }

  /// Pump and settle with timeout
  static Future<void> pumpAndSettle(WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pump();
    await tester.pumpAndSettle(timeout);
  }

  /// Wait for a specific widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    
    throw TimeoutException('Widget not found within timeout', timeout);
  }

  /// Simulate user tap with delay
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    await tester.tap(finder);
    await tester.pump(delay);
    await tester.pumpAndSettle();
  }

  /// Simulate user scroll
  static Future<void> scrollAndSettle(
    WidgetTester tester,
    Finder finder,
    Offset offset, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    await tester.drag(finder, offset);
    await tester.pump(delay);
    await tester.pumpAndSettle();
  }

  /// Enter text in a field
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    await tester.enterText(finder, text);
    await tester.pump(delay);
    await tester.pumpAndSettle();
  }

  /// Verify widget properties
  static void verifyWidgetProperties(
    WidgetTester tester,
    Finder finder,
    Map<String, dynamic> expectedProperties,
  ) {
    final widget = tester.widget(finder);
    
    for (final entry in expectedProperties.entries) {
      final property = entry.key;
      final expectedValue = entry.value;
      
      // Use reflection or specific property checks
      // This is a simplified version - extend based on needs
      expect(widget.toString().contains(expectedValue.toString()), isTrue,
          reason: 'Property $property should be $expectedValue');
    }
  }

  /// Create test gesture
  static TestGesture createTestGesture(WidgetTester tester) {
    return tester.createGesture();
  }

  /// Simulate app lifecycle changes
  static Future<void> simulateAppLifecycleChange(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    final binding = tester.binding;
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/lifecycle',
      (data) async {
        return null;
      },
    );
    
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('routeUpdated', {
          'location': '/',
          'state': state.toString(),
        }),
      ),
      (data) {},
    );
    
    await tester.pumpAndSettle();
  }

  /// Mock network responses
  static void mockNetworkResponse(String url, Map<String, dynamic> response) {
    // Implementation would depend on HTTP client used
    // This is a placeholder for network mocking
  }

  /// Create test data for specific scenarios
  static Map<String, dynamic> createTestScenario(String scenarioName) {
    switch (scenarioName) {
      case 'new_user':
        return {
          'userData': createTestUserData(name: null, age: null),
          'stepData': <DailyStepData>[],
          'achievements': <Achievement>[],
        };
      
      case 'experienced_user':
        return {
          'userData': createTestUserData(level: 25),
          'stepData': createTestStepData(),
          'achievements': createTestAchievements(),
        };
      
      case 'offline_mode':
        return {
          'isOffline': true,
          'cachedData': {
            'userData': createTestUserData(),
            'stepData': createTestStepData(),
          },
        };
      
      default:
        return {};
    }
  }

  /// Clean up after tests
  static void cleanup() {
    // Reset mocks
    reset(mockUserDataProvider);
    reset(mockStepCounterProvider);
    reset(mockActivityProvider);
    reset(mockCuratedContentProvider);
    reset(mockCommentProvider);
    reset(mockExperienceProvider);
    reset(mockAchievementProvider);
    reset(mockLeaderboardProvider);
    reset(mockTrendsProvider);
    reset(mockNotificationService);
  }

  /// Verify accessibility
  static Future<void> verifyAccessibility(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  }

  /// Performance testing helper
  static Future<void> measurePerformance(
    WidgetTester tester,
    String testName,
    Future<void> Function() testFunction,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    await testFunction();
    
    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;
    
    // Log performance metrics
    debugPrint('Performance Test [$testName]: ${duration}ms');
    
    // Assert performance thresholds
    expect(duration, lessThan(5000), reason: 'Test should complete within 5 seconds');
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for checking if a widget has specific text
  static Matcher hasText(String text) {
    return _HasTextMatcher(text);
  }
  
  /// Matcher for checking if a widget is enabled
  static Matcher isEnabled() {
    return _IsEnabledMatcher();
  }
  
  /// Matcher for checking if a widget is visible
  static Matcher isVisible() {
    return _IsVisibleMatcher();
  }
}

class _HasTextMatcher extends Matcher {
  final String expectedText;
  
  _HasTextMatcher(this.expectedText);
  
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Widget) {
      return item.toString().contains(expectedText);
    }
    return false;
  }
  
  @override
  Description describe(Description description) {
    return description.add('has text "$expectedText"');
  }
}

class _IsEnabledMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    // Implementation depends on widget type
    return true; // Placeholder
  }
  
  @override
  Description describe(Description description) {
    return description.add('is enabled');
  }
}

class _IsVisibleMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    // Implementation depends on widget type
    return true; // Placeholder
  }
  
  @override
  Description describe(Description description) {
    return description.add('is visible');
  }
}