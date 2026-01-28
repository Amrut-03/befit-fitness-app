import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise_response.dart';

/// Parameters for querying exercises (pagination + optional filters)
class ExerciseQueryParams {
  final int? limit;
  final String? cursor;
  final String? bodyPart;
  final String? target;
  final String? equipment;
  final String? name;

  const ExerciseQueryParams({
    this.limit,
    this.cursor,
    this.bodyPart,
    this.target,
    this.equipment,
    this.name,
  });
}

/// Repository interface for exercise data (DIP: depend on abstraction)
abstract class ExerciseRepository {
  /// Fetch exercises with optional filters and pagination
  Future<Either<Failure, ExerciseResponse>> getExercises(ExerciseQueryParams params);

  /// Fetch all exercises across all pages (legacy / bulk load)
  Future<Either<Failure, List<Exercise>>> getAllExercisesAllPages({int limitPerPage = 50});

  /// Get list of body parts for filters
  Future<Either<Failure, List<String>>> getBodyPartList();

  /// Get list of target muscles for filters
  Future<Either<Failure, List<String>>> getTargetList();

  /// Get list of equipment for filters
  Future<Either<Failure, List<String>>> getEquipmentList();

  /// Get a single exercise by ID
  Future<Either<Failure, Exercise?>> getExerciseById(String id);
}
