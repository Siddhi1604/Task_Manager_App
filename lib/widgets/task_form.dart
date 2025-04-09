import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class TaskForm extends StatefulWidget {
  final Task? task;
  final Function(Task) onSubmit;
  final List<String> availableTags;

  const TaskForm({
    super.key,
    this.task,
    required this.onSubmit,
    this.availableTags = const [],
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();
  final _subtaskController = TextEditingController();
  final LocationService _locationService = LocationService();

  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  bool _isRecurring = false;
  String _recurrencePattern = '';
  List<String> _tags = [];
  List<Task> _subtasks = [];
  String? _locationName;
  double? _latitude;
  double? _longitude;
  double _locationRadius = 100.0; // Default radius: 100 meters

  @override
  void initState() {
    super.initState();
    
    if (widget.task != null) {
      // Editing existing task
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _dueTime = widget.task!.dueTime;
      _priority = widget.task!.priority;
      _isRecurring = widget.task!.isRecurring;
      _recurrencePattern = widget.task!.recurrencePattern;
      _tags = List.from(widget.task!.tags);
      _subtasks = List.from(widget.task!.subtasks);
      _locationName = widget.task!.locationName;
      _locationController.text = widget.task!.locationName ?? '';
      _latitude = widget.task!.latitude;
      _longitude = widget.task!.longitude;
      _locationRadius = widget.task!.locationRadius ?? 100.0;
    } else {
      // Creating new task
      final now = DateTime.now();
      _dueDate = DateTime(now.year, now.month, now.day);
      
      // Set due time to next hour
      final nextHour = (now.hour + 1) % 24;
      _dueTime = TimeOfDay(hour: nextHour, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null && picked != _dueTime) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _subtasks.add(
          Task(
            title: title,
            dueDate: _dueDate,
            dueTime: _dueTime,
            priority: _priority,
            parentTaskId: widget.task?.id,
          ),
        );
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationName = address;
          _locationController.text = address ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  Future<void> _searchLocation() async {
    final address = _locationController.text.trim();
    if (address.isNotEmpty) {
      try {
        final coordinates = await _locationService.getCoordinatesFromAddress(address);
        if (coordinates != null) {
          setState(() {
            _latitude = coordinates['latitude'];
            _longitude = coordinates['longitude'];
            _locationName = address;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error searching location')),
        );
      }
    }
  }

  void _clearLocation() {
    setState(() {
      _locationName = null;
      _latitude = null;
      _longitude = null;
      _locationController.clear();
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        dueTime: _dueTime,
        priority: _priority,
        isRecurring: _isRecurring,
        recurrencePattern: _recurrencePattern,
        tags: _tags,
        subtasks: _subtasks,
        parentTaskId: widget.task?.parentTaskId,
        locationName: _locationName,
        latitude: _latitude,
        longitude: _longitude,
        locationRadius: _locationRadius,
        isCompleted: widget.task?.isCompleted ?? false,
        completedDate: widget.task?.completedDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        lastModified: DateTime.now(),
      );
      
      widget.onSubmit(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date and time pickers
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat.yMMMd().format(_dueDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _dueTime.format(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Priority selection
                  Text(
                    'Priority',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TaskPriority>(
                    segments: const [
                      ButtonSegment(
                        value: TaskPriority.low,
                        label: Text('Low'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: TaskPriority.medium,
                        label: Text('Medium'),
                        icon: Icon(Icons.horizontal_rule),
                      ),
                      ButtonSegment(
                        value: TaskPriority.high,
                        label: Text('High'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (Set<TaskPriority> selection) {
                      setState(() {
                        _priority = selection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.getPriorityColor(_priority.index);
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recurring task options
                  SwitchListTile(
                    title: const Text('Recurring Task'),
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                        if (!value) {
                          _recurrencePattern = '';
                        }
                      });
                    },
                  ),
                  
                  if (_isRecurring)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Repeat',
                          border: OutlineInputBorder(),
                        ),
                        value: _recurrencePattern.isNotEmpty ? _recurrencePattern : 'daily',
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                          DropdownMenuItem(
                            value: 'yearly',
                            child: Text('Yearly'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _recurrencePattern = value;
                            });
                          }
                        },
                      ),
                    ),
                  
                  // Tags
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            labelText: 'Add Tag',
                            hintText: 'Enter tag name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTag,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  
                  if (widget.availableTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: widget.availableTags
                            .where((tag) => !_tags.contains(tag))
                            .map((tag) => ActionChip(
                                  label: Text(tag),
                                  onPressed: () {
                                    setState(() {
                                      _tags.add(tag);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    
                  if (_tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: _tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  onDeleted: () => _removeTag(tag),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Location
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'Enter location name or address',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _searchLocation,
                        icon: const Icon(Icons.search),
                      ),
                      IconButton(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                      ),
                      IconButton(
                        onPressed: _clearLocation,
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                  
                  if (_latitude != null && _longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notification radius: ${_locationRadius.toInt()} meters',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            value: _locationRadius,
                            min: 50,
                            max: 500,
                            divisions: 9,
                            label: '${_locationRadius.toInt()} m',
                            onChanged: (value) {
                              setState(() {
                                _locationRadius = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Subtasks
                  Text(
                    'Subtasks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            labelText: 'Add Subtask',
                            hintText: 'Enter subtask title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSubtask,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  
                  if (_subtasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subtasks.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_subtasks[index].title),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeSubtask(index),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 