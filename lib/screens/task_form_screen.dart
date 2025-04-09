import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_form.dart';
import '../services/notification_service.dart';

class TaskFormScreen extends StatelessWidget {
  final Task? task;
  
  const TaskFormScreen({
    super.key,
    this.task,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final notificationService = NotificationService();
    
    return TaskForm(
      task: task,
      availableTags: taskProvider.getAllTags().toList(),
      onSubmit: (updatedTask) async {
        if (task == null) {
          // Adding a new task
          await taskProvider.addTask(updatedTask);
          
          // Schedule notification for the task
          await notificationService.scheduleTaskNotification(updatedTask);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task created successfully')),
            );
            Navigator.pop(context);
          }
        } else {
          // Updating existing task
          await taskProvider.updateTask(updatedTask);
          
          // Update notification for the task
          await notificationService.scheduleTaskNotification(updatedTask);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task updated successfully')),
            );
            Navigator.pop(context);
          }
        }
      },
    );
  }
} 