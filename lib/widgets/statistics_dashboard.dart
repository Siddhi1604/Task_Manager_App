import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class StatisticsDashboard extends StatelessWidget {
  final List<Task> tasks;
  final int daysToShow;

  const StatisticsDashboard({
    super.key,
    required this.tasks,
    this.daysToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    final overdueTasks = pendingTasks
        .where((task) => task.dueDate.isBefore(DateTime.now()))
        .toList();
        
    final totalTasks = tasks.length;
    final completionRate = totalTasks > 0 
        ? (completedTasks.length / totalTasks * 100).toStringAsFixed(1) 
        : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _buildStatCard(
                context,
                'Total Tasks',
                totalTasks.toString(),
                Icons.assignment,
                AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Completed',
                completedTasks.length.toString(),
                Icons.check_circle,
                AppTheme.completedStatusColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Pending',
                pendingTasks.length.toString(),
                Icons.pending_actions,
                AppTheme.pendingStatusColor,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Overdue',
                overdueTasks.length.toString(),
                Icons.warning_amber,
                AppTheme.overdueStatusColor,
              ),
            ],
          ),
          
          // Completion rate
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion Rate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: _buildCompletionRateChart(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$completionRate%',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'of tasks completed',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Task completion by day
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks Completed by Day',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _buildCompletionByDayChart(context),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Priority distribution
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Priority Distribution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _buildPriorityDistributionChart(context),
                  ),
                  const SizedBox(height: 16),
                  _buildPriorityLegend(context),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tags distribution
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Tags Distribution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildTagsDistributionChart(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionRateChart(BuildContext context) {
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 25,
        sections: [
          PieChartSectionData(
            value: completedTasks.length.toDouble(),
            color: AppTheme.completedStatusColor,
            radius: 25,
            title: '', // No title in the chart
            showTitle: false,
          ),
          PieChartSectionData(
            value: pendingTasks.length.toDouble(),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
            radius: 25,
            title: '', // No title in the chart
            showTitle: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionByDayChart(BuildContext context) {
    // Prepare data for the last n days
    final today = DateTime.now();
    final dates = List.generate(daysToShow, (index) {
      final day = today.subtract(Duration(days: daysToShow - 1 - index));
      return DateTime(day.year, day.month, day.day);
    });

    // Count completed tasks per day
    final completionData = <DateTime, int>{};
    for (var date in dates) {
      final dayStart = date;
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final completedOnDay = tasks.where((task) => 
        task.isCompleted && 
        task.completedDate != null && 
        task.completedDate!.isAfter(dayStart) && 
        task.completedDate!.isBefore(dayEnd)
      ).length;
      
      completionData[date] = completedOnDay;
    }

    // Create bar chart data
    final barGroups = dates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final count = completionData[date] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: AppTheme.completedStatusColor,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    // Prepare date labels for the x-axis
    final dayLabels = dates.map((date) => DateFormat('E').format(date)).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= dayLabels.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    dayLabels[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(
          show: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
      ),
    );
  }

  Widget _buildPriorityDistributionChart(BuildContext context) {
    // Count tasks by priority
    final lowPriorityCount = tasks.where((task) => task.priority == TaskPriority.low).length;
    final mediumPriorityCount = tasks.where((task) => task.priority == TaskPriority.medium).length;
    final highPriorityCount = tasks.where((task) => task.priority == TaskPriority.high).length;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: lowPriorityCount.toDouble(),
                color: AppTheme.lowPriorityColor,
                width: 40,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: mediumPriorityCount.toDouble(),
                color: AppTheme.mediumPriorityColor,
                width: 40,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: highPriorityCount.toDouble(),
                color: AppTheme.highPriorityColor,
                width: 40,
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final titles = ['Low', 'Medium', 'High'];
                if (value < 0 || value >= titles.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    titles[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(
          show: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
      ),
    );
  }

  Widget _buildPriorityLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, 'Low', AppTheme.lowPriorityColor),
        const SizedBox(width: 24),
        _buildLegendItem(context, 'Medium', AppTheme.mediumPriorityColor),
        const SizedBox(width: 24),
        _buildLegendItem(context, 'High', AppTheme.highPriorityColor),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTagsDistributionChart(BuildContext context) {
    // Extract all tags and count occurrences
    final tagCounts = <String, int>{};
    for (var task in tasks) {
      for (var tag in task.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // Sort tags by count (descending)
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 10 tags only
    final topTags = sortedTags.take(10).toList();

    if (topTags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No tags found'),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topTags.length,
        itemBuilder: (context, index) {
          final tag = topTags[index];
          final percentage = tag.value / tasks.length * 100;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tag.key),
                    Text('${tag.value}'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: tag.value / (tasks.isEmpty ? 1 : tasks.length),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 