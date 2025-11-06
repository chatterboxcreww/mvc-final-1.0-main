// lib/core/services/daily_sync/sync_constants.dart

/// Constants used across the daily sync service
class SyncConstants {
  // Keys for local storage
  static const String userDataKey = 'daily_user_data';
  static const String checkinDataKey = 'daily_checkin_data';
  static const String stepDataKey = 'daily_step_data';
  static const String achievementsKey = 'daily_achievements';
  static const String activitiesKey = 'daily_activities';
  static const String experienceDataKey = 'daily_experience_data';
  static const String waterGlassCountKey = 'daily_water_glass_count';
  static const String lastWaterResetDateKey = 'last_water_reset_date';
  static const String lastStepResetDateKey = 'last_step_reset_date';
  static const String lastWaterExpAwardDateKey = 'last_water_exp_award_date';
  static const String lastSyncDateKey = 'last_sync_date';
  static const String sleepSyncCompleteKey = 'sleep_sync_complete';
  static const String wakeupSyncCompleteKey = 'wakeup_sync_complete';
  static const String dailyDataVersionKey = 'daily_data_version';
  static const String dailyCheckinCompleteKey = 'daily_checkin_complete';

  // Background task names
  static const String sleepSyncTaskName = 'daily_sleep_sync';
  static const String wakeupSyncTaskName = 'daily_wakeup_sync';

  // Experience points
  static const int waterMilestoneExp = 50;
  static const int waterMilestoneTarget = 9;

  // Defaults
  static const int defaultStepGoal = 10000;
  static const double stepsToMetersMultiplier = 0.762;
  static const double stepsToCaloriesMultiplier = 0.04;
}
