import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/google_fit/core/errors/failures.dart';
import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';

/// Repository interface for Google Fit operations
abstract class GoogleFitRepository {
  /// Check if Google Fit is available
  Future<Either<FitnessFailure, bool>> isAvailable();

  /// Request permissions for Google Fit
  Future<Either<FitnessFailure, bool>> requestPermissions();

  /// Check if permissions are granted
  Future<Either<FitnessFailure, bool>> hasPermissions();

  /// Get steps count for a specific date
  Future<Either<FitnessFailure, int?>> getSteps(DateTime date);

  /// Get steps count for a date range
  Future<Either<FitnessFailure, int>> getStepsInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get distance in meters for a specific date
  Future<Either<FitnessFailure, double?>> getDistance(DateTime date);

  /// Get distance in meters for a date range
  Future<Either<FitnessFailure, double>> getDistanceInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get calories burned for a specific date
  Future<Either<FitnessFailure, double?>> getCalories(DateTime date);

  /// Get calories burned for a date range
  Future<Either<FitnessFailure, double>> getCaloriesInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get heart rate data for a specific date
  Future<Either<FitnessFailure, double?>> getHeartRate(DateTime date);

  /// Get weight data (most recent)
  Future<Either<FitnessFailure, double?>> getWeight();

  /// Get height data (most recent)
  Future<Either<FitnessFailure, double?>> getHeight();

  /// Get comprehensive fitness data for a specific date
  Future<Either<FitnessFailure, FitnessData>> getFitnessDataForDate(
    DateTime date,
  );

  /// Get aggregated fitness data for a date range
  Future<Either<FitnessFailure, AggregatedFitnessData>> getAggregatedData(
    DateTime startDate,
    DateTime endDate,
  );

  /// Write steps data to Google Fit
  Future<Either<FitnessFailure, void>> writeSteps(int steps, DateTime date);

  /// Write heart rate data to Google Fit
  Future<Either<FitnessFailure, void>> writeHeartRate(
    double heartRate,
    DateTime date,
  );

  /// Write weight data to Google Fit
  Future<Either<FitnessFailure, void>> writeWeight(
    double weight,
    DateTime date,
  );
}

