import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';

/// Response model for paginated exercise API responses
class ExerciseResponse {
  final List<Exercise> exercises;
  final ExerciseMeta meta;

  ExerciseResponse({
    required this.exercises,
    required this.meta,
  });

  factory ExerciseResponse.fromJson(Map<String, dynamic> json) {
    List<Exercise> exercises = [];
    
    // Handle different response formats
    if (json['data'] != null && json['data'] is List) {
      exercises = (json['data'] as List)
          .map<Exercise>((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['exercises'] != null && json['exercises'] is List) {
      exercises = (json['exercises'] as List)
          .map<Exercise>((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['results'] != null && json['results'] is List) {
      exercises = (json['results'] as List)
          .map<Exercise>((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    ExerciseMeta meta = ExerciseMeta.fromJson(
      json['meta'] is Map<String, dynamic> 
          ? json['meta'] as Map<String, dynamic>
          : <String, dynamic>{},
    );

    return ExerciseResponse(
      exercises: exercises,
      meta: meta,
    );
  }
}

/// Meta information for pagination
class ExerciseMeta {
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? nextCursor;
  final String? previousCursor;

  ExerciseMeta({
    required this.total,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.nextCursor,
    this.previousCursor,
  });

  factory ExerciseMeta.fromJson(Map<String, dynamic> json) {
    return ExerciseMeta(
      total: json['total'] as int? ?? 0,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
      nextCursor: json['nextCursor']?.toString(),
      previousCursor: json['previousCursor']?.toString(),
    );
  }
}
