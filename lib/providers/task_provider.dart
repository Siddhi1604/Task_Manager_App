import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../database/database_helper.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  List<Task> _upcomingTasks = [];
  bool _isLoading = false;
  String? _searchQuery;
  TaskPriority? _priorityFilter;
  List<String>? _tagFilter;
  TaskStatus? _statusFilter;
  bool? _completedFilter;
  final bool isWebMode;
  
  // Constructor
  TaskProvider({this.isWebMode = false});

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  List<Task> get upcomingTasks => _upcomingTasks;
  bool get isLoading => _isLoading;
  String? get searchQuery => _searchQuery;
  TaskPriority? get priorityFilter => _priorityFilter;
  List<String>? get tagFilter => _tagFilter;
  TaskStatus? get statusFilter => _statusFilter;
  bool? get completedFilter => _completedFilter;

  // Initialize by loading all tasks
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isWebMode) {
        await _loadTasksFromPrefs();
        // Apply filters AFTER loading from prefs for web
        _tasks = _applyFilters(_tasks);
      } else {
        _tasks = await _dbHelper.getTasks(
          searchQuery: _searchQuery,
          priority: _priorityFilter,
          status: _statusFilter,
          tags: _tagFilter,
          isCompleted: _completedFilter,
        );
      }
    } catch (e) {
      print('Error loading tasks: $e');
      // Provide empty tasks list on error
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load today's tasks
  Future<void> loadTodayTasks() async {
    try {
      if (isWebMode) {
        // Filter tasks for today from the in-memory list
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        _todayTasks = _tasks.where((task) {
          final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          return taskDate.isAtSameMomentAs(today) && !task.isCompleted;
        }).toList();
      } else {
        _todayTasks = await _dbHelper.getTasksDueToday();
      }
    } catch (e) {
      print('Error loading today tasks: $e');
      _todayTasks = [];
    } finally {
      notifyListeners();
    }
  }

  // Load tasks due this week
  Future<void> loadUpcomingTasks() async {
    try {
      if (isWebMode) {
        // Filter tasks for this week from the in-memory list
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        
        _upcomingTasks = _tasks.where((task) {
          final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          return taskDate.isAfter(weekStart) && 
                 taskDate.isBefore(weekEnd) && 
                 !task.isCompleted;
        }).toList();
      } else {
        _upcomingTasks = await _dbHelper.getTasksDueThisWeek();
      }
    } catch (e) {
      print('Error loading upcoming tasks: $e');
      _upcomingTasks = [];
    } finally {
      notifyListeners();
    }
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isWebMode) {
        // For web, add to the in-memory list and save to SharedPreferences
        final newTask = task.copyWith(
          id: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now()
        );
        _tasks.add(newTask);
        await _saveTasksToPrefs();
      } else {
        // For mobile platforms
        final id = await _dbHelper.insertTask(task);
        if (id <= 0) {
          throw Exception('Failed to insert task: Invalid ID returned');
        }
        print('Task added successfully with ID: $id');
      }
      
      // Refresh task lists
      await loadTasks();
      await loadTodayTasks();
      await loadUpcomingTasks();
    } catch (e) {
      print('Error adding task: $e');
      // Add error handling - could show a message to the user
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Web-specific methods
  Future<void> _loadTasksFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];
      
      // IMPORTANT: Load ALL tasks first, filtering happens in loadTasks for web
      _tasks = tasksJson.map((taskJson) {
        try {
          final map = json.decode(taskJson);
          return Task.fromMap(map);
        } catch (e) {
          print('Error parsing task JSON: $e');
          return null;
        }
      }).whereType<Task>().toList(); // Filter out null tasks
    } catch (e) {
      print('Error loading tasks from preferences: $e');
      _tasks = [];
    }
  }

  Future<void> _saveTasksToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks.map((task) {
        try {
          return json.encode(task.toMap());
        } catch (e) {
          print('Error encoding task: $e');
          return null;
        }
      }).whereType<String>().toList(); // Filter out null entries
      
      final result = await prefs.setStringList('tasks', tasksJson);
      if (!result) {
        print('Warning: SharedPreferences returned false when saving tasks');
      }
    } catch (e) {
      print('Error saving tasks to preferences: $e');
    }
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isWebMode) {
        // For web, update the in-memory list and save to SharedPreferences
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(lastModified: DateTime.now());
          await _saveTasksToPrefs();
        } else {
          throw Exception('Task not found for update: ${task.id}');
        }
      } else {
        // For mobile platforms
        final result = await _dbHelper.updateTask(task);
        if (result <= 0) {
          throw Exception('Failed to update task: ${task.id}');
        }
      }
      
      // Refresh task lists
      await loadTasks();
      await loadTodayTasks();
      await loadUpcomingTasks();
    } catch (e) {
      print('Error updating task: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a task
  Future<void> deleteTask(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isWebMode) {
        // For web, remove from the in-memory list and update SharedPreferences
        _tasks.removeWhere((task) => task.id == id);
        // Also remove any subtasks
        _tasks.removeWhere((task) => task.parentTaskId == id);
        await _saveTasksToPrefs();
      } else {
        // For mobile platforms
        final result = await _dbHelper.deleteTask(id);
        if (result <= 0) {
          print('Warning: No rows affected when deleting task: $id');
        }
      }
      
      // Refresh task lists
      await loadTasks();
      await loadTodayTasks();
      await loadUpcomingTasks();
    } catch (e) {
      print('Error deleting task: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(Task task) async {
    if (task.id == null) {
      print('Error: Cannot toggle completion for task with null ID');
      return;
    }

    _isLoading = true;
    notifyListeners(); // Notify UI that loading has started

    final newCompletedStatus = !task.isCompleted;

    try {
      if (isWebMode) {
        // Update in-memory list for web mode
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final updatedTask = _tasks[index].copyWith(
            isCompleted: newCompletedStatus,
            completedDate: newCompletedStatus ? DateTime.now() : null,
            status: newCompletedStatus 
              ? TaskStatus.completed 
              : (_tasks[index].dueDate.isBefore(DateTime.now()) ? TaskStatus.overdue : TaskStatus.pending),
            lastModified: DateTime.now(),
          );
          _tasks[index] = updatedTask;
          await _saveTasksToPrefs(); // Save the updated list to prefs
        } else {
          print('Warning: Task with ID ${task.id} not found in web mode list for toggling.');
        }
      } else {
        // Update database for mobile platforms
        final result = await _dbHelper.markTaskCompleted(task.id!, newCompletedStatus);
        if (result <= 0) {
          print('Warning: Failed to update task completion status in database for task ID ${task.id}');
        }
      }

      // Refresh all task lists from the source (DB or Prefs)
      // This ensures consistency after the update.
      await loadTasks();
      await loadTodayTasks();
      await loadUpcomingTasks();

    } catch (e) {
      print('Error toggling task completion: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is complete
    }
  }

  // Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    loadTasks(); // Reload tasks, which will apply filters
  }

  // Set priority filter
  void setPriorityFilter(TaskPriority? priority) {
    _priorityFilter = priority;
    loadTasks(); // Reload tasks, which will apply filters
  }

  // Set tag filter
  void setTagFilter(List<String>? tags) {
    _tagFilter = tags;
    loadTasks(); // Reload tasks, which will apply filters
  }

  // Set status filter
  void setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    loadTasks(); // Reload tasks, which will apply filters
  }

  // Set completed filter
  void setCompletedFilter(bool? completed) {
    _completedFilter = completed;
    loadTasks(); // Reload tasks, which will apply filters
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = null;
    _priorityFilter = null;
    _tagFilter = null;
    _statusFilter = null;
    _completedFilter = null;
    loadTasks();
  }

  // Get all unique tags from tasks
  Set<String> getAllTags() {
    Set<String> allTags = {};
    for (var task in _tasks) {
      allTags.addAll(task.tags);
    }
    return allTags;
  }

  // Helper to apply filters to a list of tasks (used primarily for web mode)
  List<Task> _applyFilters(List<Task> tasks) {
    List<Task> filteredTasks = List.from(tasks);

    // Apply search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filteredTasks = filteredTasks.where((task) => 
        task.title.toLowerCase().contains(query) || 
        task.description.toLowerCase().contains(query)
      ).toList();
    }

    // Apply priority filter
    if (_priorityFilter != null) {
      filteredTasks = filteredTasks.where((task) => task.priority == _priorityFilter).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      filteredTasks = filteredTasks.where((task) => task.status == _statusFilter).toList();
    }

    // Apply completed filter
    if (_completedFilter != null) {
      filteredTasks = filteredTasks.where((task) => task.isCompleted == _completedFilter).toList();
    }

    // Apply tag filter
    if (_tagFilter != null && _tagFilter!.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) => 
        task.tags.any((tag) => _tagFilter!.contains(tag))
      ).toList();
    }

    return filteredTasks;
  }
} 