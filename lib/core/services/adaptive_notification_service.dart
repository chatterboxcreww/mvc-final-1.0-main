// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\services\adaptive_notification_service.dart

// lib/core/services/adaptive_notification_service.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../providers/activity_provider.dart';
import '../providers/step_counter_provider.dart';
import '../providers/trends_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/experience_provider.dart';
import 'notification_service.dart';

class AdaptiveNotificationService {
  final NotificationService _notificationService;

  AdaptiveNotificationService(this._notificationService);

  Future<void> scheduleAdaptiveNotifications(
      BuildContext context,
      UserData userData,
      ActivityProvider activityProvider,
      StepCounterProvider stepCounterProvider,
      TrendsProvider trendsProvider,
      {AchievementProvider? achievementProvider,
      ExperienceProvider? experienceProvider}) async {
    
    // Determine appropriate time based on user's schedule
    final time = _determineOptimalNotificationTime(userData);
    
    // Generate personalized messages
    final messages = _generateSmartMessages(
        userData, 
        activityProvider, 
        stepCounterProvider, 
        trendsProvider,
        achievementProvider,
        experienceProvider
    );
    
    if (messages.isEmpty) {
      return;
    }

    // Select message with weighted probability
    final message = _selectWeightedMessage(messages);
    
    await _notificationService.scheduleNotification(
      context,
      message['title']!,
      message['body']!,
      time,
      'adaptive_notification',
    );
  }
  
  TimeOfDay _determineOptimalNotificationTime(UserData userData) {
    final random = Random();
    final now = TimeOfDay.now();
    final currentHour = now.hour;
    
    // Morning (8-11 AM)
    if (currentHour >= 8 && currentHour < 11) {
      return TimeOfDay(
        hour: 8 + random.nextInt(3), 
        minute: random.nextInt(60)
      );
    }
    
    // Lunch time (12-2 PM)
    else if (currentHour >= 11 && currentHour < 14) {
      return TimeOfDay(
        hour: 12 + random.nextInt(2), 
        minute: random.nextInt(60)
      );
    }
    
    // Afternoon (2-5 PM)
    else if (currentHour >= 14 && currentHour < 17) {
      return TimeOfDay(
        hour: 14 + random.nextInt(3), 
        minute: random.nextInt(60)
      );
    }
    
    // Evening (5-9 PM)
    else if (currentHour >= 17 && currentHour < 21) {
      return TimeOfDay(
        hour: 17 + random.nextInt(4), 
        minute: random.nextInt(60)
      );
    }
    
    // Default (10 AM to 6 PM)
    else {
      return TimeOfDay(
        hour: 10 + random.nextInt(8), 
        minute: random.nextInt(60)
      );
    }
  }
  
  Map<String, String> _selectWeightedMessage(List<Map<String, dynamic>> messages) {
    // Sort messages by priority (higher is more important)
    messages.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    
    final random = Random();
    final totalWeight = messages.fold<int>(0, (sum, item) => sum + (item['priority'] as int));
    int randomValue = random.nextInt(totalWeight);
    
    for (var message in messages) {
      randomValue -= message['priority'] as int;
      if (randomValue < 0) {
        return {
          'title': message['title'] as String,
          'body': message['body'] as String,
        };
      }
    }
    
    // Fallback to first message if something goes wrong
    return {
      'title': messages.first['title'] as String,
      'body': messages.first['body'] as String,
    };
  }

