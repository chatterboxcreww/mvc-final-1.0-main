// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\reminders_card.dart

// lib/features/home/widgets/profile_components/reminders_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/activity.dart';
import '../../../../core/models/app_enums.dart';
import '../../../../core/models/user_data.dart';
import '../../../../core/providers/activity_provider.dart';
import '../../../../core/providers/user_data_provider.dart';
import '../../../../core/providers/experience_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/utils/extensions.dart';

enum ReminderField { wakeup, sleep, water, morningWalk, coffee, tea }

class RemindersCard extends StatelessWidget {
  const RemindersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userDataProvider = Provider.of<UserDataProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final userData = userDataProvider.userData;
    final notificationService = NotificationService(flutterLocalNotificationsPlugin);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminders & Notifications',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Divider(height: 20, thickness: 1, color: colorScheme.outline),
            SwitchListTile(
              title: Text('Wake-up Notification', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(userData.wakeupTime == null
                  ? 'Set Wake-up time to enable.'
                  : 'Daily at wake-up time',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              value: userData.wakeupNotificationEnabled,
              onChanged: (userData.wakeupTime == null)
                  ? null
                  : (bool value) async {
                      await _handleReminderToggle(
                          context: context,
                          newValue: value,
                          fieldToUpdate: ReminderField.wakeup,
                          scheduleFunction: (ctx, ud) => notificationService
                              .scheduleWakeupNotification(context: ctx, userData: ud),
                          cancelFunction:
                              notificationService.cancelWakeupNotification,
                          reminderName: 'Wake-up notification',
                          timeDependent: true);
                    },
            ),
            SwitchListTile(
              title: Text('Sleep Notification', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(userData.sleepTime == null
                  ? 'Set Sleep time to enable.'
                  : 'Daily at sleep time',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              value: userData.sleepNotificationEnabled,
              onChanged: (userData.sleepTime == null)
                  ? null
                  : (bool value) async {
                      await _handleReminderToggle(
                          context: context,
                          newValue: value,
                          fieldToUpdate: ReminderField.sleep,
                          scheduleFunction: (ctx, ud) => notificationService
                              .scheduleSleepNotification(context: ctx, userData: ud),
                          cancelFunction:
                              notificationService.cancelSleepNotification,
                          reminderName: 'Sleep notification',
                          timeDependent: true);
                    },
            ),
            SwitchListTile(
              title: Text('Water Reminder', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(
                userData.wakeupTime == null || userData.sleepTime == null
                    ? 'Set Sleep & Wake-up times.'
                    : 'Every 2 hours during wake time',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              value: userData.waterReminderEnabled,
              onChanged:
                  (userData.wakeupTime == null || userData.sleepTime == null)
                      ? null
                      : (bool value) async {
                          await _handleReminderToggle(
                              context: context,
                              newValue: value,
                              fieldToUpdate: ReminderField.water,
                              scheduleFunction: (ctx, ud) => notificationService
                                  .scheduleWaterReminders(context: ctx, userData: ud),
                              cancelFunction:
                                  notificationService.cancelWaterReminders,
                              reminderName: 'Water reminders',
                              timeDependent: true);
                        },
            ),
            SwitchListTile(
              title: Text('Morning Walk Reminder', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(userData.wakeupTime == null
                  ? 'Set Wake-up time to enable.'
                  : '15min after wake-up',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              value: userData.morningWalkReminderEnabled,
              onChanged: (userData.wakeupTime == null)
                  ? null
                  : (bool value) async {
                      await _handleReminderToggle(
                          context: context,
                          newValue: value,
                          fieldToUpdate: ReminderField.morningWalk,
                          scheduleFunction: (ctx, ud) =>
                              notificationService.scheduleMorningWalkReminder(
                                  context: ctx, userData: ud),
                          cancelFunction:
                              notificationService.cancelMorningWalkReminder,
                          reminderName: 'Morning walk reminder',
                          timeDependent: true);
                    },
            ),
            SwitchListTile(
              title: Text('Coffee Reminder (10 AM)', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(userData.prefersCoffee == null
                  ? 'Set coffee preference first (in Edit Lifestyle).'
                  : (userData.prefersCoffee!
                      ? 'Enabled (set by preference)'
                      : 'Disabled (set by preference)')),
              value: userData.prefersCoffee ?? false,
              onChanged: (userData.prefersCoffee == null)
                  ? null
                  : (bool value) async {
                      await _handleReminderToggle(
                          context: context,
                          newValue: value,
                          fieldToUpdate: ReminderField.coffee,
                          scheduleFunction: (ctx, ud) =>
                              notificationService.scheduleCoffeeReminder(
                                  context: ctx),
                          cancelFunction:
                              notificationService.cancelCoffeeReminder,
                          reminderName: 'Coffee preference & reminder');
                    },
            ),
            SwitchListTile(
              title: Text('Tea Reminder (3 PM)', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(userData.prefersTea == null
                  ? 'Set tea preference first (in Edit Lifestyle).'
                  : (userData.prefersTea!
                      ? 'Enabled (set by preference)'
                      : 'Disabled (set by preference)')),
              value: userData.prefersTea ?? false,
              onChanged: (userData.prefersTea == null)
                  ? null
                  : (bool value) async {
                      await _handleReminderToggle(
                          context: context,
                          newValue: value,
                          fieldToUpdate: ReminderField.tea,
                          scheduleFunction: (ctx, ud) =>
                              notificationService.scheduleTeaReminder(context: ctx),
                          cancelFunction: notificationService.cancelTeaReminder,
                          reminderName: 'Tea preference & reminder');
                    },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Custom Task Reminders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
            ),
            if (activityProvider.activities.where((a) => a.isCustom).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No custom reminders set yet.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8))),
              ),
            ...activityProvider.activities
                .where((a) => a.isCustom)
                .map((activity) =>
                    _buildCustomReminderTile(context, activity, activityProvider))
                ,
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () => _showCustomReminderDialog(context),
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Add Custom Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReminderToggle({
    required BuildContext context,
    required bool newValue,
    required ReminderField fieldToUpdate,
    required Future<bool> Function(BuildContext, UserData) scheduleFunction,
    required Future<void> Function() cancelFunction,
    required String reminderName,
    bool timeDependent = false,
  }) async {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    UserData updatedUserDataCopy = UserData.fromJson(userDataProvider.userData.toJson());

    switch (fieldToUpdate) {
      case ReminderField.wakeup:
        updatedUserDataCopy.wakeupNotificationEnabled = newValue;
        break;
      case ReminderField.sleep:
        updatedUserDataCopy.sleepNotificationEnabled = newValue;
        break;
      case ReminderField.water:
        updatedUserDataCopy.waterReminderEnabled = newValue;
        break;
      case ReminderField.morningWalk:
        updatedUserDataCopy.morningWalkReminderEnabled = newValue;
        break;
      case ReminderField.coffee:
        updatedUserDataCopy.prefersCoffee = newValue;
        break;
      case ReminderField.tea:
        updatedUserDataCopy.prefersTea = newValue;
        break;
    }

    final notificationService = NotificationService(flutterLocalNotificationsPlugin);

    if (newValue) {
      if (timeDependent) {
        final currentTime = userDataProvider.userData;
        if ((reminderName.toLowerCase().contains("sleep") || reminderName.toLowerCase().contains("water")) && currentTime.sleepTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please set Sleep Time to enable $reminderName.')));
          return;
        }
        if ((reminderName.toLowerCase().contains("wake-up") || reminderName.toLowerCase().contains("water") || reminderName.toLowerCase().contains("morning walk")) && currentTime.wakeupTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please set Wake-up Time to enable $reminderName.')));
          return;
        }
      }

      bool permissionsGranted = await notificationService.requestPermissions();
      if (permissionsGranted) {
        await userDataProvider.updateUserData(updatedUserDataCopy);
        await scheduleFunction(context, updatedUserDataCopy);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$reminderName enabled!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to enable $reminderName. Please grant permissions in app settings.',
                style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
                label: 'Settings', onPressed: () => openAppSettings()),
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } else {
      await userDataProvider.updateUserData(updatedUserDataCopy);
      await cancelFunction();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$reminderName disabled.')));
    }
  }

  Widget _buildCustomReminderTile(
      BuildContext context, Activity activity, ActivityProvider activityProvider) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final experienceProvider =
        Provider.of<ExperienceProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Checkbox(
              value: activity.isDone,
              onChanged: (bool? value) {
                if (value != null) {
                  activityProvider.toggleActivityDone(activity.id);
                  if (value) {
                    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
                    // Use the priority-based XP system for custom tasks
                    // We'll create a custom meal entry as an example of task completion
                    experienceProvider.addXpForCustomActivity(
                      userDataProvider.userData,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task complete! XP awarded based on your health priorities')),
                    );
                  }
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                          decoration: activity.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none)),
                  if (activity.time != null)
                    Text(
                      '${activity.time!.format(context)} - ${activity.recurrence.name.capitalize()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_forever_outlined,
                  color: colorScheme.error),
              tooltip: 'Delete Custom Reminder',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Custom Reminder'),
                    content: Text(
                        'Are you sure you want to delete the reminder "${activity.label}"? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await NotificationService(
                                  flutterLocalNotificationsPlugin)
                              .cancelNotification(
                                  activity.id.hashCode % 2147483647);
                          activityProvider.deleteActivity(activity.id);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Reminder "${activity.label}" deleted.')));
                        },
                        child: Text('Delete',
                            style: TextStyle(color: colorScheme.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomReminderDialog(BuildContext profileContext) async {
    final TextEditingController labelController = TextEditingController();
    TimeOfDay? selectedTime;
    NotificationRecurrence selectedRecurrence = NotificationRecurrence.daily;
    final NotificationService notificationService =
        NotificationService(flutterLocalNotificationsPlugin);
    final activityProvider = Provider.of<ActivityProvider>(profileContext, listen: false);
    final ColorScheme colorScheme = Theme.of(profileContext).colorScheme;

    final bool granted = await notificationService.requestPermissions();
    if (!granted) {
      ScaffoldMessenger.of(profileContext).showSnackBar(
        SnackBar(
          content: Text(
            'Please grant Notification and Exact Alarm permissions to add custom reminders.',
            style: TextStyle(color: colorScheme.onError),
          ),
          backgroundColor: colorScheme.error,
          action:
              SnackBarAction(label: 'Settings', onPressed: () => openAppSettings()),
          duration: const Duration(seconds: 7),
        ),
      );
      return;
    }

    await showDialog(
      context: profileContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Custom Task Reminder'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                        labelText: 'Reminder Label',
                        hintText: 'e.g., Take medication'),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Select Time', style: TextStyle(color: colorScheme.onSurface)),
                    subtitle: Text(
                      selectedTime?.format(profileContext) ?? 'No time selected',
                      style: TextStyle(
                          color: selectedTime == null ? colorScheme.onSurfaceVariant.withValues(alpha: 0.8) : colorScheme.onSurface),
                    ),
                    trailing: Icon(Icons.access_time_filled_outlined,
                        color: colorScheme.primary),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: profileContext,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedTime = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Recurrence:',
                      style: Theme.of(profileContext).textTheme.titleSmall?.copyWith(color: colorScheme.onSurface)),
                  Column(
                    children: NotificationRecurrence.values.map((recurrence) {
                      return RadioListTile<NotificationRecurrence>(
                        title: Text(recurrence.name.capitalize(), style: TextStyle(color: colorScheme.onSurface)),
                        value: recurrence,
                        groupValue: selectedRecurrence,
                        onChanged: (NotificationRecurrence? value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedRecurrence = value;
                            });
                          }
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (labelController.text.trim().isEmpty) {
                ScaffoldMessenger.of(profileContext).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a label for the reminder.')));
                return;
              }
              if (selectedTime == null) {
                ScaffoldMessenger.of(profileContext).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a time for the reminder.')));
                return;
              }

              String activityId = const Uuid().v4();
              int notificationId = activityId.hashCode % 2147483647;
              if (notificationId < 0) notificationId += 2147483647 + 1;

              final bool scheduled = await notificationService.scheduleNotification(
                profileContext,
                labelController.text.trim(),
                'It\'s time for: ${labelController.text.trim()}',
                selectedTime!,
                'custom_reminder_payload_$activityId',
                id: notificationId,
                recurrence: selectedRecurrence,
              );

              if (scheduled) {
                final newActivity = Activity(
                  id: activityId,
                  label: labelController.text.trim(),
                  time: selectedTime,
                  isCustom: true,
                  type: 'Custom Task',
                  recurrence: selectedRecurrence,
                );
                activityProvider.addActivity(newActivity);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(profileContext).showSnackBar(
                    const SnackBar(content: Text('Custom reminder added!')));
              } else {
                ScaffoldMessenger.of(profileContext).showSnackBar(const SnackBar(
                    content: Text(
                        'Failed to schedule reminder. Ensure permissions are granted.')));
              }
            },
            child: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }
}
