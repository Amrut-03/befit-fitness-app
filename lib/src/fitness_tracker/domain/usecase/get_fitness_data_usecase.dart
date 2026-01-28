import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/entities/fitness_data.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/repositories/google_fit_repository.dart';

/// Use case for getting fitness data for a specific date
class GetFitnessDataUseCase {
  final GoogleFitRepository repository;

  GetFitnessDataUseCase(this.repository);

  Future<Either<Failure, FitnessData>> call(DateTime date) async {
    return await repository.getFitnessDataForDate(date);
  }
}

