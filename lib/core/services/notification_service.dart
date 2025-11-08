// lib/core/services/notification_service.dart
// Full notification service implementation with proper persistence

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/app_enums.dart';
import '../models/user_data.dart';

// Notification IDs (kept for compatibility)
const int MORNING_WALK_NOTIFICATION_ID = 1000;
const int SLEEP_NOTIFICATION_ID = 1001;
const int PRE_SLEEP_NOTIFICATION_ID = 1003;
const int WAKEUP_NOTIFICATION_ID = 1002;
const int WATER_REMINDER_BASE_ID = 2000;
const int BREAKFAST_FEED_NOTIFICATION_ID = 3000;
const int COFFEE_REMINDER_NOTIFICATION_ID = 3001;
const int LUNCH_FEED_NOTIFICATION_ID = 3002;
const int TEA_REMINDER_NOTIFICATION_ID = 3003;
const int DINNER_FEED_NOTIFICATION_ID = 3004;
const int ACHIEVEMENT_NOTIFICATION_BASE_ID = 4000;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  // Notification settings persistence keys
  static const String _waterRemindersEnabledKey = 'water_reminders_enabled';
  static const String _stepGoalRemindersEnabledKey = 'step_goal_reminders_enabled';
  static const String _moodCheckInsEnabledKey = 'mood_checkins_enabled';
  static const String _weeklyReportsEnabledKey = 'weekly_reports_enabled';
  static const String _achievementNotificationsEnabledKey = 'achievement_notifications_enabled';
  static const String _levelUpNotificationsEnabledKey = 'level_up_notifications_enabled';
  
  // Legacy keys for backward compatibility
  static const String _legacyWaterRemindersKey = 'water_reminders';
  static const String _legacyStepGoalRemindersKey = 'step_goal_reminders';
  static const String _legacyMoodCheckInsKey = 'mood_check_ins';
  static const String _legacyWeeklyReportsKey = 'weekly_reports';
  static const String _legacyAchievementNotificationsKey = 'achievement_notifications';
  static const String _legacyLevelUpNotificationsKey = 'level_up_notifications';

  Future<void> initializeNotifications(
    Function(NotificationResponse) onDidReceiveNotificationResponse,
    void Function(NotificationResponse) onDidReceiveBackgroundNotificationResponse,
  ) async {
    if (_isInitialized) {
      debugPrint('⚠️ Notification service already initialized');
      return;
    }

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      
      // Get device's timezone offset
      final deviceOffset = DateTime.now().timeZoneOffset;
      final deviceOffsetHours = deviceOffset.inHours;
      final deviceOffsetMinutes = deviceOffset.inMinutes % 60;
      
      debugPrint('📍 Device timezone offset: ${deviceOffsetHours >= 0 ? '+' : ''}$deviceOffsetHours:${deviceOffsetMinutes.abs().toString().padLeft(2, '0')}');
      
      // Common timezone mappings for major regions
      final timezoneMap = {
        '+5:30': 'Asia/Kolkata',      // India
        '+8:00': 'Asia/Singapore',     // Singapore, Malaysia
        '+0:00': 'Europe/London',      // UK
        '-5:00': 'America/New_York',   // US East
        '-8:00': 'America/Los_Angeles', // US West
        '+1:00': 'Europe/Paris',       // Central Europe
        '+9:00': 'Asia/Tokyo',         // Japan
        '+10:00': 'Australia/Sydney',  // Australia East
      };
      
      // Create offset string
      final offsetString = '${deviceOffsetHours >= 0 ? '+' : ''}$deviceOffsetHours:${deviceOffsetMinutes.abs().toString().padLeft(2, '0')}';
      
      // Try to get timezone from map first
      String? timezoneName = timezoneMap[offsetString];
      
      // If not in map, search through all timezones
      if (timezoneName == null) {
        debugPrint('⚠️ Timezone not in common map, searching database...');
        final locations = tz.timeZoneDatabase.locations;
        
        for (final locationName in locations.keys) {
          try {
            final loc = tz.getLocation(locationName);
            final now = tz.TZDateTime.now(loc);
            
            // Check if offset matches (within 1 minute tolerance)
            if ((now.timeZoneOffset.inMinutes - deviceOffset.inMinutes).abs() <= 1) {
              // Prefer major city names
              if (locationName.contains('/')) {
                timezoneName = locationName;
                break;
              }
            }
          } catch (e) {
            // Skip invalid locations
            continue;
          }
        }
      }
      
      // Set the timezone
      if (timezoneName != null) {
        try {
          final location = tz.getLocation(timezoneName);
          tz.setLocalLocation(location);
          debugPrint('✅ Timezone set to: ${location.name}');
        } catch (e) {
          debugPrint('❌ Failed to set timezone: $e');
        }
      } else {
        debugPrint('⚠️ Could not determine timezone, using UTC');
      }
      
      // Verify the timezone is correct
      final now = tz.TZDateTime.now(tz.local);
      final deviceNow = DateTime.now();
      
      debugPrint('📍 App timezone: ${tz.local.name}');
      debugPrint('📍 App time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
      debugPrint('📍 Device time: ${deviceNow.hour.toString().padLeft(2, '0')}:${deviceNow.minute.toString().padLeft(2, '0')}');
      
      // Check if times match
      if ((now.hour != deviceNow.hour) || (now.minute != deviceNow.minute)) {
        debugPrint('⚠️ WARNING: App time and device time do not match!');
        debugPrint('⚠️ This will cause notifications to fire at wrong times!');
      } else {
        debugPrint('✅ Timezone correctly synchronized with device');
      }

      // Initialize plugin with proper error handling
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final initializeResult = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse payload) {
          debugPrint('Notification tapped with payload: ${payload.payload}');
          onDidReceiveNotificationResponse(payload);
        },
        onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
      );

      if (initializeResult != null && initializeResult == false) {
        debugPrint('⚠️ Notification initialization returned false');
      }

      // Request permissions
      final permissionsGranted = await _requestPermissions();
      debugPrint('📋 Notification permissions granted: $permissionsGranted');

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize notifications: $e');
      _isInitialized = false; // Ensure we can try again later
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Request notification permission
        final bool? notificationGranted = await androidPlugin.requestNotificationsPermission();
        debugPrint('📋 Notification permission: ${notificationGranted ?? false}');
        
        // Request exact alarm permission (Android 12+)
        final bool? exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
        debugPrint('📋 Exact alarm permission: ${exactAlarmGranted ?? false}');
        
        // Check if exact alarms are allowed
        final bool? canScheduleExactAlarms = await androidPlugin.canScheduleExactNotifications();
        debugPrint('📋 Can schedule exact alarms: ${canScheduleExactAlarms ?? false}');
        
        if (canScheduleExactAlarms == false) {
          debugPrint('⚠️ WARNING: Exact alarms not allowed! Notifications may not fire on time.');
          debugPrint('⚠️ User needs to enable "Alarms & reminders" permission in app settings.');
        }
        
        return (notificationGranted ?? false) && (canScheduleExactAlarms ?? false);
      }

      return true; // iOS permissions handled in initialization
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  Future<bool> scheduleNotification(
    BuildContext? context,
    String notificationTitle,
    String notificationBody,
    TimeOfDay scheduledTime,
    String payload, {
    NotificationRecurrence recurrence = NotificationRecurrence.once,
    int? customId,
  }) async {
    if (!_isInitialized) {
      debugPrint('Notification service not initialized');
      return false;
    }

    try {
      final int notificationId = customId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(scheduledTime);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'scheduled_channel',
            'Scheduled Notifications',
            channelDescription: 'Notifications scheduled by the app',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // For Android, use exact scheduling to ensure notifications fire precisely
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationBody,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: recurrence == NotificationRecurrence.daily
            ? DateTimeComponents.time
            : null,
        payload: payload,
      );

      // Format the scheduled date/time for better readability
      final formattedDate = '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
      final formattedTime = '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}:${scheduledDate.second.toString().padLeft(2, '0')}';
      
      debugPrint('✅ Notification scheduled: $notificationTitle');
      debugPrint('   ⏰ Input time: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}');
      debugPrint('   📅 Will fire on: $formattedDate at $formattedTime');
      debugPrint('   🆔 Notification ID: $notificationId');
      debugPrint('   🔁 Recurrence: $recurrence');
      debugPrint('   🌍 Timezone: ${tz.local.name}');
      
      // Show current time for comparison
      final now = tz.TZDateTime.now(tz.local);
      final nowFormatted = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      debugPrint('   🕐 Current time: $nowFormatted');
      
      // Calculate time until notification
      final duration = scheduledDate.difference(now);
      if (duration.inMinutes < 60) {
        debugPrint('   ⏳ Will fire in: ${duration.inMinutes} minutes');
      } else if (duration.inHours < 24) {
        debugPrint('   ⏳ Will fire in: ${duration.inHours} hours ${duration.inMinutes % 60} minutes');
      } else {
        debugPrint('   ⏳ Will fire in: ${duration.inDays} days ${duration.inHours % 24} hours');
      }
      
      // Verify the notification was actually scheduled
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('   📋 Total pending notifications in system: ${pendingNotifications.length}');
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> scheduleNotificationWithId({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
    required String payload,
    NotificationRecurrence recurrence = NotificationRecurrence.once,
  }) async {
    return await scheduleNotification(
      null, // context not needed for this method
      title,
      body,
      scheduledTime,
      payload,
      recurrence: recurrence,
      customId: id,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('✅ Notification cancelled: $id');
    } catch (e) {
      debugPrint('❌ Failed to cancel notification $id: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel all notifications: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('📅 Scheduling notification for: ${scheduledDate.toString()} (${tz.local.name})');
    return scheduledDate;
  }
  
  // Get current timezone information
  String getCurrentTimezone() {
    return tz.local.name;
  }
  
  // Get current time in local timezone
  DateTime getCurrentLocalTime() {
    return tz.TZDateTime.now(tz.local);
  }

  // Additional methods used by the app
  Future<bool> scheduleMorningWalkReminder({
    required BuildContext context,
    required UserData userData,
  }) async {
    if (!_isInitialized || !await _isNotificationEnabled('morningWalkReminderEnabled')) {
      return false;
    }

    try {
      const TimeOfDay morningTime = TimeOfDay(hour: 7, minute: 0);
      return await scheduleNotification(
        context,
        'Morning Walk Reminder',
        'Time for your morning walk! Start your day with some exercise.',
        morningTime,
        'morning_walk',
        recurrence: NotificationRecurrence.daily,
        customId: MORNING_WALK_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling morning walk reminder: $e');
      return false;
    }
  }

  Future<void> cancelMorningWalkReminder() async {
    await cancelNotification(MORNING_WALK_NOTIFICATION_ID);
  }

  Future<bool> scheduleWaterReminders({
    required BuildContext context,
    required UserData userData,
  }) async {
    if (!_isInitialized || !await _isNotificationEnabled(_waterRemindersEnabledKey)) {
      return false;
    }

    try {
      // Schedule water reminders every 2 hours from 8 AM to 8 PM
      final List<TimeOfDay> waterTimes = [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 10, minute: 0),
        const TimeOfDay(hour: 12, minute: 0),
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 16, minute: 0),
        const TimeOfDay(hour: 18, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ];

      bool allScheduled = true;
      for (int i = 0; i < waterTimes.length; i++) {
        final success = await scheduleNotification(
          context,
          'Water Reminder',
          'Stay hydrated! Drink a glass of water.',
          waterTimes[i],
          'water_reminder_$i',
          recurrence: NotificationRecurrence.daily,
          customId: WATER_REMINDER_BASE_ID + i,
        );
        if (!success) allScheduled = false;
      }

      return allScheduled;
    } catch (e) {
      debugPrint('Error scheduling water reminders: $e');
      return false;
    }
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 7; i++) {
      await cancelNotification(WATER_REMINDER_BASE_ID + i);
    }
  }

  Future<bool> scheduleWakeupNotification({
    required BuildContext context,
    required UserData userData,
  }) async {
    if (!_isInitialized) return false;

    try {
      const TimeOfDay wakeupTime = TimeOfDay(hour: 6, minute: 30);
      return await scheduleNotification(
        context,
        'Good Morning!',
        'Rise and shine! Start your day with Health-TRKD.',
        wakeupTime,
        'wakeup',
        recurrence: NotificationRecurrence.daily,
        customId: WAKEUP_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling wakeup notification: $e');
      return false;
    }
  }

  Future<void> cancelWakeupNotification() async {
    await cancelNotification(WAKEUP_NOTIFICATION_ID);
  }

  Future<bool> scheduleSleepNotification({
    required BuildContext context,
    required UserData userData,
  }) async {
    if (!_isInitialized) return false;

    try {
      const TimeOfDay sleepTime = TimeOfDay(hour: 22, minute: 0);
      return await scheduleNotification(
        context,
        'Bedtime Reminder',
        'Time to wind down and get some rest.',
        sleepTime,
        'sleep',
        recurrence: NotificationRecurrence.daily,
        customId: SLEEP_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling sleep notification: $e');
      return false;
    }
  }

  Future<void> cancelSleepNotification() async {
    await cancelNotification(SLEEP_NOTIFICATION_ID);
  }

  Future<bool> scheduleCoffeeReminder({
    required BuildContext context,
  }) async {
    if (!_isInitialized) return false;

    try {
      const TimeOfDay coffeeTime = TimeOfDay(hour: 9, minute: 0);
      return await scheduleNotification(
        context,
        'Coffee Break',
        'Time for your morning coffee!',
        coffeeTime,
        'coffee',
        recurrence: NotificationRecurrence.daily,
        customId: COFFEE_REMINDER_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling coffee reminder: $e');
      return false;
    }
  }

  Future<void> cancelCoffeeReminder() async {
    await cancelNotification(COFFEE_REMINDER_NOTIFICATION_ID);
  }

  Future<bool> scheduleTeaReminder({
    required BuildContext context,
  }) async {
    if (!_isInitialized) return false;

    try {
      const TimeOfDay teaTime = TimeOfDay(hour: 15, minute: 0);
      return await scheduleNotification(
        context,
        'Tea Time',
        'Enjoy your afternoon tea break!',
        teaTime,
        'tea',
        recurrence: NotificationRecurrence.daily,
        customId: TEA_REMINDER_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling tea reminder: $e');
      return false;
    }
  }

  Future<void> cancelTeaReminder() async {
    await cancelNotification(TEA_REMINDER_NOTIFICATION_ID);
  }

  Future<void> showAchievementUnlockedNotification({
    required String achievementName,
    required String achievementDescription,
    required String iconPath,
  }) async {
    if (!_isInitialized || !await _isNotificationEnabled(_achievementNotificationsEnabledKey)) {
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'achievement_channel',
            'Achievement Notifications',
            channelDescription: 'Notifications for unlocked achievements',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        ACHIEVEMENT_NOTIFICATION_BASE_ID + DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Achievement Unlocked!',
        '$achievementName: $achievementDescription',
        platformChannelSpecifics,
        payload: 'achievement',
      );

      debugPrint('✅ Achievement notification shown: $achievementName');
    } catch (e) {
      debugPrint('❌ Failed to show achievement notification: $e');
    }
  }

  Future<bool> scheduleBreakfastFeedReminder({
    required BuildContext context,
  }) async {
    if (!_isInitialized) return false;

    try {
      const TimeOfDay breakfastTime = TimeOfDay(hour: 8, minute: 30);
      return await scheduleNotification(
        context,
        'Breakfast Time',
        'Check out today\'s breakfast recommendations!',
        breakfastTime,
        'breakfast_feed',
        recurrence: NotificationRecurrence.daily,
        customId: BREAKFAST_FEED_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling breakfast feed reminder: $e');
      return false;
    }
  }

  Future<bool> scheduleLunchFeedReminder({
    required BuildContext context,
  }) async {
    if (!_isInitialized) return false;

    try {
      const TimeOfDay lunchTime = TimeOfDay(hour: 12, minute: 30);
      return await scheduleNotification(
        context,
        'Lunch Time',
        'Discover healthy lunch options for today!',
        lunchTime,
        'lunch_feed',
        recurrence: NotificationRecurrence.daily,
        customId: LUNCH_FEED_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling lunch feed reminder: $e');
      return false;
    }
  }

  Future<bool> scheduleDinnerFeedReminder({
    required BuildContext context,
  }) async {
    if (!_isInitialized) return false;

    try {
      const TimeOfDay dinnerTime = TimeOfDay(hour: 19, minute: 0);
      return await scheduleNotification(
        context,
        'Dinner Time',
        'Explore nutritious dinner ideas!',
        dinnerTime,
        'dinner_feed',
        recurrence: NotificationRecurrence.daily,
        customId: DINNER_FEED_NOTIFICATION_ID,
      );
    } catch (e) {
      debugPrint('Error scheduling dinner feed reminder: $e');
      return false;
    }
  }

  // Notification settings persistence methods
  Future<void> saveNotificationSettings({
    required bool waterReminders,
    required bool stepGoalReminders,
    required bool moodCheckIns,
    required bool weeklyReports,
    required bool achievementNotifications,
    required bool levelUpNotifications,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_waterRemindersEnabledKey, waterReminders);
      await prefs.setBool(_stepGoalRemindersEnabledKey, stepGoalReminders);
      await prefs.setBool(_moodCheckInsEnabledKey, moodCheckIns);
      await prefs.setBool(_weeklyReportsEnabledKey, weeklyReports);
      await prefs.setBool(_achievementNotificationsEnabledKey, achievementNotifications);
      await prefs.setBool(_levelUpNotificationsEnabledKey, levelUpNotifications);
      debugPrint('✅ Notification settings saved');
    } catch (e) {
      debugPrint('❌ Failed to save notification settings: $e');
    }
  }

  Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get values from new keys first
      final waterReminders = prefs.getBool(_waterRemindersEnabledKey);
      final stepGoalReminders = prefs.getBool(_stepGoalRemindersEnabledKey);
      final moodCheckIns = prefs.getBool(_moodCheckInsEnabledKey);
      final weeklyReports = prefs.getBool(_weeklyReportsEnabledKey);
      final achievementNotifications = prefs.getBool(_achievementNotificationsEnabledKey);
      final levelUpNotifications = prefs.getBool(_levelUpNotificationsEnabledKey);
      
      // If any new key is null, try to get from legacy keys
      final settings = {
        'water_reminders_enabled': waterReminders ?? prefs.getBool(_legacyWaterRemindersKey) ?? true,
        'step_goal_reminders_enabled': stepGoalReminders ?? prefs.getBool(_legacyStepGoalRemindersKey) ?? true,
        'mood_checkins_enabled': moodCheckIns ?? prefs.getBool(_legacyMoodCheckInsKey) ?? true,
        'weekly_reports_enabled': weeklyReports ?? prefs.getBool(_legacyWeeklyReportsKey) ?? true,
        'achievement_notifications_enabled': achievementNotifications ?? prefs.getBool(_legacyAchievementNotificationsKey) ?? true,
        'level_up_notifications_enabled': levelUpNotifications ?? prefs.getBool(_legacyLevelUpNotificationsKey) ?? true,
      };
      
      // If legacy keys were used, migrate them to new keys
      bool migrated = false;
      if (waterReminders == null && prefs.getBool(_legacyWaterRemindersKey) != null) {
        await prefs.setBool(_waterRemindersEnabledKey, settings['water_reminders_enabled']!);
        migrated = true;
      }
      if (stepGoalReminders == null && prefs.getBool(_legacyStepGoalRemindersKey) != null) {
        await prefs.setBool(_stepGoalRemindersEnabledKey, settings['step_goal_reminders_enabled']!);
        migrated = true;
      }
      if (moodCheckIns == null && prefs.getBool(_legacyMoodCheckInsKey) != null) {
        await prefs.setBool(_moodCheckInsEnabledKey, settings['mood_checkins_enabled']!);
        migrated = true;
      }
      if (weeklyReports == null && prefs.getBool(_legacyWeeklyReportsKey) != null) {
        await prefs.setBool(_weeklyReportsEnabledKey, settings['weekly_reports_enabled']!);
        migrated = true;
      }
      if (achievementNotifications == null && prefs.getBool(_legacyAchievementNotificationsKey) != null) {
        await prefs.setBool(_achievementNotificationsEnabledKey, settings['achievement_notifications_enabled']!);
        migrated = true;
      }
      if (levelUpNotifications == null && prefs.getBool(_legacyLevelUpNotificationsKey) != null) {
        await prefs.setBool(_levelUpNotificationsEnabledKey, settings['level_up_notifications_enabled']!);
        migrated = true;
      }
      
      if (migrated) {
        debugPrint('✅ Migrated notification settings from legacy keys');
      }
      
      return settings;
    } catch (e) {
      debugPrint('❌ Failed to load notification settings: $e');
      return {
        'water_reminders_enabled': true,
        'step_goal_reminders_enabled': true,
        'mood_checkins_enabled': true,
        'weekly_reports_enabled': true,
        'achievement_notifications_enabled': true,
        'level_up_notifications_enabled': true,
      };
    }
  }

  Future<bool> _isNotificationEnabled(String key) async {
    final settings = await loadNotificationSettings();
    
    // Map specific keys to their corresponding settings
    switch (key) {
      case 'waterReminderEnabled':
        return settings[_waterRemindersEnabledKey] ?? true;
      case 'stepGoalReminderEnabled':
        return settings[_stepGoalRemindersEnabledKey] ?? true;
      case 'moodCheckInEnabled':
        return settings[_moodCheckInsEnabledKey] ?? true;
      case 'weeklyReportEnabled':
        return settings[_weeklyReportsEnabledKey] ?? true;
      case 'achievementNotificationEnabled':
        return settings[_achievementNotificationsEnabledKey] ?? true;
      case 'levelUpNotificationEnabled':
        return settings[_levelUpNotificationsEnabledKey] ?? true;
      case 'morningWalkReminderEnabled':
        return settings[_waterRemindersEnabledKey] ?? true;
      default:
        return settings[key] ?? true;
    }
  }
  
  // Method to reschedule all notifications when the app restarts
  Future<void> rescheduleAllNotifications() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized, cannot reschedule');
      return;
    }
    
    try {
      // Load notification settings
      final settings = await loadNotificationSettings();
      
      debugPrint('🔄 Rescheduling all notifications based on settings: $settings');
      
      // Note: Actual rescheduling should happen based on user preferences
      // This would typically be called from the adaptive notification service
    } catch (e) {
      debugPrint('❌ Error rescheduling notifications: $e');
    }
  }
  
  // Method to check if notifications are properly scheduled and reschedule if needed
  Future<void> ensureNotificationsScheduled() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized, cannot ensure notifications scheduled');
      return;
    }
    
    try {
      // Get pending notifications to see if any are already scheduled
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('📋 Currently scheduled notifications: ${pendingNotifications.length}');
      
      // If there are no scheduled notifications, we may need to reschedule them
      // However, we don't want to cancel existing ones unnecessarily
      // Instead, we'll let the adaptive notification service handle this based on user settings
      if (pendingNotifications.isEmpty) {
        debugPrint('🔄 No notifications found, they may need to be rescheduled based on user preferences...');
      } else {
        debugPrint('✅ Notifications are already scheduled (${pendingNotifications.length} found)');
      }
    } catch (e) {
      debugPrint('❌ Error checking scheduled notifications: $e');
    }
  }
  
  // Method to request notification permissions and handle the result
  Future<bool> ensureNotificationPermissions() async {
    try {
      // Check if we have notification permissions
      final granted = await _requestPermissions();
      debugPrint('📋 Notification permissions granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  // Show persistent notification for step tracking
  Future<void> showPersistentStepNotification({
    required int currentSteps,
    required int goalSteps,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized, cannot show persistent notification');
      return;
    }

    try {
      final progress = (currentSteps / goalSteps * 100).clamp(0, 100).toInt();
      
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'step_counter_channel',
            'Step Counter',
            channelDescription: 'Persistent notification showing step count',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true, // Makes it persistent
            autoCancel: false,
            showProgress: true,
            maxProgress: 100,
            progress: progress,
            playSound: false,
            enableVibration: false,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        999, // Fixed ID for persistent notification
        '🚶 Steps Today',
        '$currentSteps / $goalSteps steps ($progress%)',
        platformChannelSpecifics,
        payload: 'step_counter',
      );

      debugPrint('✅ Persistent step notification updated: $currentSteps/$goalSteps');
    } catch (e) {
      debugPrint('❌ Failed to show persistent step notification: $e');
    }
  }

  // Cancel persistent step notification
  Future<void> cancelPersistentStepNotification() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(999);
      debugPrint('✅ Persistent step notification cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel persistent step notification: $e');
    }
  }

  // Show immediate test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications to verify setup',
            importance: Importance.high,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        888,
        '✅ Test Notification',
        'Notifications are working! This is a test notification.',
        platformChannelSpecifics,
        payload: 'test',
      );

      debugPrint('✅ Test notification shown immediately');
    } catch (e) {
      debugPrint('❌ Failed to show test notification: $e');
    }
  }
  
  // Schedule a test notification 1 minute from now
  Future<void> scheduleTestNotificationIn1Minute() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(const Duration(minutes: 1));
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications to verify setup',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999,
        '⏰ Scheduled Test',
        'This notification was scheduled 1 minute ago!',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('✅ Test notification scheduled for: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}');
      debugPrint('   Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      debugPrint('   Will fire in 1 minute');
    } catch (e) {
      debugPrint('❌ Failed to schedule test notification: $e');
    }
  }
  
  // Get list of all pending notifications
  Future<List<String>> getPendingNotifications() async {
    if (!_isInitialized) {
      return [];
    }

    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final List<String> notificationList = [];
      
      final now = tz.TZDateTime.now(tz.local);
      final nowFormatted = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      debugPrint('📋 ========== PENDING NOTIFICATIONS (${pendingNotifications.length}) ==========');
      debugPrint('   🕐 Current time: $nowFormatted (${tz.local.name})');
      debugPrint('   ─────────────────────────────────────────────────────');
      
      for (var i = 0; i < pendingNotifications.length; i++) {
        final notification = pendingNotifications[i];
        final info = '${i + 1}. ID: ${notification.id} | ${notification.title}';
        debugPrint('   $info');
        if (notification.body != null && notification.body!.isNotEmpty) {
          debugPrint('      Body: ${notification.body}');
        }
        notificationList.add(info);
      }
      
      if (pendingNotifications.isEmpty) {
        debugPrint('   ⚠️  NO PENDING NOTIFICATIONS FOUND!');
        debugPrint('   This means scheduled notifications are not being saved.');
      }
      
      debugPrint('📋 ═══════════════════════════════════════════════════════');
      
      return notificationList;
    } catch (e) {
      debugPrint('❌ Failed to get pending notifications: $e');
      return [];
    }
  }
}
