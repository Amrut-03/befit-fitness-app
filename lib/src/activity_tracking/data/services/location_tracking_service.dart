import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:befit_fitness_app/src/activity_tracking/domain/models/activity_tracking_data.dart';

/// Service for tracking location during activities
class LocationTrackingService {
  StreamSubscription<Position>? _positionStream;
  final List<LocationPoint> _pathPoints = [];
  DateTime? _startTime;
  Position? _lastPosition;
  double _totalDistance = 0.0; // in meters
  double _maxSpeed = 0.0; // in m/s
  final List<double> _speeds = [];

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Start tracking location
  Future<void> startTracking({
    required Function(Position) onLocationUpdate,
    required Function(String) onError,
  }) async {
    try {
      // Check permissions
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        onError('Location permission denied. Please grant location permission in settings.');
        return;
      }

      // Check if location services are enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        onError('Location services are disabled. Please enable location services.');
        return;
      }

      // Reset tracking data
      _pathPoints.clear();
      _totalDistance = 0.0;
      _maxSpeed = 0.0;
      _speeds.clear();
      _startTime = DateTime.now();
      _lastPosition = null;

      // Get initial position
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _lastPosition = initialPosition;
        _pathPoints.add(LocationPoint(initialPosition.latitude, initialPosition.longitude));
        onLocationUpdate(initialPosition);
      } catch (e) {
        // Continue with stream even if initial position fails
      }

      // Start listening to position updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen(
        (Position position) {
          _lastPosition = position;
          final locationPoint = LocationPoint(position.latitude, position.longitude);
          _pathPoints.add(locationPoint);

          // Calculate distance from last position
          if (_pathPoints.length > 1) {
            final previousPoint = _pathPoints[_pathPoints.length - 2];
            final distance = _calculateDistance(
              previousPoint.latitude,
              previousPoint.longitude,
              locationPoint.latitude,
              locationPoint.longitude,
            );
            _totalDistance += distance;
          }

          // Track speed
          if (position.speed > 0) {
            _speeds.add(position.speed);
            if (position.speed > _maxSpeed) {
              _maxSpeed = position.speed;
            }
          }

          onLocationUpdate(position);
        },
        onError: (error) {
          onError('Location tracking error: $error');
        },
      );
    } catch (e) {
      onError('Failed to start tracking: $e');
    }
  }

  /// Stop tracking location
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Get current tracking data
  ActivityTrackingData? getTrackingData() {
    if (_startTime == null || _pathPoints.isEmpty) {
      return null;
    }

    final duration = DateTime.now().difference(_startTime!);
    final averageSpeed = _speeds.isNotEmpty
        ? _speeds.reduce((a, b) => a + b) / _speeds.length
        : 0.0;

    // Calculate calories based on activity type and distance
    // This is a simplified calculation - you can enhance it based on user weight, activity type, etc.
    final calories = _calculateCalories(_totalDistance, duration);

    return ActivityTrackingData(
      distance: _totalDistance,
      duration: duration,
      calories: calories,
      averageSpeed: averageSpeed,
      maxSpeed: _maxSpeed,
      pathPoints: List.from(_pathPoints),
    );
  }

  /// Calculate distance between two points in meters using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate estimated calories burned
  /// This is a simplified calculation - you can enhance it with user weight, activity type, etc.
  double _calculateCalories(double distanceInMeters, Duration duration) {
    // Rough estimation: ~1 calorie per 10 meters for running/walking
    // Adjust based on activity type if needed
    final baseCalories = distanceInMeters / 10;
    
    // Add time-based component (metabolic rate)
    final minutes = duration.inMinutes;
    final timeCalories = minutes * 5; // ~5 calories per minute for moderate activity
    
    return baseCalories + timeCalories;
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}

