// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\lifestyle_components\notification_manager.dart

// lib/features/profile/widgets/lifestyle_components/notification_manager.dart
import 'package:flutter/material.dart';
import '../../../../core/models/user_data.dart';
import '../../../../core/services/notification_service.dart';

/// Manages notification scheduling and cancellation for lifestyle preferences
class NotificationManager {
  /// Reschedules all notifications based on updated user data
  static Future<void> rescheduleNotifications(
      BuildContext context, NotificationService service, UserData data) async {
    // Handle morning walk reminders
    if (data.morningWalkReminderEnabled) {
      await service.scheduleMorningWalkReminder(context: context, userData: data);
    } else {
      await service.cancelMorningWalkReminder();
    }
    
    // Handle sleep notifications
    if (data.sleepNotificationEnabled) {
      await service.scheduleSleepNotification(context: context, userData: data);
      await service.schedulePreSleepReminder(context: context, userData: data);
    } else {
      await service.cancelSleepNotification();
      await service.cancelPreSleepReminder();
    }
    
    // Handle wakeup notifications
    if (data.wakeupNotificationEnabled) {
      await service.scheduleWakeupNotification(context: context, userData: data);
    } else {
      await service.cancelWakeupNotification();
    }
    
    // Handle water reminders
    if (data.waterReminderEnabled) {
      await service.scheduleWaterReminders(context: context, userData: data);
    } else {
      await service.cancelWaterReminders();
    }
    
    // Handle beverage preferences
    if (data.prefersCoffee == true) {
      await service.scheduleCoffeeReminder(context: context);
    } else {
      await service.cancelCoffeeReminder();
    }
    
    if (data.prefersTea == true) {
      await service.scheduleTeaReminder(context: context);
    } else {
      await service.cancelTeaReminder();
    }
  }

  /// Requests notification permissions and reschedules notifications
  static Future<bool> updateNotifications(
      BuildContext context, NotificationService service, UserData data) async {
    final bool permissionsGranted = await service.requestPermissions();
    
    if (permissionsGranted) {
      await rescheduleNotifications(context, service, data);
      return true;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permissions not granted. Reminders may not update correctly.'),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
      }
      return false;
    }
  }
}
