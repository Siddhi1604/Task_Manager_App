import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Initialize speech recognition
  Future<bool> init() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
    
    return _isInitialized;
  }

  // Check if speech is available
  bool get isAvailable => _isInitialized;
  
  // Check if currently listening
  bool get isListening => _isListening;

  // Start listening for voice commands
  Future<void> startListening({
    required Function(String) onResult,
    required Function() onComplete,
  }) async {
    if (!_isInitialized) {
      bool initialized = await init();
      if (!initialized) return;
    }

    if (_speech.isListening) {
      await stopListening();
    }

    _isListening = true;
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onResult(result.recognizedWords);
          onComplete();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: false,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  // Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  // Parse voice command into task data
  Task? parseVoiceCommand(String command) {
    if (command.isEmpty) return null;
    
    try {
      // Basic parsing: "Add task [title] for [date/time]"
      command = command.toLowerCase();
      
      // Extract title
      String title = '';
      if (command.contains('add task')) {
        title = command.split('add task')[1].trim();
        
        // Remove date/time part from title if present
        if (title.contains(' for ')) {
          title = title.split(' for ')[0].trim();
        } else if (title.contains(' on ')) {
          title = title.split(' on ')[0].trim();
        } else if (title.contains(' at ')) {
          title = title.split(' at ')[0].trim();
        }
      } else if (command.contains('create task')) {
        title = command.split('create task')[1].trim();
        
        // Remove date/time part from title if present
        if (title.contains(' for ')) {
          title = title.split(' for ')[0].trim();
        } else if (title.contains(' on ')) {
          title = title.split(' on ')[0].trim();
        } else if (title.contains(' at ')) {
          title = title.split(' at ')[0].trim();
        }
      } else {
        // Default to using the entire command as title
        title = command;
      }
      
      // Extract date
      DateTime dueDate = DateTime.now();
      
      // Check for tomorrow
      if (command.contains('tomorrow')) {
        dueDate = DateTime.now().add(const Duration(days: 1));
      } 
      // Check for next week
      else if (command.contains('next week')) {
        dueDate = DateTime.now().add(const Duration(days: 7));
      }
      // Check for date patterns (e.g., "on April 15th")
      else if (command.contains(' on ')) {
        final datePart = command.split(' on ')[1].trim();
        try {
          // Try to parse common date formats
          for (var format in ['MMMM d', 'MMMM d yyyy', 'M/d', 'M/d/yyyy']) {
            try {
              final dateFormat = DateFormat(format);
              dueDate = dateFormat.parse(datePart);
              // If year is not specified, use current year
              if (format == 'MMMM d' || format == 'M/d') {
                dueDate = DateTime(
                  DateTime.now().year,
                  dueDate.month,
                  dueDate.day,
                );
              }
              break;
            } catch (e) {
              // Continue to next format
            }
          }
        } catch (e) {
          // If date parsing fails, use today's date
        }
      }
      
      // Extract time
      TimeOfDay dueTime = TimeOfDay.now();
      
      if (command.contains(' at ')) {
        final timePart = command.split(' at ')[1].trim();
        try {
          // Try to parse time formats
          if (timePart.contains('am') || timePart.contains('pm')) {
            final timeFormat = DateFormat('h:mm a');
            final parsedTime = timeFormat.parse(timePart);
            dueTime = TimeOfDay(
              hour: parsedTime.hour,
              minute: parsedTime.minute,
            );
          } else {
            final timeFormat = DateFormat('HH:mm');
            final parsedTime = timeFormat.parse(timePart);
            dueTime = TimeOfDay(
              hour: parsedTime.hour,
              minute: parsedTime.minute,
            );
          }
        } catch (e) {
          // If time parsing fails, use current time
        }
      }
      
      // Determine priority
      TaskPriority priority = TaskPriority.medium;
      if (command.contains('high priority') || command.contains('important')) {
        priority = TaskPriority.high;
      } else if (command.contains('low priority') || command.contains('not important')) {
        priority = TaskPriority.low;
      }
      
      // Create task
      return Task(
        title: title,
        dueDate: dueDate,
        dueTime: dueTime,
        priority: priority,
      );
    } catch (e) {
      print('Error parsing voice command: $e');
      return null;
    }
  }
} 