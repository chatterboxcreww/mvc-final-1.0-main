// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\daily_checkin_card.dart

// lib/features/home/widgets/daily_checkin_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/daily_checkin_data.dart';
import '../../../core/providers/trends_provider.dart';
import '../../../core/services/daily_sync_service.dart';
import '../../../shared/widgets/glass_container.dart';

class DailyCheckinCard extends StatefulWidget {
  const DailyCheckinCard({super.key});

  @override
  State<DailyCheckinCard> createState() => _DailyCheckinCardState();
}

class _DailyCheckinCardState extends State<DailyCheckinCard> {
  late DailyCheckinData _todayData;
  late TextEditingController _weightController;
  final DailySyncService _dailySyncService = DailySyncService();
  bool _hasCheckedInToday = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _todayData = context.read<TrendsProvider>().getTodayCheckinData();
    _weightController = TextEditingController(
        text: _todayData.weight > 0 ? _todayData.weight.toString() : '');
    _checkDailyCheckinStatus();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  /// Check if user has already completed daily checkin today
  Future<void> _checkDailyCheckinStatus() async {
    final hasCompleted = await _dailySyncService.hasCompletedDailyCheckinToday();
    if (mounted) {
      setState(() {
        _hasCheckedInToday = hasCompleted;
      });
    }
  }

  void _submitCheckin() async {
    // Update weight from controller (optional)
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    _todayData.weight = weight;
    
    // Let mood and water intake remain as they are (dynamic from existing data)
    // No hardcoded values - use existing values from _todayData

    context.read<TrendsProvider>().submitDailyCheckin(_todayData, context: context);
    
    // Mark daily checkin as completed
    await _dailySyncService.markDailyCheckinComplete();
    
    if (mounted) {
      setState(() {
        _hasCheckedInToday = true;
      });
      
      // Get XP reward dynamically from trends provider
      final xpReward = context.read<TrendsProvider>().getDailyCheckinXP();
      
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily check-in completed! You earned $xpReward XP! 🌟'),
            backgroundColor: Colors.green,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.15),
              colorScheme.primaryContainer.withOpacity(isDark ? 0.1 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text("Daily Check-in", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            
            // Show different content based on checkin status
            if (_hasCheckedInToday) ...[
              Consumer<TrendsProvider>(
                builder: (context, trendsProvider, child) {
                  final messages = trendsProvider.getDailyCheckinMessages();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              messages['completedMessage'] ?? "You've already completed your daily check-in today! Come back tomorrow.",
                              style: textTheme.bodyMedium?.copyWith(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        messages['thankYouMessage'] ?? "Thanks for staying consistent with your health tracking! 🎉",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ] else ...[
              Consumer<TrendsProvider>(
                builder: (context, trendsProvider, child) {
                  final messages = trendsProvider.getDailyCheckinMessages();
                  final xpReward = trendsProvider.getDailyCheckinXP();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(messages['prompt'] ?? "Complete your daily check-in to earn experience points!", 
                           style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 20),

                      // Weight Log (Optional)
                      Text(messages['weightLabel'] ?? "Today's Weight (kg) - Optional", 
                           style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: messages['weightHint'] ?? 'Enter weight (optional)',
                          prefixIcon: const Icon(Icons.monitor_weight_outlined),
                          helperText: messages['weightHelper'] ?? 'Leave empty if you prefer not to track weight today',
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _submitCheckin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star),
                            const SizedBox(width: 8),
                            Text(messages['buttonText'] ?? 'Complete Daily Check-in'),
                            const SizedBox(width: 8),
                            Text('+$xpReward XP', style: textTheme.bodySmall?.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            )),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}
