import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/workout/domain/repositories/exercise_repository.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

/// Load filter options (body parts, targets, equipment)
class LoadExerciseFiltersEvent extends WorkoutEvent {
  const LoadExerciseFiltersEvent();
}

/// Load exercises with optional filters and pagination
class LoadExercisesEvent extends WorkoutEvent {
  final bool reset;
  final String? bodyPart;
  final String? target;
  final String? equipment;
  final String? searchName;
  final String? cursor;

  const LoadExercisesEvent({
    this.reset = true,
    this.bodyPart,
    this.target,
    this.equipment,
    this.searchName,
    this.cursor,
  });

  @override
  List<Object?> get props => [reset, bodyPart, target, equipment, searchName, cursor];
}

/// Update filters and reload (body part, target, equipment - mutually exclusive in UI)
class ApplyFiltersEvent extends WorkoutEvent {
  final String? bodyPart;
  final String? target;
  final String? equipment;

  const ApplyFiltersEvent({
    this.bodyPart,
    this.target,
    this.equipment,
  });

  @override
  List<Object?> get props => [bodyPart, target, equipment];
}

/// Search by name (local filter or API)
class SearchExercisesEvent extends WorkoutEvent {
  final String query;

  const SearchExercisesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Load more (pagination)
class LoadMoreExercisesEvent extends WorkoutEvent {
  const LoadMoreExercisesEvent();
}
