import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const androidNotificationChannel = AndroidNotificationChannel(
    'task_reminders_channel',
    'Task Reminders',
    description: 'This channel is used for task reminder notifications',
    importance: Importance.high,
  );

  Future<void> init() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Create notification channel for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  // Request notification permissions
  Future<void> requestPermissions() async {
    try {
      // Request iOS permissions
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      // Request Android permissions for API level 33+ (Android 13+)
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        // Check if the requestPermission method is available (Flutter Local Notifications 9.1.0+)
        try {
          final arePermissionsGranted = await androidImplementation.areNotificationsEnabled();
          if (arePermissionsGranted == false) {
            await androidImplementation.requestNotificationsPermission();
          }
        } catch (e) {
          print('Error requesting Android notification permissions: $e');
          // Fallback - for older versions we don't need to do anything
          // as permissions are requested at install time
        }
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  // Display an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'This channel is used for task reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Schedule a notification for a task
  Future<void> scheduleTaskNotification(Task task) async {
    if (task.id == null) return;

    // Cancel any existing notifications for this task
    await cancelNotification(task.id!);

    // Create task due time
    final scheduledDate = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.dueTime.hour,
      task.dueTime.minute,
    );

    // Don't schedule if the time is in the past
    if (scheduledDate.isBefore(DateTime.now())) return;

    // Schedule notification 30 minutes before due time
    final reminderTime = scheduledDate.subtract(const Duration(minutes: 30));
    
    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id!,
      'Task Reminder: ${task.title}',
      'This task is due in 30 minutes',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders_channel',
          'Task Reminders',
          channelDescription: 'This channel is used for task reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id.toString(),
    );

    // Also schedule at exact due time
    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id! + 1000, // Use different ID to avoid conflict
      'Task Due: ${task.title}',
      'This task is due now',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders_channel',
          'Task Reminders',
          channelDescription: 'This channel is used for task reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id.toString(),
    );
  }

  // Cancel a notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    await flutterLocalNotificationsPlugin.cancel(id + 1000); // Cancel the due time notification too
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // iOS-specific notification callback
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    // Handle iOS notification when app is in foreground
  }

  // Handle notification tap
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    final String payload = response.payload ?? '';
    if (payload.isNotEmpty) {
      // Navigate to task details page using the payload as task ID
      // This would typically be handled through a callback or event bus
    }
  }
} 