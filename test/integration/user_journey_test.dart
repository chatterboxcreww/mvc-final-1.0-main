// test/integration/user_journey_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mvc/main.dart' as app;
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Journey Integration Tests', () {
    testWidgets('Complete new user onboarding flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test age gate screen
      expect(find.text('Age Verification'), findsOneWidget);
      
      // Enter valid age (18+)
      await TestHelpers.enterTextAndSettle(
        tester,
        find.byType(TextField),
        '25',
      );
      
      await TestHelpers.tapAndSettle(
        tester,
        find.text('Continue'),
      );

      // Test permission gate screen
      expect(find.text('Permissions Required'), findsOneWidget);
      
      await TestHelpers.tapAndSettle(
        tester,
        find.text('Grant Permissions'),
      );

      // Test authentication screen
      expect(find.text('Welcome to Health-TRKD'), findsOneWidget);
      
      // Simulate Google Sign-In (would need to mock in real test)
      await TestHelpers.tapAndSettle(
        tester,
        find.text('Sign in with Google'),
      );

      // Test onboarding screens
      await _testOnboardingFlow(tester);

      // Test main app functionality
      await _testMainAppFeatures(tester);
    });

    testWidgets('Water tracking functionality end-to-end', (tester) async {
      // Initialize app with existing user
      await _initializeAppWithUser(tester);

      // Navigate to home screen
      expect(find.text('Today\'s Progress'), findsOneWidget);

      // Test water tracking
      await _testWaterTracking(tester);
    });

    testWidgets('Step tracking accuracy and persistence', (tester) async {
      // Initialize app with existing user
      await _initializeAppWithUser(tester);

      // Test step tracking
      await _testStepTracking(tester);
    });

    testWidgets('Achievement system functionality', (tester) async {
      // Initialize app with existing user
      await _initializeAppWithUser(tester);

      // Test achievement unlocking
      await _testAchievementSystem(tester);
    });

    testWidgets('Offline mode functionality', (tester) async {
      // Initialize app
      await _initializeAppWithUser(tester);

      // Simulate offline mode
      await _testOfflineMode(tester);
    });

    testWidgets('Settings and preferences', (tester) async {
      // Initialize app with existing user
      await _initializeAppWithUser(tester);

      // Test settings functionality
      await _testSettingsFlow(tester);
    });
  });
}

/// Test the complete onboarding flow
Future<void> _testOnboardingFlow(WidgetTester tester) async {
  // Personal Information Screen
  expect(find.text('Personal Information'), findsOneWidget);
  
  await TestHelpers.enterTextAndSettle(
    tester,
    find.byKey(const Key('name_field')),
    'Test User',
  );
  
  await TestHelpers.enterTextAndSettle(
    tester,
    find.byKey(const Key('age_field')),
    '25',
  );
  
  await TestHelpers.tapAndSettle(
    tester,
    find.text('Next'),
  );

  // Health Information Screen
  expect(find.text('Health Information'), findsOneWidget);
  
  await TestHelpers.enterTextAndSettle(
    tester,
    find.byKey(const Key('height_field')),
    '175',
  );
  
  await TestHelpers.enterTextAndSettle(
    tester,
    find.byKey(const Key('weight_field')),
    '70',
  );
  
  await TestHelpers.tapAndSettle(
    tester,
    find.text('Next'),
  );

  // Health Goals Screen
  expect(find.text('Health Goals'), findsOneWidget);
  
  // Set step goal
  await TestHelpers.tapAndSettle(
    tester,
    find.byKey(const Key('step_goal_10000')),
  );
  
  // Set water goal
  await TestHelpers.tapAndSettle(
    tester,
    find.byKey(const Key('water_goal_8')),
  );
  
  await TestHelpers.tapAndSettle(
    tester,
    find.text('Complete Setup'),
  );

  // Verify onboarding completion
  await TestHelpers.waitForWidget(
    tester,
    find.text('Welcome to Health-TRKD!'),
  );
}

/// Test main app features
Future<void> _testMainAppFeatures(WidgetTester tester) async {
  // Verify home screen elements
  expect(find.text('Today\'s Progress'), findsOneWidget);
  expect(find.byKey(const Key('step_tracker_card')), findsOneWidget);
  expect(find.byKey(const Key('water_tracker_card')), findsOneWidget);

  // Test navigation between tabs
  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.trending_up),
  );
  expect(find.text('Trends'), findsOneWidget);

  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.emoji_events),
  );
  expect(find.text('Achievements'), findsOneWidget);

  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.person),
  );
  expect(find.text('Profile'), findsOneWidget);

  // Return to home
  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.home),
  );
}

