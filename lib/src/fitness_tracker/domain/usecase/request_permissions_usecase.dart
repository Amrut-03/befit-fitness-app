import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/repositories/google_fit_repository.dart';

/// Use case for requesting Google Fit permissions
class RequestPermissionsUseCase {
  final GoogleFitRepository repository;

  RequestPermissionsUseCase(this.repository);

  Future<Either<Failure, bool>> call() async {
    return await repository.requestPermissions();
  }
}

