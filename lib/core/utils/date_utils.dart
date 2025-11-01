// lib/core/utils/date_utils.dart

import 'package:intl/intl.dart';

/// Centralized date utility class for consistent date handling across the app
class AppDateUtils {
  // Private constructor to prevent instantiation
  AppDateUtils._();
  
  /// Standard date format: YYYY-MM-DD
  static final DateFormat _standardDateFormat = DateFormat('yyyy-MM-dd');
  
  /// Standard datetime format: YYYY-MM-DD HH:mm:ss
  static final DateFormat _standardDateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  
  /// Display date format: MMM dd, yyyy (e.g., Jan 15, 2024)
  static final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy');
  
  /// Display datetime format: MMM dd, yyyy HH:mm (e.g., Jan 15, 2024 14:30)
  static final DateFormat _displayDateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  
  /// Format date to standard string (YYYY-MM-DD)
  static String formatDateToString(DateTime date) {
    return _standardDateFormat.format(date);
  }
  
  /// Format datetime to standard string (YYYY-MM-DD HH:mm:ss)
  static String formatDateTimeToString(DateTime dateTime) {
    return _standardDateTimeFormat.format(dateTime);
  }
  
  /// Format date for display (MMM dd, yyyy)
  static String formatDateForDisplay(DateTime date) {
    return _displayDateFormat.format(date);
  }
  
  /// Format datetime for display (MMM dd, yyyy HH:mm)
  static String formatDateTimeForDisplay(DateTime dateTime) {
    return _displayDateTimeFormat.format(dateTime);
  }
  
  /// Parse standard date string (YYYY-MM-DD) to DateTime
  static DateTime? parseDateString(String dateString) {
    try {
      return _standardDateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Parse standard datetime string (YYYY-MM-DD HH:mm:ss) to DateTime
  static DateTime? parseDateTimeString(String dateTimeString) {
    try {
      return _standardDateTimeFormat.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if two dates are the same day (ignoring time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
  
  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
  
  /// Get start of day (00:00:00)
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get end of day (23:59:59)
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  /// Get start of week (Monday 00:00:00)
  static DateTime getStartOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return getStartOfDay(monday);
  }
  
  /// Get end of week (Sunday 23:59:59)
  static DateTime getEndOfWeek(DateTime date) {
    final sunday = date.add(Duration(days: 7 - date.weekday));
    return getEndOfDay(sunday);
  }
  
  /// Get start of month (1st day 00:00:00)
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Get end of month (last day 23:59:59)
  static DateTime getEndOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return getEndOfDay(lastDay);
  }
  
  /// Get number of days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = getStartOfDay(from);
    final toDate = getStartOfDay(to);
    return toDate.difference(fromDate).inDays;
  }
  
  /// Get relative time string (e.g., "2 hours ago", "yesterday", "3 days ago")
  static String getRelativeTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (isYesterday(dateTime)) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
  
  /// Get today's date string (YYYY-MM-DD)
  static String getTodayString() {
    return formatDateToString(DateTime.now());
  }
  
  /// Get yesterday's date string (YYYY-MM-DD)
  static String getYesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return formatDateToString(yesterday);
  }
  
  /// Check if a date string is today
  static bool isDateStringToday(String dateString) {
    return dateString == getTodayString();
  }
  
  /// Get age from birthdate
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
