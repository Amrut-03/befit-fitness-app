import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/core/usecase/usecase.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise_response.dart';
import 'package:befit_fitness_app/src/workout/domain/repositories/exercise_repository.dart';

/// Use case for fetching exercises with filters and pagination (SRP: one use case, one responsibility)
class GetExercisesUseCase extends UseCase<ExerciseResponse, ExerciseQueryParams> {
  final ExerciseRepository repository;

  GetExercisesUseCase(this.repository);

  @override
  Future<Either<Failure, ExerciseResponse>> call(ExerciseQueryParams params) {
    return repository.getExercises(params);
  }
}
