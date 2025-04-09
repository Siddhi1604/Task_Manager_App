import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class CalendarView extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTapTask;

  const CalendarView({
    super.key,
    required this.tasks,
    required this.onTapTask,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<Task>> _tasksMap;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _updateTasksMap();
  }

  @override
  void didUpdateWidget(CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _updateTasksMap();
    }
  }

  void _updateTasksMap() {
    _tasksMap = {};
    for (var task in widget.tasks) {
      final date = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      if (_tasksMap[date] != null) {
        _tasksMap[date]!.add(task);
      } else {
        _tasksMap[date] = [task];
      }
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _tasksMap[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          calendarFormat: _calendarFormat,
          eventLoader: _getTasksForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(
              color: isDark ? Colors.red[200] : Colors.red,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                DateFormat.yMMMMd().format(_selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${_getTasksForDay(_selectedDay).length} tasks',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildTasksList(),
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    final tasksForSelectedDay = _getTasksForDay(_selectedDay);

    if (tasksForSelectedDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasksForSelectedDay.length,
      itemBuilder: (context, index) {
        final task = tasksForSelectedDay[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.getPriorityColor(task.priority.index),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              DateFormat.jm().format(
                DateTime(
                  task.dueDate.year,
                  task.dueDate.month,
                  task.dueDate.day,
                  task.dueTime.hour,
                  task.dueTime.minute,
                ),
              ),
            ),
            trailing: task.isCompleted
                ? const Icon(Icons.check_circle, color: AppTheme.completedStatusColor)
                : Icon(
                    Icons.circle_outlined,
                    color: task.dueDate.isBefore(DateTime.now())
                        ? AppTheme.overdueStatusColor
                        : null,
                  ),
            onTap: () => widget.onTapTask(task),
          ),
        );
      },
    );
  }
} 