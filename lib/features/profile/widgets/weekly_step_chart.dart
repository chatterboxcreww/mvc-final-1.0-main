// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\weekly_step_chart.dart

// lib/features/profile/widgets/weekly_step_chart.dart
import 'dart:math'; // IMPORT THIS for the max() function
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/daily_step_data.dart';

class WeeklyStepChart extends StatelessWidget {
  final List<DailyStepData> weeklyData;
  const WeeklyStepChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    // Ensure we have data for the last 7 days, even if it's 0 steps
    final List<DailyStepData> chartData = [];
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day - i);
      final data = weeklyData.firstWhere(
            (d) =>
        d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
        orElse: () => DailyStepData(date: date, steps: 0, goal: 10000),
      );
      chartData.add(data);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // FIX: Correctly calculate the maximum Y value for the chart axis
    final maxSteps = chartData.isEmpty ? 10000.0 : chartData.map((d) => d.steps).reduce(max).toDouble();
    final maxGoal = chartData.isEmpty ? 10000.0 : chartData.map((d) => d.goal).reduce(max).toDouble();
    final yMax = max(maxSteps, maxGoal) * 1.2;

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // FIX: Use 'getTooltipColor' callback for fl_chart 1.0.0
              getTooltipColor: (group) {
                return colorScheme.surfaceContainerHighest;
              },
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final data = chartData[groupIndex];
                return BarTooltipItem(
                  '${data.steps}\n',
                  TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Goal: ${data.goal}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                // The 'getTitlesWidget' property is used in this version
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value >= meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                // The 'getTitlesWidget' property is used in this version
                getTitlesWidget: (double value, TitleMeta meta) {
                  final day = chartData[value.toInt()].date;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('E').format(day),
                      style: textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outline.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: chartData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final isGoalMet = data.steps >= data.goal;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.steps.toDouble(),
                  color: isGoalMet
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
