import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

class WorkoutLoading extends WorkoutState {
  const WorkoutLoading();
}

class WorkoutFiltersLoading extends WorkoutState {
  const WorkoutFiltersLoading();
}

class WorkoutLoaded extends WorkoutState {
  final List<Exercise> exercises;
  final List<Exercise> filteredExercises;
  final List<String> bodyParts;
  final List<String> targets;
  final List<String> equipment;
  final String? selectedBodyPart;
  final String? selectedTarget;
  final String? selectedEquipment;
  final String searchQuery;
  final String? nextCursor;
  final bool hasNextPage;
  final bool isLoadingMore;
  final bool isLoading;

  const WorkoutLoaded({
    required this.exercises,
    required this.filteredExercises,
    required this.bodyParts,
    required this.targets,
    required this.equipment,
    this.selectedBodyPart,
    this.selectedTarget,
    this.selectedEquipment,
    this.searchQuery = '',
    this.nextCursor,
    this.hasNextPage = false,
    this.isLoadingMore = false,
    this.isLoading = false,
  });

  WorkoutLoaded copyWith({
    List<Exercise>? exercises,
    List<Exercise>? filteredExercises,
    List<String>? bodyParts,
    List<String>? targets,
    List<String>? equipment,
    String? selectedBodyPart,
    String? selectedTarget,
    String? selectedEquipment,
    String? searchQuery,
    String? nextCursor,
    bool? hasNextPage,
    bool? isLoadingMore,
    bool? isLoading,
  }) {
    return WorkoutLoaded(
      exercises: exercises ?? this.exercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      bodyParts: bodyParts ?? this.bodyParts,
      targets: targets ?? this.targets,
      equipment: equipment ?? this.equipment,
      selectedBodyPart: selectedBodyPart ?? this.selectedBodyPart,
      selectedTarget: selectedTarget ?? this.selectedTarget,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      searchQuery: searchQuery ?? this.searchQuery,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        exercises,
        filteredExercises,
        bodyParts,
        targets,
        equipment,
        selectedBodyPart,
        selectedTarget,
        selectedEquipment,
        searchQuery,
        nextCursor,
        hasNextPage,
        isLoadingMore,
        isLoading,
      ];
}

class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
