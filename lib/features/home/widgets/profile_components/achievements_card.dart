// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\achievements_card.dart

// lib/features/home/widgets/profile_components/achievements_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/achievement_provider.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../profile/screens/achievements_screen.dart';

class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        final unlockedCount = achievementProvider.unlockedAchievements.length;
        final totalCount = achievementProvider.allAchievements.length;
        final achievementProgress = totalCount > 0 ? unlockedCount / totalCount : 0.0;
        final colorScheme = Theme.of(context).colorScheme;
        
        // Minimal margins for compact layout
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        final cardMargin = isSmallScreen 
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        
        return GlassCard(
          margin: cardMargin,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, 
                       color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Achievements',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                       color: colorScheme.onSurfaceVariant, size: 16),
                ],
              ),
                  const SizedBox(height: 16),
                  
                  // Achievement stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unlockedCount / $totalCount',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            'Unlocked',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${(achievementProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Progress bar
                  LinearProgressIndicator(
                    value: achievementProgress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    'Tap to view all achievements',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }
}

