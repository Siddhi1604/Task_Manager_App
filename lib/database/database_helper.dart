import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  bool _isInitializing = false;
  final Completer<Database> _initializationCompleter = Completer<Database>();
  
  // Flag to indicate web mode and skip actual database operations
  final bool _isWebMode = kIsWeb;

  Future<Database> get database async {
    // For web, return a dummy database - actual storage will be handled by TaskProvider
    if (_isWebMode) {
      throw UnsupportedError('SQLite database not supported in web mode');
    }
    
    if (_database != null) return _database!;
    
    if (_isInitializing) {
      // Wait for the initialization to complete
      return _initializationCompleter.future;
    }
    
    _isInitializing = true;
    try {
      _database = await _initDatabase();
      _initializationCompleter.complete(_database);
    } catch (e) {
      print('Database initialization error: $e');
      _initializationCompleter.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
    }
    
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      if (_isWebMode) {
        throw UnsupportedError('SQLite database not supported in web mode');
      }
      
      // For mobile platforms
      String path = join(await getDatabasesPath(), 'task_manager.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDb,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  // Create database tables
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        dueTime TEXT NOT NULL,
        priority INTEGER NOT NULL,
        status INTEGER NOT NULL,
        isRecurring INTEGER NOT NULL,
        recurrencePattern TEXT,
        tags TEXT,
        parentTaskId INTEGER,
        locationName TEXT,
        latitude REAL,
        longitude REAL,
        locationRadius REAL,
        isCompleted INTEGER NOT NULL,
        completedDate TEXT,
        createdAt TEXT NOT NULL,
        lastModified TEXT
      )
    ''');
  }

  // CRUD Operations for Tasks - all operations should check for web mode first

  // Create
  Future<int> insertTask(Task task) async {
    if (_isWebMode) return -1; // Skip actual DB operation in web mode
    
    try {
      Database db = await database;
      
      // Start a transaction for better error handling
      return await db.transaction((txn) async {
        // First insert the main task
        final taskId = await txn.insert(
          'tasks',
          task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        if (taskId <= 0) {
          throw Exception('Failed to insert task: Invalid ID returned');
        }
        
        print('Task inserted with ID: $taskId');
        
        // Then handle any subtasks
        if (task.subtasks.isNotEmpty) {
          for (var subtask in task.subtasks) {
            final subtaskWithParent = subtask.copyWith(
              parentTaskId: taskId,
            );
            
            final subtaskId = await txn.insert(
              'tasks',
              subtaskWithParent.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            
            print('Subtask inserted with ID: $subtaskId');
          }
        }
        
        return taskId;
      });
    } catch (e) {
      print('Error in insertTask: $e');
      return -1; // Return -1 to indicate failure
    }
  }

  // Read
  Future<List<Task>> getTasks({
    String? searchQuery,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_isWebMode) return []; // Skip actual DB operation in web mode
    
    Database db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += 'title LIKE ? OR description LIKE ?';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    if (priority != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'priority = ?';
      whereArgs.add(priority.index);
    }

    if (status != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(status.index);
    }

    if (isCompleted != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'isCompleted = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'dueDate >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'dueDate <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (tags != null && tags.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND (';
      else whereClause += '(';
      
      for (int i = 0; i < tags.length; i++) {
        if (i > 0) whereClause += ' OR ';
        whereClause += 'tags LIKE ?';
        whereArgs.add('%${tags[i]}%');
      }
      
      whereClause += ')';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'dueDate ASC, priority DESC',
    );

    // Convert the maps to Task objects and handle subtasks
    final List<Task> tasks = [];
    for (var map in maps) {
      Task task = Task.fromMap(map);
      if (task.parentTaskId == null) {
        // Load subtasks for this parent task
        final subtasks = await getSubtasks(task.id!);
        task = task.copyWith(subtasks: subtasks);
        tasks.add(task);
      }
    }
    
    return tasks;
  }

  // Get tasks due today
  Future<List<Task>> getTasksDueToday() async {
    if (_isWebMode) return []; // Skip actual DB operation in web mode
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return getTasks(
      startDate: today,
      endDate: tomorrow.subtract(const Duration(milliseconds: 1)),
      isCompleted: false,
    );
  }

  // Get tasks due this week
  Future<List<Task>> getTasksDueThisWeek() async {
    if (_isWebMode) return []; // Skip actual DB operation in web mode
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return getTasks(
      startDate: weekStart,
      endDate: weekEnd.subtract(const Duration(milliseconds: 1)),
      isCompleted: false,
    );
  }

  // Update
  Future<int> updateTask(Task task) async {
    if (_isWebMode) return -1; // Skip actual DB operation in web mode
    
    Database db = await database;
    return await db.update(
      'tasks',
      task.copyWith(lastModified: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete
  Future<int> deleteTask(int id) async {
    if (_isWebMode) return -1; // Skip actual DB operation in web mode
    
    try {
      Database db = await database;
      
      // Use a transaction to ensure both operations complete or fail together
      return await db.transaction((txn) async {
        // First delete all subtasks
        final subtasksDeleted = await txn.delete(
          'tasks',
          where: 'parentTaskId = ?',
          whereArgs: [id],
        );
        
        print('Deleted $subtasksDeleted subtasks for task $id');
        
        // Then delete the main task
        final taskDeleted = await txn.delete(
          'tasks',
          where: 'id = ?',
          whereArgs: [id],
        );
        
        if (taskDeleted == 0) {
          print('Warning: No task found with ID $id to delete');
        } else {
          print('Successfully deleted task $id');
        }
        
        return taskDeleted;
      });
    } catch (e) {
      print('Error in deleteTask: $e');
      return -1; // Return -1 to indicate failure
    }
  }

  // Mark task as completed
  Future<int> markTaskCompleted(int id, bool isCompleted) async {
    if (_isWebMode) return -1; // Skip actual DB operation in web mode
    
    Database db = await database;
    return await db.update(
      'tasks',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'completedDate': isCompleted ? DateTime.now().toIso8601String() : null,
        'status': isCompleted ? TaskStatus.completed.index : TaskStatus.pending.index,
        'lastModified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get a single task by ID
  Future<Task?> getTask(int id) async {
    if (_isWebMode) return null; // Skip actual DB operation in web mode
    
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      Task task = Task.fromMap(maps.first);
      
      // Load subtasks if this is a parent task
      if (task.parentTaskId == null) {
        final subtasks = await getSubtasks(task.id!);
        task = task.copyWith(subtasks: subtasks);
      }
      
      return task;
    }
    
    return null;
  }

  // Get subtasks for a parent task
  Future<List<Task>> getSubtasks(int parentTaskId) async {
    if (_isWebMode) return []; // Skip actual DB operation in web mode
    
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'parentTaskId = ?',
      whereArgs: [parentTaskId],
      orderBy: 'createdAt ASC',
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
} 