  List<Map<String, dynamic>> _generateSmartMessages(
      UserData userData,
      ActivityProvider activityProvider,
      StepCounterProvider stepCounterProvider,
      TrendsProvider trendsProvider,
      AchievementProvider? achievementProvider,
      ExperienceProvider? experienceProvider) {
    
    final messages = <Map<String, dynamic>>[];
    final now = TimeOfDay.now();
    final currentHour = now.hour;
    
    // ===== PROGRESS-BASED MESSAGES =====
    
    // Step progress
    final stepGoal = userData.dailyStepGoal ?? 10000;
    final stepProgress = stepCounterProvider.todaySteps / stepGoal;
    
    if (stepProgress >= 0.9 && stepProgress < 1.0) {
      messages.add({
        'title': 'Almost There!',
        'body': 'Just ${stepGoal - stepCounterProvider.todaySteps} more steps to reach your daily goal!',
        'priority': 8,
      });
    } else if (stepProgress >= 0.5 && stepProgress < 0.75) {
      messages.add({
        'title': 'Halfway There!',
        'body': 'You\'ve taken ${stepCounterProvider.todaySteps} steps today. Keep going!',
        'priority': 6,
      });
    } else if (stepProgress < 0.3 && currentHour >= 14) {
      messages.add({
        'title': 'Time for a Walk?',
        'body': 'You\'ve only reached ${(stepProgress * 100).toInt()}% of your step goal today. A short walk could help!',
        'priority': 7,
      });
    }
    
    // Streak motivation
    if (stepCounterProvider.streak >= 2) {
      messages.add({
        'title': 'Keep Your Streak Going!',
        'body': 'You\'ve met your step goal for ${stepCounterProvider.streak} days in a row. Don\'t break the chain!',
        'priority': 7,
      });
    }
    
    // ===== HEALTH CONDITION SPECIFIC MESSAGES =====
    
    // Diabetes-specific
    if (userData.hasDiabetes == true) {
      messages.add({
        'title': 'Blood Sugar Management',
        'body': 'Regular physical activity helps manage blood sugar levels. Consider a 15-minute walk after your next meal.',
        'priority': 9,
      });
      
      // Water reminder for diabetics
      final checkinData = trendsProvider.getTodayCheckinData();
      if (checkinData.waterIntake < 6 && currentHour >= 14) {
        messages.add({
          'title': 'Hydration Reminder',
          'body': 'Staying hydrated is especially important for managing diabetes. Have you had enough water today?',
          'priority': 8,
        });
      }
    }
    
    // ===== TIME-AWARE MESSAGES =====
    
    // Morning messages (6-11 AM)
    if (currentHour >= 6 && currentHour < 11) {
      messages.add({
        'title': 'Morning Boost',
        'body': 'Starting your day with a glass of water can boost your metabolism by up to 30%.',
        'priority': 5,
      });
      
      if (userData.wakeupTime != null) {
        final wakeupHour = userData.wakeupTime!.hour;
        if (currentHour - wakeupHour >= 1) {
          messages.add({
            'title': 'Morning Movement',
            'body': 'A quick 5-minute stretch after waking up can improve your energy levels throughout the day.',
            'priority': 6,
          });
        }
      }
    }
    
    // Midday messages (11-3 PM)
    else if (currentHour >= 11 && currentHour < 15) {
      messages.add({
        'title': 'Lunch Break Tip',
        'body': 'Taking a short walk after lunch can aid digestion and prevent the afternoon energy slump.',
        'priority': 6,
      });
    }
    
    // Afternoon messages (3-6 PM)
    else if (currentHour >= 15 && currentHour < 18) {
      messages.add({
        'title': 'Afternoon Reminder',
        'body': 'The afternoon is a great time to refill your water bottle and stay hydrated.',
        'priority': 5,
      });
    }
    
    // Evening messages (6-9 PM)
    else if (currentHour >= 18 && currentHour < 21) {
      if (userData.sleepTime != null) {
        final sleepHour = userData.sleepTime!.hour;
        final hoursToSleep = sleepHour < currentHour ? 
            (sleepHour + 24) - currentHour : 
            sleepHour - currentHour;
            
        if (hoursToSleep <= 3) {
          messages.add({
            'title': 'Wind Down Time',
            'body': 'Consider reducing screen time as you prepare for sleep in the next few hours.',
            'priority': 7,
          });
        }
      }
    }
    
    // ===== ACTIVITY SUGGESTIONS =====
    
    // Incomplete tasks
    final incompleteTasks = activityProvider.activities.where((a) => !a.isDone).toList();
    if (incompleteTasks.isNotEmpty) {
      final task = incompleteTasks[Random().nextInt(incompleteTasks.length)];
      messages.add({
        'title': 'Task Reminder',
        'body': 'Don\'t forget to complete your "${task.label}" task today.',
        'priority': 6,
      });
    }
    
    // No completed tasks yet
    if (activityProvider.activities.where((a) => a.isDone).isEmpty && 
        activityProvider.activities.isNotEmpty &&
        currentHour >= 14) {
      messages.add({
        'title': 'Ready for a challenge?',
        'body': 'You haven\'t completed any tasks today. Let\'s get started with one small step!',
        'priority': 7,
      });
    }
    
    // ===== ACHIEVEMENT & LEVEL PROGRESS =====
    
    if (achievementProvider != null) {
      final unlockedCount = achievementProvider.unlockedAchievements.length;
      final totalCount = achievementProvider.allAchievements.length;
      
      if (unlockedCount > 0 && unlockedCount < totalCount) {
        messages.add({
          'title': 'Achievement Progress',
          'body': 'You\'ve unlocked $unlockedCount out of $totalCount achievements. Keep up the good work!',
          'priority': 5,
        });
      }
    }
    
    if (experienceProvider != null) {
      final xpProgress = experienceProvider.xp / experienceProvider.xpForNextLevel;
      if (xpProgress >= 0.8 && xpProgress < 1.0) {
        messages.add({
          'title': 'Almost to Level ${experienceProvider.level + 1}!',
          'body': 'You\'re very close to leveling up! Complete a few more activities to reach the next level.',
          'priority': 7,
        });
      }
    }
    
    // ===== PERSONALIZED HEALTH TIPS =====
    
    // Diet-specific tips
    if (userData.dietPreference != null) {
      switch (userData.dietPreference!.name) {
        case 'Vegetarian':
          messages.add({
            'title': 'Vegetarian Protein Tip',
            'body': 'Combining legumes with grains creates complete proteins. Try rice and beans or hummus with whole wheat pita.',
            'priority': 5,
          });
          break;
        case 'Vegan':
          messages.add({
            'title': 'Vegan Nutrition Tip',
            'body': 'Consider foods fortified with B12 or a supplement, as this vitamin is primarily found in animal products.',
            'priority': 5,
          });
          break;
        case 'Keto':
          messages.add({
            'title': 'Keto-Friendly Snack Idea',
            'body': 'Avocados, nuts, and cheese make excellent keto-friendly snacks that can help you stay in ketosis.',
            'priority': 5,
          });
          break;
        default:
          messages.add({
            'title': 'Balanced Diet Reminder',
            'body': 'Aim for a colorful plate - different colored fruits and vegetables provide different nutrients.',
            'priority': 4,
          });
      }
    }
    
    // Age-specific tips
    if (userData.age != null) {
      if (userData.age! < 30) {
        messages.add({
          'title': 'Building Healthy Habits',
          'body': 'Habits formed now can last a lifetime. Focus on consistency rather than intensity in your health routine.',
          'priority': 4,
        });
      } else if (userData.age! >= 30 && userData.age! < 50) {
        messages.add({
          'title': 'Midlife Health Tip',
          'body': 'Regular strength training becomes increasingly important after 30 to maintain muscle mass and metabolism.',
          'priority': 4,
        });
      } else {
        messages.add({
          'title': 'Healthy Aging Tip',
          'body': 'Balance exercises like standing on one foot can help prevent falls and maintain independence as you age.',
          'priority': 4,
        });
      }
    }
    
    // ===== GENERAL HEALTH FACTS =====
    
    // Add some general health facts with lower priority
    final healthFacts = [
      {
        'title': 'Hydration Fact',
        'body': 'Even mild dehydration can affect your mood, energy level, and cognitive function.',
        'priority': 3,
      },
      {
        'title': 'Sleep Quality Tip',
        'body': 'The blue light from screens can interfere with melatonin production. Try to avoid screens 1-2 hours before bedtime.',
        'priority': 3,
      },
      {
        'title': 'Nutrition Fact',
        'body': 'Eating slowly gives your body time to recognize when you\'re full, which can prevent overeating.',
        'priority': 3,
      },
      {
        'title': 'Mental Health Tip',
        'body': 'Just 5 minutes of mindfulness meditation can help reduce stress and improve focus.',
        'priority': 3,
      },
      {
        'title': 'Movement Reminder',
        'body': 'Breaking up long periods of sitting with even short movement breaks can improve your health.',
        'priority': 3,
      },
    ];
    
    // Add 2 random health facts
    final random = Random();
    healthFacts.shuffle(random);
    messages.addAll(healthFacts.take(2));
    
    return messages;
  }
}
