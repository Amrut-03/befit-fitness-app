import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/home/core/errors/failures.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';

/// Repository interface for home data operations
abstract class HomeRepository {
  /// Fetch health metrics for a user
  Future<Either<Failure, HealthMetrics>> getHealthMetrics(String userId);

  /// Fetch user profile information
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);
}