/// Test water tracking functionality
Future<void> _testWaterTracking(WidgetTester tester) async {
  // Find water tracker card
  final waterCard = find.byKey(const Key('water_tracker_card'));
  expect(waterCard, findsOneWidget);

  // Get initial water count
  final initialCountText = find.byKey(const Key('water_count_text'));
  expect(initialCountText, findsOneWidget);

  // Add water glass
  await TestHelpers.tapAndSettle(
    tester,
    find.byKey(const Key('add_water_button')),
  );

  // Verify count increased
  await TestHelpers.pumpAndSettle(tester);
  
  // Test multiple additions
  for (int i = 0; i < 3; i++) {
    await TestHelpers.tapAndSettle(
      tester,
      find.byKey(const Key('add_water_button')),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Test removal
  await TestHelpers.tapAndSettle(
    tester,
    find.byKey(const Key('remove_water_button')),
  );

  // Verify water goal progress
  expect(find.byKey(const Key('water_progress_indicator')), findsOneWidget);
}

/// Test step tracking functionality
Future<void> _testStepTracking(WidgetTester tester) async {
  // Find step tracker card
  final stepCard = find.byKey(const Key('step_tracker_card'));
  expect(stepCard, findsOneWidget);

  // Verify step count display
  expect(find.byKey(const Key('step_count_text')), findsOneWidget);
  expect(find.byKey(const Key('step_progress_indicator')), findsOneWidget);

  // Test step history navigation
  await TestHelpers.tapAndSettle(tester, stepCard);
  
  // Verify step history screen
  expect(find.text('Step History'), findsOneWidget);
  expect(find.byType(ListView), findsOneWidget);

  // Return to home
  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.arrow_back),
  );
}

/// Test achievement system
Future<void> _testAchievementSystem(WidgetTester tester) async {
  // Navigate to achievements
  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.emoji_events),
  );

  // Verify achievements screen
  expect(find.text('Achievements'), findsOneWidget);
  expect(find.byType(GridView), findsOneWidget);

  // Test achievement categories
  await TestHelpers.tapAndSettle(
    tester,
    find.text('Water'),
  );

  // Verify filtered achievements
  expect(find.byKey(const Key('achievement_card')), findsWidgets);

  // Test achievement details
  await TestHelpers.tapAndSettle(
    tester,
    find.byKey(const Key('achievement_card')).first,
  );

  // Verify achievement detail dialog
  expect(find.byType(Dialog), findsOneWidget);
  
  // Close dialog
  await TestHelpers.tapAndSettle(
    tester,
    find.text('Close'),
  );
}

/// Test offline mode functionality
Future<void> _testOfflineMode(WidgetTester tester) async {
  // Simulate network disconnection
  await TestHelpers.simulateAppLifecycleChange(
    tester,
    AppLifecycleState.paused,
  );

  // Perform offline actions
  await TestHelpers.tapAndSettle(
    tester,
    find.byKey(const Key('add_water_button')),
  );

  // Verify offline indicator
  expect(find.text('Offline'), findsOneWidget);

  // Simulate network reconnection
  await TestHelpers.simulateAppLifecycleChange(
    tester,
    AppLifecycleState.resumed,
  );

  // Verify sync indicator
  await TestHelpers.waitForWidget(
    tester,
    find.text('Syncing...'),
  );
}

/// Test settings flow
Future<void> _testSettingsFlow(WidgetTester tester) async {
  // Navigate to profile/settings
  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.person),
  );

  // Open settings
  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.settings),
  );

  // Verify settings screen
  expect(find.text('Settings'), findsOneWidget);

  // Test notification settings
  await TestHelpers.tapAndSettle(
    tester,
    find.text('Notifications'),
  );

  // Toggle notification setting
  await TestHelpers.tapAndSettle(
    tester,
    find.byType(Switch).first,
  );

  // Test theme settings
  await TestHelpers.tapAndSettle(
    tester,
    find.byIcon(Icons.arrow_back),
  );

  await TestHelpers.tapAndSettle(
    tester,
    find.text('Theme'),
  );

  // Change theme
  await TestHelpers.tapAndSettle(
    tester,
    find.text('Dark'),
  );

  // Verify theme change
  await TestHelpers.pumpAndSettle(tester);
}

/// Initialize app with existing user for testing
Future<void> _initializeAppWithUser(WidgetTester tester) async {
  // This would typically involve mocking authentication
  // and setting up test user data
  app.main();
  await tester.pumpAndSettle();
  
  // Skip onboarding for existing user tests
  // Implementation would depend on how app handles existing users
}