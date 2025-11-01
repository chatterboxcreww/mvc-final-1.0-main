// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\services\notification_service.dart

// lib/core/services/notification_service.dart
// f:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\services\notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../models/app_enums.dart';
import '../models/user_data.dart';
import 'storage_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Notification IDs
// Notification IDs <-- ADD THIS SECTION
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

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse notificationResponse) {
  debugPrint('Background notification tapped: ${notificationResponse.payload}');
  
  // Handle different notification types based on payload
  try {
    if (notificationResponse.payload != null) {
      final payload = notificationResponse.payload!;
      
      // Handle achievement notifications
      if (payload.contains('achievement')) {
        debugPrint('Achievement notification tapped in background');
        // Could store this for when app comes back to foreground
      }
      
      // Handle reminder notifications
      else if (payload.contains('water_reminder')) {
        debugPrint('Water reminder notification tapped in background');
        // Could increment some background counter
      }
      
      // Handle sleep/wakeup notifications
      else if (payload.contains('sleep') || payload.contains('wakeup')) {
        debugPrint('Sleep-related notification tapped in background');
        // Could log sleep interaction time
      }
      
      // Default handling
      else {
        debugPrint('Generic notification tapped in background: $payload');
      }
    }
  } catch (e) {
    debugPrint('Error handling background notification tap: $e');
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  NotificationService(this._flutterLocalNotificationsPlugin, [this._scaffoldMessengerKey]);

  Future<void> initializeNotifications(
      Function(NotificationResponse) onDidReceiveNotificationResponse,
      Function(NotificationResponse) onDidReceiveBackgroundNotificationResponse,
      ) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImplementation == null) {
          debugPrint("[NotificationService] iOS implementation not available");
          return false;
        }
        
        final bool? granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        final bool isGranted = granted ?? false;
        debugPrint("[NotificationService] iOS Notification Permission granted: $isGranted");
        return isGranted;
        
      } else if (Platform.isAndroid) {
        // Check standard notification permission
        PermissionStatus notificationStatus = await Permission.notification.status;
        debugPrint("[NotificationService] Initial notification permission: $notificationStatus");

        if (!notificationStatus.isGranted) {
          notificationStatus = await Permission.notification.request();
          debugPrint("[NotificationService] Notification permission after request: $notificationStatus");
        }

        final bool notificationGranted = notificationStatus.isGranted;
        if (!notificationGranted) {
          debugPrint("[NotificationService] Standard notification permission denied");
          return false;
        }

        // Check exact alarm permission for Android 12+
        PermissionStatus exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        debugPrint("[NotificationService] Initial exact alarm permission: $exactAlarmStatus");

        bool exactAlarmGranted = exactAlarmStatus.isGranted;
        
        if (!exactAlarmGranted) {
          final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

          if (androidImplementation != null) {
            try {
              await androidImplementation.requestExactAlarmsPermission();
              await Future.delayed(const Duration(seconds: 1));
              exactAlarmStatus = await Permission.scheduleExactAlarm.status;
              exactAlarmGranted = exactAlarmStatus.isGranted;
            } catch (e) {
              debugPrint("[NotificationService] Error requesting exact alarm permission: $e");
            }
          }
        }

        final bool allGranted = notificationGranted && exactAlarmGranted;
        debugPrint("[NotificationService] Final permissions - Notifications: $notificationGranted, ExactAlarms: $exactAlarmGranted");
        return allGranted;
      }
      
      return false;
    } catch (e) {
      debugPrint("[NotificationService] Error requesting permissions: $e");
      return false;
    }
  }

  Future<bool> _scheduleNotificationInternal({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String? payload,
    required String channelId,
    required String channelName,
    required String channelDescription,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      print('Successfully scheduled notification (ID:$id) for ${scheduledDate.toLocal()}: $title');
      return true;
    } on Exception catch (e) {
      debugPrint('Error during _scheduleNotificationInternal (ID:$id): $e');
      if (Platform.isAndroid && e.toString().toLowerCase().contains("exact alarm permission")) {
        print("Scheduling failed specifically due to missing exact alarm permission. User needs to grant it in system settings.");
      }
      return false;
    }
  }

  Future<bool> scheduleNotification(
      BuildContext context,
      String notificationTitle,
      String notificationBody,
      TimeOfDay time,
      String? payload, {
        int? id,
        NotificationRecurrence recurrence = NotificationRecurrence.once,
      }) async {
    final tz.Location location = tz.local;
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final int notificationId = id ?? await StorageService().getNextCustomNotificationId();
    String channelId, channelName, channelDescription;
    DateTimeComponents? matchComponents;

    if (recurrence == NotificationRecurrence.daily) {
      channelId = 'daily_custom_reminders_trkd';
      channelName = 'Daily Custom Reminders';
      channelDescription = 'Your daily custom reminders.';
      matchComponents = DateTimeComponents.time;
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    } else {
      channelId = 'one_time_custom_reminders_trkd';
      channelName = 'One-Time Custom Reminders';
      channelDescription = 'Your one-time custom reminders.';
      matchComponents = null;
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    return _scheduleNotificationInternal(
      id: notificationId,
      title: notificationTitle,
      body: notificationBody,
      scheduledDate: scheduledDate,
      payload: payload,
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      matchDateTimeComponents: matchComponents,
    );
  }

  Future<bool> _scheduleRecurringDailyNotification({
    required BuildContext context,
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String? payload,
    String channelId = 'recurring_notifications_health_trkd',
    String channelName = 'Daily Health Reminders',
    String channelDescription = 'Channel for daily health and activity reminders',
  }) async {
    final tz.Location location = tz.local;
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return _scheduleNotificationInternal(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    print('Cancelled notification with ID: $id');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('Cancelled ALL notifications');
  }

  // --- Predefined App Reminders ---
  Future<bool> scheduleMorningWalkReminder({ required BuildContext context, required UserData userData, }) async {
    if (userData.wakeupTime == null) return false;
    final wakeUpTime = userData.wakeupTime!;
    int walkTimeMinute = wakeUpTime.minute + 15;
    int walkTimeHour = wakeUpTime.hour;
    if (walkTimeMinute >= 60) {
      walkTimeHour = (wakeUpTime.hour + (walkTimeMinute ~/ 60)) % 24;
      walkTimeMinute = walkTimeMinute % 60;
    }
    TimeOfDay walkTime = TimeOfDay(hour: walkTimeHour, minute: walkTimeMinute);
    await cancelMorningWalkReminder();
    return _scheduleRecurringDailyNotification(
      context: context,
      id: MORNING_WALK_NOTIFICATION_ID,
      title: '🚶 Morning Walk Reminder',
      body: 'Time for your healthy morning walk!',
      time: walkTime,
      payload: 'morning_walk_reminder',
      channelId: 'morning_walk_channel_trkd',
      channelName: 'Morning Walk Reminders',
      channelDescription: 'Reminders for daily morning walk',
    );
  }

  Future<void> cancelMorningWalkReminder() async {
    await cancelNotification(MORNING_WALK_NOTIFICATION_ID);
  }

  Future<bool> scheduleWaterReminders({ required BuildContext context, required UserData userData, }) async {
    if (userData.wakeupTime == null || userData.sleepTime == null) return false;
    await cancelWaterReminders();

    final tz.Location location = tz.local;
    final TimeOfDay wakeUpTime = userData.wakeupTime!;
    final TimeOfDay sleepTime = userData.sleepTime!;

    tz.TZDateTime currentDay = tz.TZDateTime.now(location);
    tz.TZDateTime wakeUpDateTime = tz.TZDateTime(location, currentDay.year,
        currentDay.month, currentDay.day, wakeUpTime.hour, wakeUpTime.minute);
    tz.TZDateTime firstReminderTime = wakeUpDateTime.add(const Duration(hours: 2));
    tz.TZDateTime sleepDateTimeUser = tz.TZDateTime(location, currentDay.year,
        currentDay.month, currentDay.day, sleepTime.hour, sleepTime.minute);

    if (sleepDateTimeUser.isBefore(wakeUpDateTime)) {
      sleepDateTimeUser = sleepDateTimeUser.add(const Duration(days: 1));
    }

    int notificationCount = 0;
    bool anyScheduled = false;
    tz.TZDateTime scheduledReminderTime = firstReminderTime;

    while (scheduledReminderTime.isBefore(sleepDateTimeUser.subtract(const Duration(minutes: 30))) && notificationCount < 12) {
      final success = await _scheduleRecurringDailyNotification(
        context: context,
        id: WATER_REMINDER_BASE_ID + notificationCount,
        title: '💧 Hydration Reminder',
        body: 'Stay hydrated! Time for some water.',
        time: TimeOfDay(hour: scheduledReminderTime.hour, minute: scheduledReminderTime.minute),
        payload: 'water_reminder_${notificationCount + 1}',
        channelId: 'water_reminders_channel_trkd',
        channelName: 'Water Reminders',
        channelDescription: 'Periodic reminders to drink water.',
      );
      if (success) anyScheduled = true;
      notificationCount++;
      scheduledReminderTime = scheduledReminderTime.add(const Duration(hours: 2));
    }
    print('Scheduled $notificationCount water reminders.');
    return anyScheduled;
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 12; i++) {
      await cancelNotification(WATER_REMINDER_BASE_ID + i);
    }
  }

  Future<bool> scheduleWakeupNotification({ required BuildContext context, required UserData userData, }) async {
    if (userData.wakeupTime == null) return false;
    await cancelWakeupNotification();
    return _scheduleRecurringDailyNotification(
        context: context,
        id: WAKEUP_NOTIFICATION_ID,
        title: '${userData.name ?? "User"}, Good Morning! ☀️',
        body: 'Time to rise and shine! Start your day strong.',
        time: userData.wakeupTime!,
        payload: 'wakeup_notification',
        channelId: 'wakeup_channel_trkd',
        channelName: 'Wake-up Notifications',
        channelDescription: 'Daily wake-up calls.');
  }

  Future<void> cancelWakeupNotification() async {
    await cancelNotification(WAKEUP_NOTIFICATION_ID);
  }

  Future<bool> scheduleSleepNotification({ required BuildContext context, required UserData userData,}) async {
    if (userData.sleepTime == null) return false;
    await cancelSleepNotification();
    return _scheduleRecurringDailyNotification(
        context: context,
        id: SLEEP_NOTIFICATION_ID,
        title: 'Good Night, ${userData.name ?? "User"}! 🌙',
        body: 'Time to wind down. Sweet dreams!',
        time: userData.sleepTime!,
        payload: 'sleep_notification',
        channelId: 'sleep_channel_trkd',
        channelName: 'Sleep Notifications',
        channelDescription: 'Daily reminders for bedtime.');
  }

  Future<void> cancelSleepNotification() async {
    await cancelNotification(SLEEP_NOTIFICATION_ID);
  }

  Future<bool> schedulePreSleepReminder({ required BuildContext context, required UserData userData,}) async {
    if (userData.sleepTime == null) return false;
    await cancelPreSleepReminder();
    final sleepTime = userData.sleepTime!;
    final preSleepTime = TimeOfDay(hour: sleepTime.hour, minute: sleepTime.minute - 30);
    return _scheduleRecurringDailyNotification(
        context: context,
        id: PRE_SLEEP_NOTIFICATION_ID,
        title: 'Bedtime is approaching! 🛌',
        body: 'Wrap up your work and get ready for a good night\'s sleep.',
        time: preSleepTime,
        payload: 'pre_sleep_reminder',
        channelId: 'sleep_channel_trkd',
        channelName: 'Sleep Notifications',
        channelDescription: 'Daily reminders for bedtime.');
  }

  Future<void> cancelPreSleepReminder() async {
    await cancelNotification(PRE_SLEEP_NOTIFICATION_ID);
  }

  Future<bool> scheduleBreakfastFeedReminder({required BuildContext context}) async {
    await cancelBreakfastFeedReminder();
    return _scheduleRecurringDailyNotification(
      context: context,
      id: BREAKFAST_FEED_NOTIFICATION_ID,
      title: '🍳 Breakfast Feed Updated!',
      body: 'Check out today\'s breakfast ideas and tips in your feed.',
      time: const TimeOfDay(hour: 7, minute: 0),
      payload: 'breakfast_feed_update',
      channelId: 'feed_updates_trkd',
      channelName: 'Feed Updates',
      channelDescription: 'Notifications for feed content updates.',
    );
  }

  Future<void> cancelBreakfastFeedReminder() async {
    await cancelNotification(BREAKFAST_FEED_NOTIFICATION_ID);
  }

  Future<bool> scheduleCoffeeReminder({required BuildContext context}) async {
    await cancelCoffeeReminder();
    return _scheduleRecurringDailyNotification(
      context: context,
      id: COFFEE_REMINDER_NOTIFICATION_ID,
      title: '☕ Stay Active All Day!',
      body: 'Have a cup of coffee to boost your energy and stay active throughout the day.',
      time: const TimeOfDay(hour: 10, minute: 0),
      payload: 'coffee_reminder',
      channelId: 'beverage_reminders_trkd',
      channelName: 'Beverage Reminders',
      channelDescription: 'Reminders for coffee or tea based on preference.',
    );
  }

  Future<void> cancelCoffeeReminder() async {
    await cancelNotification(COFFEE_REMINDER_NOTIFICATION_ID);
  }

  Future<bool> scheduleLunchFeedReminder({required BuildContext context}) async {
    await cancelLunchFeedReminder();
    return _scheduleRecurringDailyNotification(
      context: context,
      id: LUNCH_FEED_NOTIFICATION_ID,
      title: '🥗 Lunch Feed Updated!',
      body: 'Discover new lunch recipes and nutritional advice in your feed.',
      time: const TimeOfDay(hour: 13, minute: 0),
      payload: 'lunch_feed_update',
      channelId: 'feed_updates_trkd',
    );
  }

  Future<void> cancelLunchFeedReminder() async {
    await cancelNotification(LUNCH_FEED_NOTIFICATION_ID);
  }

  Future<bool> scheduleTeaReminder({required BuildContext context}) async {
    await cancelTeaReminder();
    return _scheduleRecurringDailyNotification(
      context: context,
      id: TEA_REMINDER_NOTIFICATION_ID,
      title: '🍵 Tea Break from Work!',
      body: 'Take a break from work and enjoy a refreshing cup of tea.',
      time: const TimeOfDay(hour: 15, minute: 0),
      payload: 'tea_reminder',
      channelId: 'beverage_reminders_trkd',
    );
  }

  Future<void> cancelTeaReminder() async {
    await cancelNotification(TEA_REMINDER_NOTIFICATION_ID);
  }

  Future<bool> scheduleDinnerFeedReminder({required BuildContext context}) async {
    await cancelDinnerFeedReminder();
    return _scheduleRecurringDailyNotification(
      context: context,
      id: DINNER_FEED_NOTIFICATION_ID,
      title: '🍲 Dinner Feed Updated!',
      body: 'Find inspiration for a healthy and delicious dinner in your feed.',
      time: const TimeOfDay(hour: 19, minute: 0),
      payload: 'dinner_feed_update',
      channelId: 'feed_updates_trkd',
    );
  }

  Future<void> cancelDinnerFeedReminder() async {
    await cancelNotification(DINNER_FEED_NOTIFICATION_ID);
  }
  
  // Show an immediate notification for achievement unlocked
  Future<void> showAchievementUnlockedNotification({
    required String achievementName,
    required String achievementDescription,
    String? iconPath,
  }) async {
    final int notificationId = ACHIEVEMENT_NOTIFICATION_BASE_ID +
        DateTime.now().millisecondsSinceEpoch % 1000;
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'achievement_unlocked_channel_trkd',
      'Achievement Unlocked',
      channelDescription: 'Notifications for unlocked achievements',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50), // Green color for achievements
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      '🏆 Achievement Unlocked!',
      '$achievementName\n$achievementDescription',
      notificationDetails,
      payload: 'achievement_unlocked:$achievementName',
    );
    
    // print('Showed achievement unlocked notification: $achievementName');
  }
  
  // Cancel all achievement notifications
  Future<void> cancelAllAchievementNotifications() async {
    for (int i = 0; i < 100; i++) {
      await cancelNotification(ACHIEVEMENT_NOTIFICATION_BASE_ID + i);
    }
  }
}
