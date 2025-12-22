import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';

/// Data source interface for Google Fit operations
abstract class GoogleFitDataSource {
  /// Check if Google Fit is available on the device
  Future<bool> isAvailable();

  /// Request necessary permissions for Google Fit
  Future<bool> requestPermissions();

  /// Check if permissions are granted
  Future<bool> hasPermissions();

  /// Get steps count for a specific date
  Future<int?> getSteps(DateTime date);

  /// Get steps count for a date range
  Future<int> getStepsInRange(DateTime startDate, DateTime endDate);

  /// Get distance in meters for a specific date
  Future<double?> getDistance(DateTime date);

  /// Get distance in meters for a date range
  Future<double> getDistanceInRange(DateTime startDate, DateTime endDate);

  /// Get calories burned for a specific date
  Future<double?> getCalories(DateTime date);

  /// Get calories burned for a date range
  Future<double> getCaloriesInRange(DateTime startDate, DateTime endDate);

  /// Get heart rate data for a specific date
  Future<double?> getHeartRate(DateTime date);

  /// Get weight data (most recent)
  Future<double?> getWeight();

  /// Get height data (most recent)
  Future<double?> getHeight();

  /// Get comprehensive fitness data for a specific date
  Future<FitnessData> getFitnessDataForDate(DateTime date);

  /// Get aggregated fitness data for a date range
  Future<AggregatedFitnessData> getAggregatedData(
    DateTime startDate,
    DateTime endDate,
  );

  /// Write steps data to Google Fit
  Future<void> writeSteps(int steps, DateTime date);

  /// Write heart rate data to Google Fit
  Future<void> writeHeartRate(double heartRate, DateTime date);

  /// Write weight data to Google Fit
  Future<void> writeWeight(double weight, DateTime date);
}

