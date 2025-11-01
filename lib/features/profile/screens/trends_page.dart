import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/models/daily_checkin_data.dart';
import '../../../core/providers/trends_provider.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/providers/experience_provider.dart';
import '../widgets/daily_checkin_dialog.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Trends'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Charts'),
            Tab(icon: Icon(Icons.history_outlined), text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeaderStats(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Consumer<TrendsProvider>(
      builder: (context, trendsProvider, child) {
        final todayData = trendsProvider.getTodayCheckinData();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Water Today',
                  '${todayData.waterIntake}/8',
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStatCard(
                  'Mood',
                  _getMoodEmoji(todayData.mood),
                  Icons.mood,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStatCard(
                  'Sleep',
                  '${todayData.sleepHours.toStringAsFixed(1)}h',
                  Icons.bedtime,
                  Colors.indigo,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer3<TrendsProvider, ExperienceProvider, StepCounterProvider>(
      builder: (context, trendsProvider, expProvider, stepProvider, child) {
        final checkinHistory = trendsProvider.checkinHistory;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Experience Overview
              _buildExperienceCard(expProvider, stepProvider),
              const SizedBox(height: 16),

              // Wellness Summary
              _buildWellnessSummaryCard(trendsProvider, checkinHistory),
              const SizedBox(height: 16),

              // Weekly Goals Progress
              _buildWeeklyGoalsCard(stepProvider, trendsProvider),
              const SizedBox(height: 80), // Increased bottom spacing to move it up from extreme bottom
            ],
          ),
        );
      },
    );
  }

  Widget _buildExperienceCard(ExperienceProvider expProvider, StepCounterProvider stepProvider) {
    final xpProgress = expProvider.xpForNextLevel > 0
        ? expProvider.xp / expProvider.xpForNextLevel
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${expProvider.level}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: xpProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expProvider.xp} / ${expProvider.xpForNextLevel} XP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stepProvider.streak}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'day streak',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessSummaryCard(TrendsProvider trendsProvider, List<DailyCheckinData> checkinHistory) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Water Streak', '${trendsProvider.getWaterStreak(checkinHistory)} days'),
            _buildSummaryRow('Sleep Quality Days', '${trendsProvider.getConsistentSleepDays(checkinHistory)} days'),
            _buildSummaryRow('Total Meditation', '${trendsProvider.getTotalMeditationMinutes(checkinHistory)} minutes'),
            _buildSummaryRow('Perfect Days', '${trendsProvider.getPerfectDayStreak(checkinHistory)} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalsCard(StepCounterProvider stepProvider, TrendsProvider trendsProvider) {
    final weeklyData = stepProvider.weeklyStepData;
    final goalsMetThisWeek = weeklyData.where((data) => data.goalReached).length;
    
    // Get water goals from weekly analytics
    final waterGoalsThisWeek = trendsProvider.weeklyAnalytics['hydrationGoalDays'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Goals Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24), // Increased spacing
            Row(
              children: [
                Expanded(
                  child: _buildGoalProgressItem(
                    'Step Goals Met',
                    '$goalsMetThisWeek/7',
                    goalsMetThisWeek / 7,
                    Icons.directions_walk,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGoalProgressItem(
                    'Water Goals',
                    '$waterGoalsThisWeek/7',
                    waterGoalsThisWeek / 7,
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressItem(String title, String value, double progress, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return Consumer<TrendsProvider>(
      builder: (context, trendsProvider, child) {
        final checkinHistory = trendsProvider.checkinHistory;

        if (checkinHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No data available'),
                Text('Start checking in daily to see your trends!'),
              ],
            ),
          );
        }

        // Sort data and take last 7 days
        final sortedData = List<DailyCheckinData>.from(checkinHistory);
        sortedData.sort((a, b) => a.date.compareTo(b.date));
        final last7Days = sortedData.length > 7
            ? sortedData.sublist(sortedData.length - 7)
            : sortedData;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Water Intake Chart
              _buildChartCard(
                'Water Intake (Last 7 Days)',
                _buildWaterChart(last7Days),
              ),

              const SizedBox(height: 24),

              // Mood Chart
              _buildChartCard(
                'Mood Trends (Last 7 Days)',
                _buildMoodChart(last7Days),
              ),

              const SizedBox(height: 24),

              // Sleep Chart
              _buildChartCard(
                'Sleep Hours (Last 7 Days)',
                _buildSleepChart(last7Days),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<TrendsProvider>(
      builder: (context, trendsProvider, child) {
        final checkinHistory = trendsProvider.checkinHistory;

        if (checkinHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No check-in history'),
                Text('Start your first daily check-in!'),
              ],
            ),
          );
        }

        // Sort by date (most recent first)
        final sortedHistory = List<DailyCheckinData>.from(checkinHistory);
        sortedHistory.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedHistory.length,
          itemBuilder: (context, index) {
            final data = sortedHistory[index];
            return _buildHistoryCard(data);
          },
        );
      },
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterChart(List<DailyCheckinData> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: Theme.of(context).textTheme.bodySmall);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    DateFormat('E').format(data[index].date),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 12,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.waterIntake.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 8,
              color: Colors.blue.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChart(List<DailyCheckinData> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: Theme.of(context).textTheme.bodySmall);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    DateFormat('E').format(data[index].date),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 1,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.mood.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepChart(List<DailyCheckinData> data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h', style: Theme.of(context).textTheme.bodySmall);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    DateFormat('E').format(data[index].date),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 12,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.sleepHours);
            }).toList(),
            isCurved: true,
            color: Colors.indigo,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 7,
              color: Colors.green.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
            HorizontalLine(
              y: 9,
              color: Colors.green.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DailyCheckinData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(data.date),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.water_drop, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text('Water: ${data.waterIntake}/8 glasses'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.mood, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Text('Mood: ${_getMoodEmoji(data.mood)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.bedtime, size: 18, color: Colors.indigo),
                const SizedBox(width: 6),
                Text('Sleep: ${data.sleepHours.toStringAsFixed(1)} hours'),
              ],
            ),
            if (data.meditationMinutes > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.self_improvement, size: 18, color: Colors.purple),
                  const SizedBox(width: 6),
                  Text('Meditation: ${data.meditationMinutes} minutes'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😔';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '😁';
      default:
        return '🤔';
    }
  }

  void _showDailyCheckinDialog() {
    showDialog(
      context: context,
      builder: (_) => const DailyCheckinDialog(),
    );
  }
}
