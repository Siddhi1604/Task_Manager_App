import 'package:flutter/material.dart';

enum TaskPriority {
  low,
  medium,
  high
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  overdue
}

class Task {
  final int? id;
  String title;
  String description;
  DateTime dueDate;
  TimeOfDay dueTime;
  TaskPriority priority;
  TaskStatus status;
  bool isRecurring;
  String recurrencePattern;
  List<String> tags;
  List<Task> subtasks;
  int? parentTaskId;
  String? locationName;
  double? latitude;
  double? longitude;
  double? locationRadius;
  bool isCompleted;
  DateTime? completedDate;
  DateTime createdAt;
  DateTime? lastModified;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    required this.dueTime,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.isRecurring = false,
    this.recurrencePattern = '',
    this.tags = const [],
    this.subtasks = const [],
    this.parentTaskId,
    this.locationName,
    this.latitude,
    this.longitude,
    this.locationRadius,
    this.isCompleted = false,
    this.completedDate,
    DateTime? createdAt,
    this.lastModified,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Task to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'dueTime': '${dueTime.hour.toString().padLeft(2, '0')}:${dueTime.minute.toString().padLeft(2, '0')}',
      'priority': priority.index,
      'status': status.index,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrencePattern': recurrencePattern,
      'tags': tags.isEmpty ? '' : tags.join(','),
      'parentTaskId': parentTaskId,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'locationRadius': locationRadius,
      'isCompleted': isCompleted ? 1 : 0,
      'completedDate': completedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  // Create a Task from a Map (database row)
  factory Task.fromMap(Map<String, dynamic> map) {
    try {
      // Parse the time string safely
      final timeString = map['dueTime']?.toString() ?? '00:00';
      final timeParts = timeString.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
      
      // Parse tags safely
      final tagsString = map['tags']?.toString() ?? '';
      final tagsList = tagsString.isEmpty 
          ? <String>[] 
          : tagsString.split(',').where((tag) => tag.isNotEmpty).toList();

      return Task(
        id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
        title: map['title']?.toString() ?? 'Untitled',
        description: map['description']?.toString() ?? '',
        dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'].toString()) ?? DateTime.now() : DateTime.now(),
        dueTime: TimeOfDay(hour: hour, minute: minute),
        priority: map['priority'] != null && map['priority'] is int 
            ? TaskPriority.values[map['priority'] as int] 
            : TaskPriority.medium,
        status: map['status'] != null && map['status'] is int 
            ? TaskStatus.values[map['status'] as int] 
            : TaskStatus.pending,
        isRecurring: map['isRecurring'] == 1 || map['isRecurring'] == true,
        recurrencePattern: map['recurrencePattern']?.toString() ?? '',
        tags: tagsList,
        parentTaskId: map['parentTaskId'] is int ? map['parentTaskId'] : null,
        locationName: map['locationName']?.toString(),
        latitude: map['latitude'] is double ? map['latitude'] : null,
        longitude: map['longitude'] is double ? map['longitude'] : null,
        locationRadius: map['locationRadius'] is double ? map['locationRadius'] : null,
        isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
        completedDate: map['completedDate'] != null ? DateTime.tryParse(map['completedDate'].toString()) : null,
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
        lastModified: map['lastModified'] != null ? DateTime.tryParse(map['lastModified'].toString()) : null,
      );
    } catch (e) {
      print('Error parsing task: $e');
      // Return a default task in case of parsing error
      return Task(
        title: 'Error Task',
        dueDate: DateTime.now(),
        dueTime: const TimeOfDay(hour: 12, minute: 0),
      );
    }
  }

  // Create a copy of the task with some properties changed
  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    TaskPriority? priority,
    TaskStatus? status,
    bool? isRecurring,
    String? recurrencePattern,
    List<String>? tags,
    List<Task>? subtasks,
    int? parentTaskId,
    String? locationName,
    double? latitude,
    double? longitude,
    double? locationRadius,
    bool? isCompleted,
    DateTime? completedDate,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      tags: tags ?? List.from(this.tags),
      subtasks: subtasks ?? List.from(this.subtasks),
      parentTaskId: parentTaskId ?? this.parentTaskId,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationRadius: locationRadius ?? this.locationRadius,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
} 