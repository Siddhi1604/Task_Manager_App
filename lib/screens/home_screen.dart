import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/calendar_view.dart';
import '../widgets/statistics_dashboard.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();
  int _currentIndex = 0;
  final List<String> _tabTitles = ['Today', 'Tasks', 'Calendar', 'Statistics'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Initialize notifications
    _initializeServices();
    
    // Load tasks
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Initialize notification service
    await _notificationService.init();
    await _notificationService.requestPermissions();
    
    // Initialize location service
    await _locationService.init();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  Future<void> _loadTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.loadTasks();
    await taskProvider.loadTodayTasks();
    await taskProvider.loadUpcomingTasks();
    
    // Start location monitoring for location-based tasks
    _locationService.startLocationMonitoring(taskProvider.tasks);
  }

  void _openTaskForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskFormScreen(),
      ),
    ).then((_) => _loadTasks());
  }

  void _openTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id!),
      ),
    ).then((_) => _loadTasks());
  }

  void _toggleTaskCompletion(Task task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.toggleTaskCompletion(task);
  }

  void _handleVoiceTask(Task? task) {
    if (task != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.addTask(task);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" created successfully'),
          action: SnackBarAction(
            label: 'EDIT',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskFormScreen(task: task),
                ),
              ).then((_) => _loadTasks());
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.shouldUseDarkTheme(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today)),
            Tab(icon: Icon(Icons.list)),
            Tab(icon: Icon(Icons.calendar_month)),
            Tab(icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Today's tasks
              _buildTodayTab(taskProvider),
              
              // All tasks
              _buildTasksTab(taskProvider),
              
              // Calendar view
              _buildCalendarTab(taskProvider),
              
              // Statistics
              _buildStatisticsTab(taskProvider),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Voice input button
          VoiceInputButton(
            onTaskRecognized: _handleVoiceTask,
            size: 48,
          ),
          const SizedBox(height: 16),
          // Regular add task button
          FloatingActionButton(
            onPressed: _openTaskForm,
            tooltip: 'Add Task',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab(TaskProvider taskProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskProvider.todayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks for today',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openTaskForm,
              child: const Text('Add a Task'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: taskProvider.todayTasks.length,
      itemBuilder: (context, index) {
        final task = taskProvider.todayTasks[index];
        return TaskListItem(
          task: task,
          onToggleComplete: _toggleTaskCompletion,
          onTap: _openTaskDetail,
          onEdit: (task) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskFormScreen(task: task),
              ),
            ).then((_) => _loadTasks());
          },
          onDelete: (task) => taskProvider.deleteTask(task.id!),
        );
      },
    );
  }

  Widget _buildTasksTab(TaskProvider taskProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskProvider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openTaskForm,
              child: const Text('Add a Task'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search tasks',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
            ),
            onChanged: (value) {
              taskProvider.setSearchQuery(value.isNotEmpty ? value : null);
            },
          ),
        ),
        
        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All',
                selected: taskProvider.statusFilter == null && 
                          taskProvider.priorityFilter == null && 
                          taskProvider.completedFilter == null,
                onSelected: (_) => taskProvider.clearFilters(),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Pending',
                selected: taskProvider.completedFilter == false,
                onSelected: (selected) => taskProvider.setCompletedFilter(
                  selected ? false : null,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Completed',
                selected: taskProvider.completedFilter == true,
                onSelected: (selected) => taskProvider.setCompletedFilter(
                  selected ? true : null,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'High Priority',
                selected: taskProvider.priorityFilter == TaskPriority.high,
                onSelected: (selected) => taskProvider.setPriorityFilter(
                  selected ? TaskPriority.high : null,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Medium Priority',
                selected: taskProvider.priorityFilter == TaskPriority.medium,
                onSelected: (selected) => taskProvider.setPriorityFilter(
                  selected ? TaskPriority.medium : null,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Low Priority',
                selected: taskProvider.priorityFilter == TaskPriority.low,
                onSelected: (selected) => taskProvider.setPriorityFilter(
                  selected ? TaskPriority.low : null,
                ),
              ),
            ],
          ),
        ),
        
        // Task list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: taskProvider.tasks.length,
            itemBuilder: (context, index) {
              final task = taskProvider.tasks[index];
              return TaskListItem(
                task: task,
                onToggleComplete: _toggleTaskCompletion,
                onTap: _openTaskDetail,
                onEdit: (task) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskFormScreen(task: task),
                    ),
                  ).then((_) => _loadTasks());
                },
                onDelete: (task) => taskProvider.deleteTask(task.id!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarTab(TaskProvider taskProvider) {
    return CalendarView(
      tasks: taskProvider.tasks,
      onTapTask: _openTaskDetail,
    );
  }

  Widget _buildStatisticsTab(TaskProvider taskProvider) {
    return StatisticsDashboard(
      tasks: taskProvider.tasks,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
} 