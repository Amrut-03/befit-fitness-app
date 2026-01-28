import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/core/usecase/usecase.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';
import 'package:befit_fitness_app/src/workout/domain/repositories/exercise_repository.dart';

/// Use case for fetching a single exercise by ID (SRP)
class GetExerciseByIdUseCase extends UseCase<Exercise?, String> {
  final ExerciseRepository repository;

  GetExerciseByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Exercise?>> call(String id) {
    return repository.getExerciseById(id);
  }
}
