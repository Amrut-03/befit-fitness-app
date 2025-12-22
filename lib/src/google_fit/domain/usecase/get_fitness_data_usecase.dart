import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/google_fit/core/errors/failures.dart';
import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';

/// Use case for getting fitness data for a specific date
class GetFitnessDataUseCase {
  final GoogleFitRepository repository;

  GetFitnessDataUseCase(this.repository);

  Future<Either<FitnessFailure, FitnessData>> call(DateTime date) async {
    return await repository.getFitnessDataForDate(date);
  }
}

