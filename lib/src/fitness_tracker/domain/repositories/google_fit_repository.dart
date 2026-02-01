import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/entities/fitness_data.dart';

/// Repository interface for Google Fit operations
abstract class GoogleFitRepository {
  /// Check if Google Fit is available
  Future<Either<Failure, bool>> isAvailable();

  /// Request permissions for Google Fit
  Future<Either<Failure, bool>> requestPermissions();

  /// Check if permissions are granted
  Future<Either<Failure, bool>> hasPermissions();

  /// Get steps count for a specific date
  Future<Either<Failure, int?>> getSteps(DateTime date);

  /// Get steps count for a date range
  Future<Either<Failure, int>> getStepsInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get distance in meters for a specific date
  Future<Either<Failure, double?>> getDistance(DateTime date);

  /// Get distance in meters for a date range
  Future<Either<Failure, double>> getDistanceInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get calories burned for a specific date
  Future<Either<Failure, double?>> getCalories(DateTime date);

  /// Get calories burned for a date range
  Future<Either<Failure, double>> getCaloriesInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get heart rate data for a specific date
  Future<Either<Failure, double?>> getHeartRate(DateTime date);

  /// Get weight data (most recent)
  Future<Either<Failure, double?>> getWeight();

  /// Get height data (most recent)
  Future<Either<Failure, double?>> getHeight();

  /// Get comprehensive fitness data for a specific date
  Future<Either<Failure, FitnessData>> getFitnessDataForDate(
    DateTime date,
  );

  /// Get aggregated fitness data for a date range
  Future<Either<Failure, AggregatedFitnessData>> getAggregatedData(
    DateTime startDate,
    DateTime endDate,
  );

  /// Write steps data to Google Fit
  Future<Either<Failure, void>> writeSteps(int steps, DateTime date);

  /// Write heart rate data to Google Fit
  Future<Either<Failure, void>> writeHeartRate(
    double heartRate,
    DateTime date,
  );

  /// Write weight data to Google Fit
  Future<Either<Failure, void>> writeWeight(
    double weight,
    DateTime date,
  );
}

