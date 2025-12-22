import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/google_fit/core/errors/failures.dart';
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_data_source.dart';
import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';

/// Implementation of Google Fit repository
class GoogleFitRepositoryImpl implements GoogleFitRepository {
  final GoogleFitDataSource dataSource;

  GoogleFitRepositoryImpl({required this.dataSource});

  @override
  Future<Either<FitnessFailure, bool>> isAvailable() async {
    try {
      final isAvail = await dataSource.isAvailable();
      return Right(isAvail);
    } catch (e) {
      return const Left(GoogleFitNotAvailableFailure());
    }
  }

  @override
  Future<Either<FitnessFailure, bool>> requestPermissions() async {
    try {
      final granted = await dataSource.requestPermissions();
      if (!granted) {
        return const Left(PermissionDeniedFailure());
      }
      return Right(granted);
    } catch (e) {
      return const Left(PermissionDeniedFailure());
    }
  }

  @override
  Future<Either<FitnessFailure, bool>> hasPermissions() async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      return Right(hasPerms);
    } catch (e) {
      return const Left(PermissionDeniedFailure());
    }
  }

  @override
  Future<Either<FitnessFailure, int?>> getSteps(DateTime date) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final steps = await dataSource.getSteps(date);
      return Right(steps);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, int>> getStepsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final steps = await dataSource.getStepsInRange(startDate, endDate);
      return Right(steps);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, double?>> getDistance(DateTime date) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final distance = await dataSource.getDistance(date);
      return Right(distance);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, double>> getDistanceInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final distance = await dataSource.getDistanceInRange(startDate, endDate);
      return Right(distance);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, double?>> getCalories(DateTime date) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final calories = await dataSource.getCalories(date);
      return Right(calories);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, double>> getCaloriesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final calories = await dataSource.getCaloriesInRange(startDate, endDate);
      return Right(calories);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, double?>> getHeartRate(DateTime date) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final heartRate = await dataSource.getHeartRate(date);
      return Right(heartRate);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, double?>> getWeight() async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final weight = await dataSource.getWeight();
      return Right(weight);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, double?>> getHeight() async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final height = await dataSource.getHeight();
      return Right(height);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, FitnessData>> getFitnessDataForDate(
    DateTime date,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final fitnessData = await dataSource.getFitnessDataForDate(date);
      return Right(fitnessData);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, AggregatedFitnessData>> getAggregatedData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      final aggregatedData =
          await dataSource.getAggregatedData(startDate, endDate);
      return Right(aggregatedData);
    } catch (e) {
      return Left(DataRetrievalFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, void>> writeSteps(
    int steps,
    DateTime date,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      await dataSource.writeSteps(steps, date);
      return const Right(null);
    } catch (e) {
      return Left(DataWriteFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, void>> writeHeartRate(
    double heartRate,
    DateTime date,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      await dataSource.writeHeartRate(heartRate, date);
      return const Right(null);
    } catch (e) {
      return Left(DataWriteFailure(e.toString()));
    }
  }

  @override
  Future<Either<FitnessFailure, void>> writeWeight(
    double weight,
    DateTime date,
  ) async {
    try {
      final hasPerms = await dataSource.hasPermissions();
      if (!hasPerms) {
        return const Left(PermissionDeniedFailure());
      }

      await dataSource.writeWeight(weight, date);
      return const Right(null);
    } catch (e) {
      return Left(DataWriteFailure(e.toString()));
    }
  }
}

