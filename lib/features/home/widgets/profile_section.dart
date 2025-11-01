// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_section.dart

// lib/features/home/widgets/profile_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/user_data_provider.dart';
import '../../../core/providers/experience_provider.dart';
import 'profile_components/experience_card.dart';
import 'profile_components/achievements_card.dart';
import 'profile_components/personal_info_card.dart';
import 'profile_components/sleep_schedule_card.dart';
import 'profile_components/diet_preferences_card.dart';
import 'profile_components/health_info_card.dart';
import 'profile_components/reminders_card.dart';
import 'profile_components/app_theme_card.dart';
import 'profile_components/level_circle_painter.dart';

class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  @override
  Widget build(BuildContext context) {
    final userDataProvider = Provider.of<UserDataProvider>(context);
    final experienceProvider = Provider.of<ExperienceProvider>(context);
    final userData = userDataProvider.userData;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    ImageProvider<Object>? profileImage;
    if (userData.profilePicturePath != null &&
        userData.profilePicturePath!.startsWith('http')) {
      profileImage = NetworkImage(userData.profilePicturePath!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Avatar with LinkedIn-style Level Circle
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Level circle around profile picture
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: LevelCirclePainter(
                      level: experienceProvider.level,
                      primaryColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      xp: experienceProvider.xp,
                      xpForNextLevel: experienceProvider.xpForNextLevel,
                    ),
                  ),
                ),
                // Profile picture
                CircleAvatar(
                  radius: 70,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: profileImage,
                  child: profileImage == null
                      ? Icon(Icons.person_rounded,
                          size: 80,
                          color: colorScheme.primary.withValues(alpha: 0.8))
                      : null,
                ),
                // Level text at the top
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Level ${experienceProvider.level}',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Experience Card
          const ExperienceCard(),
          
          // Achievements Card
          const AchievementsCard(),
          
          // Personal Information Card
          PersonalInfoCard(userData: userData),
          
          // Sleep Schedule Card
          const SleepScheduleCard(),
          
          // Diet & Preferences Card
          DietPreferencesCard(userData: userData),
          
          // Health Information Card
          HealthInfoCard(userData: userData),
          
          // Reminders Card
          const RemindersCard(),
          
          // App Theme Card
          const AppThemeCard(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
