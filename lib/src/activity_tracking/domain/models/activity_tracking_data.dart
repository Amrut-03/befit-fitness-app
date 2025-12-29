/// Model for activity tracking data
class ActivityTrackingData {
  final double distance; // in meters
  final Duration duration;
  final double calories;
  final double averageSpeed; // in m/s
  final double maxSpeed; // in m/s
  final List<LocationPoint> pathPoints;

  ActivityTrackingData({
    required this.distance,
    required this.duration,
    required this.calories,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.pathPoints,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    }
    return '${(distance / 1000).toStringAsFixed(2)} km';
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedCalories {
    return calories.toStringAsFixed(0);
  }

  String get formattedAverageSpeed {
    return '${(averageSpeed * 3.6).toStringAsFixed(1)} km/h';
  }
}

/// Simple LocationPoint class for location points
class LocationPoint {
  final double latitude;
  final double longitude;

  LocationPoint(this.latitude, this.longitude);
}

