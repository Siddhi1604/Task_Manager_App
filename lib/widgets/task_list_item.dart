import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final Function(Task) onToggleComplete;
  final Function(Task) onTap;
  final Function(Task)? onEdit;
  final Function(Task)? onDelete;
  final bool showSubtasks;
  final bool isSubtask;
  final bool animate;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showSubtasks = true,
    this.isSubtask = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();
    
    final formattedDate = dateFormat.format(task.dueDate);
    final formattedTime = timeFormat.format(
      DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
        task.dueTime.hour,
        task.dueTime.minute,
      ),
    );

    // Check if task is overdue
    final now = DateTime.now();
    final taskDueDateTime = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.dueTime.hour,
      task.dueTime.minute,
    );
    final isOverdue = !task.isCompleted && taskDueDateTime.isBefore(now);

    // Determine task colors based on priority and status
    final Color priorityColor = AppTheme.getPriorityColor(task.priority.index);
    final Color statusColor = isOverdue 
      ? AppTheme.overdueStatusColor 
      : AppTheme.getStatusColor(task.status.index);

    Widget taskItem = Dismissible(
      key: Key('task_${task.id}'),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as complete
          onToggleComplete(task);
          return false;
        } else {
          // Delete
          if (onDelete != null) {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Task'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Text('Are you sure you want to delete "${task.title}"?'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('DELETE'),
                  ),
                ],
              ),
            ) ?? false;
            
            if (confirmed) {
              onDelete!(task);
              return true;
            }
          }
          return false;
        }
      },
      child: Card(
        elevation: isSubtask ? 0 : 2,
        margin: EdgeInsets.only(
          bottom: 8,
          left: isSubtask ? 16 : 0,
          right: 0,
          top: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSubtask
              ? BorderSide(color: priorityColor.withOpacity(0.3), width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => onTap(task),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: task.isCompleted,
                          onChanged: (_) => onToggleComplete(task),
                          shape: const CircleBorder(),
                          activeColor: AppTheme.completedStatusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Task content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with priority indicator
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: isSubtask ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Description if available
                          if (task.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 16.0),
                              child: Text(
                                task.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          
                          // Due date and time
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: isOverdue
                                      ? AppTheme.overdueStatusColor
                                      : Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$formattedDate at $formattedTime',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverdue
                                        ? AppTheme.overdueStatusColor
                                        : Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: isOverdue ? FontWeight.bold : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Tags if available
                          if (task.tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: task.tags
                                    .map((tag) => Chip(
                                          label: Text(
                                            tag,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: EdgeInsets.zero,
                                          labelPadding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: -2),
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Actions
                    if (onEdit != null || onDelete != null)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) {
                            onEdit!(task);
                          } else if (value == 'delete' && onDelete != null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Task'),
                                content: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 400),
                                  child: Text('Are you sure you want to delete "${task.title}"?'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      onDelete!(task);
                                    },
                                    child: const Text('DELETE'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                
                // Subtasks
                if (showSubtasks && task.subtasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 36.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: task.subtasks
                          .map((subtask) => TaskListItem(
                                task: subtask,
                                onToggleComplete: onToggleComplete,
                                onTap: onTap,
                                onEdit: onEdit,
                                onDelete: onDelete,
                                showSubtasks: false, // Prevent infinite nesting
                                isSubtask: true,
                                animate: false,
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply animations if requested
    if (animate) {
      return taskItem
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 300))
          .slideY(
            begin: 0.1,
            end: 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
    }

    return taskItem;
  }
} 