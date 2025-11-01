// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\progress_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/app_enums.dart';
import '../../../core/providers/activity_provider.dart';
import '../../../core/providers/experience_provider.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/animated_list_item.dart';

class ProgressSection extends StatefulWidget {
  const ProgressSection({super.key});

  @override
  State<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<ProgressSection>
    with TickerProviderStateMixin {
  final TextEditingController _customActivityController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isAddingActivity = false;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _progressAnimationController.forward();
  }

  @override
  void dispose() {
    _customActivityController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _addCustomActivity() async {
    if (_customActivityController.text.trim().isEmpty) {
      _showSnackBar('Please enter an activity name', isError: true);
      return;
    }

    setState(() => _isAddingActivity = true);

    try {
      final newActivity = Activity(
        id: const Uuid().v4(),
        label: _customActivityController.text.trim(),
        time: _selectedTime,
        type: 'Custom',
        isCustom: true,
        recurrence: NotificationRecurrence.daily,
      );

      await context.read<ActivityProvider>().addActivity(newActivity);

      // Schedule notification if time is set
      if (_selectedTime != null && mounted) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        await notificationService.scheduleNotification(
          context,
          'Task Reminder',
          'Time to: ${newActivity.label}',
          _selectedTime!,
          'custom_activity_${newActivity.id}',
          recurrence: NotificationRecurrence.daily,
        );
      }

      _customActivityController.clear();
      _selectedTime = null;

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Added "${newActivity.label}" to your tasks!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to add activity: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingActivity = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Select reminder time',
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customActivityController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Name',
                    hintText: 'e.g., Take vitamins, Stretch',
                    prefixIcon: Icon(Icons.task_alt),
                  ),
                  maxLength: 50,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(
                      _selectedTime != null
                          ? 'Reminder: ${_selectedTime!.format(context)}'
                          : 'No reminder set',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await _selectTime();
                        setDialogState(() {});
                      },
                      child: const Text('Set Time'),
                    ),
                  ),
                ),
                if (_selectedTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You\'ll get a daily reminder at this time',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isAddingActivity ? null : _addCustomActivity,
              child: _isAddingActivity
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final activities = activityProvider.activities;
        final completedCount = activities.where((a) => a.isDone).length;
        final totalCount = activities.length;
        final progressPercentage = totalCount > 0 ? completedCount / totalCount : 0.0;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Enhanced Progress Overview Card
              AnimatedListItem(
                index: 0,
                child: _buildProgressCard(
                  completedCount,
                  totalCount,
                  progressPercentage,
                ),
              ),
              const SizedBox(height: 16),

              // Add Activity Button
              AnimatedListItem(
                index: 1,
                child: _buildAddActivityButton(),
              ),
              const SizedBox(height: 16),

              // Activities List or Empty State
              if (activities.isEmpty)
                AnimatedListItem(
                  index: 2,
                  child: _buildEmptyState(),
                )
              else
                ..._buildActivityList(activities),

              const SizedBox(height: 20),

              // Enhanced Summary Card
              if (activities.isNotEmpty)
                AnimatedListItem(
                  index: activities.length + 2,
                  child: _buildSummaryCard(
                    completedCount,
                    totalCount,
                    progressPercentage,
                  ),
                ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(int completed, int total, double progress) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.primaryContainer.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Progress',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getProgressMessage(progress),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$completed/$total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animated Progress Bar
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress * _progressAnimation.value,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(progress),
                            ),
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}% Complete',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (progress >= 1.0)
                              Icon(
                                Icons.celebration,
                                color: Colors.amber,
                                size: 20,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddActivityButton() {
    return ElevatedButton.icon(
      onPressed: _showAddActivityDialog,
      icon: const Icon(Icons.add_task),
      label: const Text('Add Custom Activity'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No activities yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some tasks to track your daily progress and build healthy habits!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _showAddActivityDialog,
              icon: const Icon(Icons.add),
              label: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityList(List<Activity> activities) {
    return activities.asMap().entries.map((entry) {
      final index = entry.key;
      final activity = entry.value;

      return AnimatedListItem(
        index: index + 2,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildActivityTile(activity),
        ),
      );
    }).toList();
  }

  Widget _buildActivityTile(Activity activity) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: activity.isDone ? 1 : 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: activity.isDone
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: activity.isDone,
            onChanged: (value) => _toggleActivity(activity),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            activity.label,
            style: TextStyle(
              decoration: activity.isDone ? TextDecoration.lineThrough : null,
              color: activity.isDone
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
              fontWeight: activity.isDone ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          subtitle: _buildActivitySubtitle(activity),
          trailing: activity.isCustom ? _buildDeleteButton(activity) : null,
        ),
      ),
    );
  }

  Widget? _buildActivitySubtitle(Activity activity) {
    final colorScheme = Theme.of(context).colorScheme;

    if (activity.time == null && activity.type == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activity.time != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Reminder: ${activity.time!.format(context)}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        if (activity.type != null && activity.type!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getActivityTypeIcon(activity.type!),
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                activity.type!,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDeleteButton(Activity activity) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _showDeleteDialog(activity),
      tooltip: 'Delete activity',
    );
  }

  Widget _buildSummaryCard(int completed, int total, double progress) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer.withValues(alpha: 0.3),
              colorScheme.secondaryContainer.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total', '$total', Icons.assignment),
                  _buildSummaryItem('Completed', '$completed', Icons.check_circle),
                  _buildSummaryItem('Remaining', '${total - completed}', Icons.pending),
                  _buildSummaryItem('Success', '${(progress * 100).toStringAsFixed(0)}%', Icons.trending_up),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.secondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _toggleActivity(Activity activity) async {
    final activityProvider = context.read<ActivityProvider>();
    final experienceProvider = context.read<ExperienceProvider>();
    final userDataProvider = context.read<UserDataProvider>();

    final updatedActivity = await activityProvider.toggleActivityDone(activity.id);

    if (updatedActivity != null && updatedActivity.isDone && !activity.isDone) {
      // Activity was just completed, award XP
      await experienceProvider.processGains(
        userDataProvider.userData,
        // Custom activity completion XP
      );

      _showSnackBar('Great job completing "${activity.label}"! 🎉');
    }
  }

  void _showDeleteDialog(Activity activity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ActivityProvider>().deleteActivity(activity.id);
              Navigator.of(ctx).pop();
              _showSnackBar('Activity deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getProgressMessage(double progress) {
    if (progress >= 1.0) return 'Amazing! All tasks completed! 🎉';
    if (progress >= 0.8) return 'Almost there! Keep going! 💪';
    if (progress >= 0.5) return 'Great progress so far! 👍';
    if (progress > 0.0) return 'Good start! Let\'s continue! 🚀';
    return 'Ready to begin your day? 🌟';
  }

  Color _getProgressColor(double progress) {
    final colorScheme = Theme.of(context).colorScheme;
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.8) return Colors.lightGreen;
    if (progress >= 0.5) return colorScheme.primary;
    return Colors.orange;
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exercise':
        return Icons.fitness_center;
      case 'hydration':
        return Icons.water_drop;
      case 'wellness':
        return Icons.self_improvement;
      case 'nutrition':
        return Icons.restaurant;
      case 'custom':
        return Icons.task_alt;
      default:
        return Icons.assignment;
    }
  }
}

