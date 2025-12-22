import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/google_fit/core/errors/failures.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';

/// Use case for writing steps data to Google Fit
class WriteStepsUseCase {
  final GoogleFitRepository repository;

  WriteStepsUseCase(this.repository);

  Future<Either<FitnessFailure, void>> call(int steps, DateTime date) async {
    return await repository.writeSteps(steps, date);
  }
}

