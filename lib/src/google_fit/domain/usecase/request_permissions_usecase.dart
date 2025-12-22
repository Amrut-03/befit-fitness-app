import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/google_fit/core/errors/failures.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';

/// Use case for requesting Google Fit permissions
class RequestPermissionsUseCase {
  final GoogleFitRepository repository;

  RequestPermissionsUseCase(this.repository);

  Future<Either<FitnessFailure, bool>> call() async {
    return await repository.requestPermissions();
  }
}

