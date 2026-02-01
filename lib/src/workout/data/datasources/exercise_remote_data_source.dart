import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise_response.dart';

/// Abstraction for remote exercise data (DIP: domain/data boundary)
/// Implementations can be ExerciseDB API, mock, etc.
abstract class ExerciseRemoteDataSource {
  Future<ExerciseResponse> getExercises({
    int? limit,
    String? cursor,
    String? bodyPart,
    String? target,
    String? equipment,
    String? name,
  });

  Future<List<Exercise>> getAllExercisesAllPages({int limitPerPage = 50});

  Future<List<String>> getBodyPartList();

  Future<List<String>> getTargetList();

  Future<List<String>> getEquipmentList();

  Future<Exercise?> getExerciseById(String id);
}
