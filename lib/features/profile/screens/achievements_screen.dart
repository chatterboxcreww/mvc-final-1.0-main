// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\screens\achievements_screen.dart

// lib/features/profile/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../../core/models/achievement.dart';
import '../../../core/providers/achievement_provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementProvider = Provider.of<AchievementProvider>(context);
    final allAchievements = achievementProvider.allAchievements;
    final unlockedAchievements = achievementProvider.unlockedAchievements;
    
    // Group achievements by category
    final Map<AchievementCategory, List<Achievement>> achievementsByCategory = {};
    for (final achievement in allAchievements) {
      if (!achievementsByCategory.containsKey(achievement.category)) {
        achievementsByCategory[achievement.category] = [];
      }
      achievementsByCategory[achievement.category]!.add(achievement);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Achievements',
      ),
      body: Stack(
        children: [
          // Glass background
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: AlwaysStoppedAnimation(0.5),
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
          // Content
          Column(
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
              // Tab bar with glass effect
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'All', icon: Icon(Icons.emoji_events_outlined)),
                    Tab(text: 'Categories', icon: Icon(Icons.category_outlined)),
                  ],
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ],
                    ),
                  ),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllAchievementsTab(allAchievements, unlockedAchievements),
                    _buildCategoriesTab(achievementsByCategory),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllAchievementsTab(List<Achievement> allAchievements, List<Achievement> unlockedAchievements) {
    // Sort achievements: unlocked first (by unlock date), then locked
    final sortedAchievements = List<Achievement>.from(allAchievements);
    sortedAchievements.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      if (a.isUnlocked && b.isUnlocked) {
        return (b.unlockedAt ?? DateTime.now()).compareTo(a.unlockedAt ?? DateTime.now());
      }
      return a.name.compareTo(b.name);
    });

    return Column(
      children: [
        // Progress indicator with glass effect
        GlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${unlockedAchievements.length}/${allAchievements.length}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: allAchievements.isNotEmpty ? unlockedAchievements.length / allAchievements.length : 0,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${((unlockedAchievements.length / allAchievements.length) * 100).toStringAsFixed(1)}% Complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Achievements list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedAchievements.length,
            itemBuilder: (context, index) {
              final achievement = sortedAchievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(Map<AchievementCategory, List<Achievement>> achievementsByCategory) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: achievementsByCategory.entries.map((entry) {
          final category = entry.key;
          final achievements = entry.value;
          final unlockedCount = achievements.where((a) => a.isUnlocked).length;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: Icon(_getCategoryIcon(category)),
              title: Text(_getCategoryDisplayName(category)),
              subtitle: Text('$unlockedCount/${achievements.length} unlocked'),
              children: achievements.map((achievement) => _buildAchievementCard(achievement)).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnlocked = achievement.isUnlocked;
    
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.6,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
            children: [
              // Achievement icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? _getCategoryColor(achievement.category).withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked 
                        ? _getCategoryColor(achievement.category)
                        : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: achievement.icon.endsWith('.svg')
                    ? SvgPicture.asset(
                        achievement.icon,
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                          isUnlocked 
                              ? _getCategoryColor(achievement.category)
                              : colorScheme.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                      )
                    : Image.asset(
                        achievement.icon,
                        width: 32,
                        height: 32,
                        color: isUnlocked 
                            ? _getCategoryColor(achievement.category)
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Achievement details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isUnlocked 
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isUnlocked)
                          Icon(
                            Icons.check_circle,
                            color: _getCategoryColor(achievement.category),
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isUnlocked 
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Progress bar for achievements in progress
                    if (!isUnlocked && achievement.progress > 0) ...[
                      LinearProgressIndicator(
                        value: achievement.progress,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(achievement.category),
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${achievement.currentValue}/${achievement.targetValue}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    
                    // Unlock date for completed achievements
                    if (isUnlocked && achievement.unlockedAt != null)
                      Text(
                        'Unlocked: ${DateFormat('MMM d, yyyy').format(achievement.unlockedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getCategoryColor(achievement.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  String _getCategoryDisplayName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.water:
        return 'Water & Hydration';
      case AchievementCategory.steps:
        return 'Steps & Movement';
      case AchievementCategory.sleep:
        return 'Sleep & Rest';
      case AchievementCategory.meditation:
        return 'Meditation & Mindfulness';
      case AchievementCategory.level:
        return 'Level Progression';
      case AchievementCategory.combo:
        return 'Combinations & Streaks';
      case AchievementCategory.social:
        return 'Social & Community';
      case AchievementCategory.app:
        return 'App Usage';
      case AchievementCategory.explorer:
        return 'Feature Explorer';
      case AchievementCategory.time:
        return 'Time-based';
      case AchievementCategory.seasonal:
        return 'Seasonal';
      case AchievementCategory.challenge:
        return 'Challenges';
    }
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.water:
        return Icons.water_drop;
      case AchievementCategory.steps:
        return Icons.directions_walk;
      case AchievementCategory.sleep:
        return Icons.bedtime;
      case AchievementCategory.meditation:
        return Icons.self_improvement;
      case AchievementCategory.level:
        return Icons.trending_up;
      case AchievementCategory.combo:
        return Icons.emoji_events;
      case AchievementCategory.social:
        return Icons.group;
      case AchievementCategory.app:
        return Icons.phone_android;
      case AchievementCategory.explorer:
        return Icons.explore;
      case AchievementCategory.time:
        return Icons.access_time;
      case AchievementCategory.seasonal:
        return Icons.calendar_today;
      case AchievementCategory.challenge:
        return Icons.flag;
    }
  }

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.water:
        return Colors.blue;
      case AchievementCategory.steps:
        return Colors.green;
      case AchievementCategory.sleep:
        return Colors.indigo;
      case AchievementCategory.meditation:
        return Colors.purple;
      case AchievementCategory.level:
        return Colors.orange;
      case AchievementCategory.combo:
        return Colors.amber;
      case AchievementCategory.social:
        return Colors.pink;
      case AchievementCategory.app:
        return Colors.teal;
      case AchievementCategory.explorer:
        return Colors.cyan;
      case AchievementCategory.time:
        return Colors.brown;
      case AchievementCategory.seasonal:
        return Colors.deepOrange;
      case AchievementCategory.challenge:
        return Colors.red;
    }
  }
}

