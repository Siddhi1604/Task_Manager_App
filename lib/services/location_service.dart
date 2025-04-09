import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/task.dart';
import 'notification_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final NotificationService _notificationService = NotificationService();
  StreamSubscription<Position>? _positionStream;
  List<Task> _locationBasedTasks = [];

  // Initialize and request location permissions
  Future<bool> init() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    // Permissions are granted, initialize location monitoring
    return true;
  }

  // Start monitoring location for proximity alerts
  void startLocationMonitoring(List<Task> locationTasks) {
    // Stop any existing monitoring
    stopLocationMonitoring();

    // Save location-based tasks
    _locationBasedTasks = locationTasks.where((task) => 
      task.latitude != null && 
      task.longitude != null && 
      task.locationRadius != null &&
      !task.isCompleted
    ).toList();

    // If there are no location tasks, don't start monitoring
    if (_locationBasedTasks.isEmpty) return;

    // Start listening to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    ).listen(_checkProximity);
  }

  // Stop location monitoring
  void stopLocationMonitoring() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Check if user is near any location-based tasks
  void _checkProximity(Position position) {
    for (var task in _locationBasedTasks) {
      if (task.latitude == null || task.longitude == null || task.locationRadius == null) {
        continue;
      }

      // Calculate distance between current position and task location
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        task.latitude!,
        task.longitude!,
      );

      // If within radius, send notification
      if (distance <= task.locationRadius! && !task.isCompleted) {
        _notificationService.showNotification(
          id: task.id! + 2000, // Use a different ID range for location notifications
          title: 'You are near a task',
          body: 'Task "${task.title}" is nearby at ${task.locationName}',
          payload: task.id.toString(),
        );
      }
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get coordinates from address
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations[0].latitude,
          'longitude': locations[0].longitude,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }
} 