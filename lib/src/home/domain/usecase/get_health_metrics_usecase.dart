import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/home/core/errors/failures.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/repositories/home_repository.dart';

/// Use case for fetching health metrics
class GetHealthMetricsUseCase {
  final HomeRepository repository;

  GetHealthMetricsUseCase(this.repository);

  Future<Either<Failure, HealthMetrics>> call(String email) {
    return repository.getHealthMetrics(email);
  }
}

