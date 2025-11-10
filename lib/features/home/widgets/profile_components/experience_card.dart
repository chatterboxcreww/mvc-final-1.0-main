// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\experience_card.dart

// lib/features/home/widgets/profile_components/experience_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/experience_provider.dart';
import '../../../../shared/widgets/glass_container.dart';

class ExperienceCard extends StatelessWidget {
  const ExperienceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExperienceProvider>(
      builder: (context, experienceProvider, child) {
        final xpProgress = experienceProvider.xp / experienceProvider.xpForNextLevel;
        final colorScheme = Theme.of(context).colorScheme;
        
        // Minimal margins for compact layout
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        final cardMargin = isSmallScreen 
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        
        return GlassCard(
          margin: cardMargin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, 
                       color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Experience & Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 16),
                
                // Level and XP info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${experienceProvider.level}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'XP: ${experienceProvider.xp} / ${experienceProvider.xpForNextLevel}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(xpProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Progress bar
                LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Keep completing activities to level up!',
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

