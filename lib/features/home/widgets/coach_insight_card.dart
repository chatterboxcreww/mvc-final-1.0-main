import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/models/coach_insight.dart';
import '../../../shared/widgets/glass_container.dart';

class CoachInsightCard extends StatelessWidget {
  final String insight;

  const CoachInsightCard({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getInsightColor(CoachInsightType.general).withOpacity(isDark ? 0.15 : 0.1),
              _getInsightColor(CoachInsightType.general).withOpacity(isDark ? 0.05 : 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getInsightColor(CoachInsightType.general).withOpacity(isDark ? 0.3 : 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getInsightIcon(CoachInsightType.general),
                      color: _getInsightColor(CoachInsightType.general),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'General',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getInsightColor(CoachInsightType.general).withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'GENERAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getInsightColor(CoachInsightType.general),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Just now',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getInsightColor(CoachInsightType type) {
    switch (type) {
      case CoachInsightType.steps:
        return Colors.green;
      case CoachInsightType.water:
        return Colors.blue;
      case CoachInsightType.sleep:
        return Colors.indigo;
      case CoachInsightType.nutrition:
        return Colors.orange;
      case CoachInsightType.achievement:
        return Colors.amber;
      case CoachInsightType.motivation:
        return Colors.purple;
      case CoachInsightType.warning:
        return Colors.red;
      case CoachInsightType.general:
      default:
        return Colors.grey;
    }
  }

  IconData _getInsightIcon(CoachInsightType type) {
    switch (type) {
      case CoachInsightType.steps:
        return Icons.directions_walk;
      case CoachInsightType.water:
        return Icons.water_drop;
      case CoachInsightType.sleep:
        return Icons.bedtime;
      case CoachInsightType.nutrition:
        return Icons.restaurant;
      case CoachInsightType.achievement:
        return Icons.emoji_events;
      case CoachInsightType.motivation:
        return Icons.psychology;
      case CoachInsightType.warning:
        return Icons.warning;
      case CoachInsightType.general:
      default:
        return Icons.lightbulb;
    }
  }
}
