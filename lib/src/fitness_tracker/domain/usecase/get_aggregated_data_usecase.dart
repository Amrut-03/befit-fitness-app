import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/entities/fitness_data.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/repositories/google_fit_repository.dart';

/// Use case for getting aggregated fitness data for a date range
class GetAggregatedDataUseCase {
  final GoogleFitRepository repository;

  GetAggregatedDataUseCase(this.repository);

  Future<Either<Failure, AggregatedFitnessData>> call(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await repository.getAggregatedData(startDate, endDate);
  }
}

