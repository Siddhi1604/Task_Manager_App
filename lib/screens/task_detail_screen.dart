import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LocationService _locationService = LocationService();
  Task? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding.instance.addPostFrameCallback to ensure Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTask();
    });
  }

  Future<void> _loadTask() async {
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() {
      _isLoading = true;
    });

    Task? fetchedTask;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    try {
      if (taskProvider.isWebMode) {
        // Web mode: Find the task in the provider's list using singleWhere with try-catch
        try {
          fetchedTask = taskProvider.tasks.singleWhere((t) => t.id == widget.taskId);
        } on StateError {
          // Handle case where task is not found (0 or >1 matches)
          fetchedTask = null;
          print('Task with ID ${widget.taskId} not found or multiple tasks found in provider list.');
        }
      } else {
        // Mobile mode: Fetch from database
        fetchedTask = await _dbHelper.getTask(widget.taskId);
      }
    } catch (e) {
      print("Error loading task details: $e");
      fetchedTask = null; // Ensure fetchedTask is null on error
    }
    
    if (mounted) { // Check again if widget is still mounted after async operation
      setState(() {
        _task = fetchedTask;
        _isLoading = false;
      });
    }
  }

  void _toggleTaskCompletion() {
    if (_task == null) return;
    
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.toggleTaskCompletion(_task!).then((_) {
      _loadTask();
    });
  }

  void _editTask() {
    if (_task == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: _task),
      ),
    ).then((_) {
      _loadTask();
    });
  }

  void _deleteTask() {
    if (_task == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: ConstrainedBox( // Constrain dialog content width
          constraints: const BoxConstraints(maxWidth: 400), 
          child: Text('Are you sure you want to delete "${_task!.title}"?')
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              taskProvider.deleteTask(_task!.id!).then((_) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              });
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_task == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
        ),
        body: const Center(
          child: Text('Task not found'),
        ),
      );
    }

    final dateFormat = DateFormat.yMMMMd();
    final timeFormat = DateFormat.jm();
    
    final formattedDate = dateFormat.format(_task!.dueDate);
    final formattedTime = timeFormat.format(
      DateTime(
        _task!.dueDate.year,
        _task!.dueDate.month,
        _task!.dueDate.day,
        _task!.dueTime.hour,
        _task!.dueTime.minute,
      ),
    );

    final priorityColor = AppTheme.getPriorityColor(_task!.priority.index);
    final statusColor = AppTheme.getStatusColor(_task!.status.index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTask,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: Center( // Center the content
        child: ConstrainedBox( // Constrain the maximum width
          constraints: const BoxConstraints(maxWidth: 450), // Reduced width
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _task!.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          decoration: _task!.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Status information
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _task!.isCompleted
                                  ? Icons.check_circle
                                  : _task!.status == TaskStatus.overdue
                                      ? Icons.warning
                                      : Icons.pending,
                              color: statusColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _task!.isCompleted
                                  ? 'Completed'
                                  : _task!.status.toString().split('.').last,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _task!.priority == TaskPriority.high
                                  ? Icons.arrow_upward
                                  : _task!.priority == TaskPriority.low
                                      ? Icons.arrow_downward
                                      : Icons.remove,
                              color: priorityColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_task!.priority.toString().split('.').last} Priority',
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Due date and time
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Due Date'),
                    subtitle: Text('$formattedDate at $formattedTime'),
                  ),
                ),
                
                // Recurring information if applicable
                if (_task!.isRecurring)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.repeat),
                      title: const Text('Recurring'),
                      subtitle: Text('Repeats ${_task!.recurrencePattern}'),
                    ),
                  ),
                
                // Description
                if (_task!.description.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_task!.description),
                        ],
                      ),
                    ),
                  ),
                
                // Tags
                if (_task!.tags.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tags',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _task!.tags
                                .map((tag) => Chip(label: Text(tag)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Location if available
                if (_task!.locationName != null &&
                    _task!.latitude != null &&
                    _task!.longitude != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_task!.locationName!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coordinates: ${_task!.latitude!.toStringAsFixed(6)}, ${_task!.longitude!.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Reminder radius: ${_task!.locationRadius!.toInt()} meters',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.map),
                              label: const Text('Open in Maps'),
                              onPressed: () {
                                // Implement map opening logic here
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Subtasks
                if (_task!.subtasks.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subtasks',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                            _task!.subtasks.length,
                            (index) {
                              final subtask = _task!.subtasks[index];
                              return CheckboxListTile(
                                value: subtask.isCompleted,
                                onChanged: (value) {
                                  // Update subtask completion status
                                  if (value != null) {
                                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                                    final updatedSubtask = subtask.copyWith(isCompleted: value);
                                    
                                    // Find the parent task in the provider
                                    final parentTaskIndex = taskProvider.tasks.indexWhere((t) => t.id == _task!.id);
                                    if (parentTaskIndex != -1) {
                                      final parentTask = taskProvider.tasks[parentTaskIndex];
                                      // Find the subtask within the parent
                                      final subtaskIndex = parentTask.subtasks.indexWhere((st) => st.id == subtask.id);
                                      if (subtaskIndex != -1) {
                                        // Create a mutable list of subtasks
                                        List<Task> mutableSubtasks = List.from(parentTask.subtasks);
                                        mutableSubtasks[subtaskIndex] = updatedSubtask;
                                        
                                        // Create the updated parent task
                                        final updatedParentTask = parentTask.copyWith(subtasks: mutableSubtasks);
                                        
                                        // Update the task using the provider
                                        taskProvider.updateTask(updatedParentTask).then((_) {
                                          _loadTask(); // Reload parent task to reflect changes
                                        });
                                      }
                                    }
                                  }
                                },
                                title: Text(
                                  subtask.title,
                                  style: TextStyle(
                                    decoration: subtask.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Creation and modification info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created: ${dateFormat.format(_task!.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_task!.lastModified != null)
                          Text(
                            'Last modified: ${dateFormat.format(_task!.lastModified!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (_task!.isCompleted && _task!.completedDate != null)
                          Text(
                            'Completed: ${dateFormat.format(_task!.completedDate!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _toggleTaskCompletion,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              backgroundColor: _task!.isCompleted
                  ? Colors.grey
                  : AppTheme.completedStatusColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _task!.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
} 