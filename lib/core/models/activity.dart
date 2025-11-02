// lib/core/models/activity.dart
import 'package:flutter/material.dart';
import 'app_enums.dart';

class Activity {
  final String id;
  final String label;
  final TimeOfDay? time;
  bool isDone;
  final bool isCustom;
  final String? type;
  final NotificationRecurrence recurrence;
  final int? customDays;

  Activity({
    required this.id,
    required this.label,
    this.time,
    this.isDone = false,
    this.isCustom = false,
    this.type,
    this.recurrence = NotificationRecurrence.once,
    this.customDays,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      label: json['label'],
      time: json['timeHour'] != null && json['timeMinute'] != null
          ? TimeOfDay(hour: json['timeHour'], minute: json['timeMinute'])
          : null,
      isDone: json['isDone'] ?? false,
      isCustom: json['isCustom'] ?? false,
      type: json['type'],
      recurrence: json['recurrence'] != null
          ? NotificationRecurrence.values.firstWhere(
            (e) => e.name == json['recurrence'],
        orElse: () => NotificationRecurrence.once,
      ) : NotificationRecurrence.once,
      customDays: json['customDays'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'timeHour': time?.hour,
      'timeMinute': time?.minute,
      'isDone': isDone,
      'isCustom': isCustom,
      'type': type,
      'recurrence': recurrence.name,
      'customDays': customDays,
    };
  }
}
