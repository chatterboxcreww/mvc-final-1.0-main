// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\screens\step_history_screen.dart

// lib/features/profile/screens/step_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../../core/models/daily_step_data.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';

class StepHistoryScreen extends StatefulWidget {
  const StepHistoryScreen({super.key});

  @override
  State<StepHistoryScreen> createState() => _StepHistoryScreenState();
}

class _StepHistoryScreenState extends State<StepHistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _bgController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepCounterProvider>();
    final userProvider = context.watch<UserDataProvider>();
    final stepData = stepProvider.weeklyStepData;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Step History',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: _bgController,
                colorScheme: colorScheme,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                GlassContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.zero,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Chart', icon: Icon(Icons.bar_chart)),
                      Tab(text: 'Details', icon: Icon(Icons.list)),
                    ],
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.3),
                          colorScheme.primary.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChartTab(stepData, userProvider.userData.dailyStepGoal ?? 10000),
                      _buildDetailsTab(stepData, userProvider.userData.dailyStepGoal ?? 10000),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(List<DailyStepData> stepData, int stepGoal) {
    if (stepData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No step data available'),
            Text('Start walking to see your progress!'),
          ],
        ),
      );
    }

    // Sort data by date and take last 7 days
    final sortedData = List<DailyStepData>.from(stepData);
    sortedData.sort((a, b) => a.date.compareTo(b.date));
    final last7Days = sortedData.length > 7 
        ? sortedData.sublist(sortedData.length - 7)
        : sortedData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryCards(stepData, stepGoal),
          const SizedBox(height: 24),
          
          // Chart
          Text(
            'Last 7 Days',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildBarChart(last7Days, stepGoal),
          ),
          
          const SizedBox(height: 24),
          
          // Weekly total
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Total Steps', _getTotalSteps(last7Days).toString()),
                  _buildSummaryRow('Daily Average', (_getTotalSteps(last7Days) / 7).round().toString()),
                  _buildSummaryRow('Goals Met', '${_getGoalsMet(last7Days)} / 7'),
                  _buildSummaryRow('Best Day', _getBestDay(last7Days)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(List<DailyStepData> stepData, int stepGoal) {
    if (stepData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No step data available'),
            Text('Start walking to see your history!'),
          ],
        ),
      );
    }

    // Sort data by date (most recent first)
    final sortedData = List<DailyStepData>.from(stepData);
    sortedData.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedData.length,
      itemBuilder: (context, index) {
        final data = sortedData[index];
        return _buildStepDataCard(data);
      },
    );
  }

  Widget _buildSummaryCards(List<DailyStepData> stepData, int stepGoal) {
    final totalSteps = _getTotalSteps(stepData);
    final avgSteps = stepData.isNotEmpty ? (totalSteps / stepData.length).round() : 0;
    final goalsMet = _getGoalsMet(stepData);
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Steps',
            totalSteps.toString(),
            Icons.directions_walk,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Daily Average',
            avgSteps.toString(),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Goals Met',
            '$goalsMet/${stepData.length}',
            Icons.flag,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildBarChart(List<DailyStepData> data, int stepGoal) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (stepGoal * 1.5).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: stepGoal / 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colorScheme.outline.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: colorScheme.outline),
            left: BorderSide(color: colorScheme.outline),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: stepGoal / 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
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
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final stepData = entry.value;
          final goalMet = stepData.steps >= stepData.goal;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stepData.steps.toDouble(),
                color: goalMet ? colorScheme.primary : colorScheme.error,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: stepGoal.toDouble(),
              color: colorScheme.primary.withValues(alpha: 0.7),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (line) => 'Goal: $stepGoal',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDataCard(DailyStepData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final goalMet = data.steps >= data.goal;
    final progressPercent = (data.steps / data.goal * 100).clamp(0, 100);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(data.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goalMet 
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goalMet ? 'Goal Met' : 'Goal Missed',
                    style: TextStyle(
                      color: goalMet 
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${data.steps} steps',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progressPercent.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            LinearProgressIndicator(
              value: data.steps / data.goal,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                goalMet ? colorScheme.primary : colorScheme.error,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Goal: ${data.goal} steps',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  int _getTotalSteps(List<DailyStepData> data) {
    return data.fold(0, (sum, item) => sum + item.steps);
  }

  int _getGoalsMet(List<DailyStepData> data) {
    return data.where((item) => item.steps >= item.goal).length;
  }

  String _getBestDay(List<DailyStepData> data) {
    if (data.isEmpty) return 'None';
    
    final bestDay = data.reduce((a, b) => a.steps > b.steps ? a : b);
    return DateFormat('MMM d').format(bestDay.date);
  }
}

