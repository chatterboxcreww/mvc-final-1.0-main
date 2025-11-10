// lib/features/home/widgets/quick_tips_card.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/glass_container.dart';

/// Displays helpful tips for new users on the home screen
class QuickTipsCard extends StatefulWidget {
  const QuickTipsCard({super.key});

  @override
  State<QuickTipsCard> createState() => _QuickTipsCardState();
}

class _QuickTipsCardState extends State<QuickTipsCard> {
  int _currentTipIndex = 0;
  bool _isDismissed = false;

  final List<QuickTip> _tips = [
    QuickTip(
      icon: Icons.water_drop_rounded,
      title: 'Stay Hydrated',
      description: 'Tap the + button on the Water Tracker to log each glass you drink. Earn 5 XP per glass!',
      color: Colors.blue,
    ),
    QuickTip(
      icon: Icons.directions_walk_rounded,
      title: 'Track Your Steps',
      description: 'Your phone automatically counts steps. Tap the Step Tracker card to view detailed history.',
      color: Colors.green,
    ),
    QuickTip(
      icon: Icons.restaurant_menu_rounded,
      title: 'Explore the Feed',
      description: 'Get personalized meal suggestions in the Feed tab. Tap recipes for full details!',
      color: Colors.orange,
    ),
    QuickTip(
      icon: Icons.task_alt_rounded,
      title: 'Daily Check-in',
      description: 'Complete your daily check-in in the Progress tab to track mood, sleep, and stress.',
      color: Colors.purple,
    ),
    QuickTip(
      icon: Icons.emoji_events_rounded,
      title: 'Unlock Achievements',
      description: 'Complete activities to earn XP, level up, and unlock special achievement badges!',
      color: Colors.amber,
    ),
    QuickTip(
      icon: Icons.notifications_active_rounded,
      title: 'Set Reminders',
      description: 'Create custom activities with reminders in the Progress tab to build healthy habits.',
      color: Colors.pink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('quick_tips_dismissed') ?? false;
    if (mounted) {
      setState(() {
        _isDismissed = dismissed;
      });
    }
  }

  Future<void> _dismissTips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quick_tips_dismissed', true);
    if (mounted) {
      setState(() {
        _isDismissed = true;
      });
    }
  }

  void _nextTip() {
    if (mounted) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
      });
    }
  }

  void _previousTip() {
    if (mounted) {
      setState(() {
        _currentTipIndex = (_currentTipIndex - 1 + _tips.length) % _tips.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final currentTip = _tips[_currentTipIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentTip.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: currentTip.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quick Tip',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _dismissTips,
                tooltip: 'Dismiss tips',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Tip content
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentTip.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentTip.icon,
                  color: currentTip.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTip.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentTip.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentTip.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  _tips.length,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentTipIndex == index
                          ? currentTip.color
                          : colorScheme.onSurfaceVariant.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: _previousTip,
                    tooltip: 'Previous tip',
                  ),
                  Text(
                    '${_currentTipIndex + 1}/${_tips.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _nextTip,
                    tooltip: 'Next tip',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickTip {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  QuickTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
