import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/repositories/google_fit_repository.dart';

/// Use case for writing steps data to Google Fit
class WriteStepsUseCase {
  final GoogleFitRepository repository;

  WriteStepsUseCase(this.repository);

  Future<Either<Failure, void>> call(int steps, DateTime date) async {
    return await repository.writeSteps(steps, date);
  }
}

