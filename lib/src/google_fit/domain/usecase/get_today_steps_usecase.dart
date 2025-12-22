import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/google_fit/core/errors/failures.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';

/// Use case for getting today's step count
class GetTodayStepsUseCase {
  final GoogleFitRepository repository;

  GetTodayStepsUseCase(this.repository);

  Future<Either<FitnessFailure, int?>> call() async {
    final today = DateTime.now();
    return await repository.getSteps(today);
  }
}

