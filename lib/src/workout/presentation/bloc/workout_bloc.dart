import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:befit_fitness_app/core/utils/logger.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';
import 'package:befit_fitness_app/src/workout/domain/repositories/exercise_repository.dart';
import 'package:befit_fitness_app/src/workout/domain/usecases/get_exercises_usecase.dart';
import 'package:befit_fitness_app/src/workout/domain/usecases/get_exercise_filters_usecase.dart';
import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_event.dart';
import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_state.dart';

/// BLoC for workout/exercise list (DIP: depends on use cases only)
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final GetExercisesUseCase getExercisesUseCase;
  final GetExerciseFiltersUseCase getExerciseFiltersUseCase;

  WorkoutBloc({
    required this.getExercisesUseCase,
    required this.getExerciseFiltersUseCase,
  }) : super(const WorkoutInitial()) {
    on<LoadExerciseFiltersEvent>(_onLoadExerciseFilters);
    on<LoadExercisesEvent>(_onLoadExercises);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<SearchExercisesEvent>(_onSearchExercises);
    on<LoadMoreExercisesEvent>(_onLoadMoreExercises);
  }

  Future<void> _onLoadExerciseFilters(
    LoadExerciseFiltersEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutFiltersLoading());

    final result = await getExerciseFiltersUseCase();

    result.fold(
      (failure) {
        AppLogger.e('WorkoutBloc: Failed to load filters', failure, StackTrace.current);
        emit(WorkoutError(failure.message));
      },
      (filters) {
        emit(WorkoutLoaded(
          exercises: [],
          filteredExercises: [],
          bodyParts: filters.bodyParts,
          targets: filters.targets,
          equipment: filters.equipment,
        ));
      },
    );
  }

  Future<void> _onLoadExercises(
    LoadExercisesEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    final current = state;
    if (current is WorkoutLoaded && current.isLoadingMore) return;

    if (event.reset) {
      if (current is WorkoutLoaded) {
        emit(current.copyWith(isLoading: true, isLoadingMore: false));
      } else {
        emit(const WorkoutLoading());
      }
    }

    final params = ExerciseQueryParams(
      limit: 50,
      cursor: event.cursor,
      bodyPart: event.bodyPart,
      target: event.target,
      equipment: event.equipment,
      name: event.searchName?.isNotEmpty == true ? event.searchName : null,
    );

    final result = await getExercisesUseCase(params);

    result.fold(
      (failure) {
        AppLogger.e('WorkoutBloc: Failed to load exercises', failure, StackTrace.current);
        final current = state;
        if (current is WorkoutLoaded) {
          emit(current.copyWith(isLoadingMore: false));
          emit(WorkoutError(failure.message));
          emit(current);
        } else {
          emit(WorkoutError(failure.message));
        }
      },
      (response) {
        final stateAfterLoad = state;
        if (stateAfterLoad is WorkoutLoaded) {
          final exercises = event.reset
              ? response.exercises
              : [...stateAfterLoad.exercises, ...response.exercises];
          final filtered = _applySearch(exercises, stateAfterLoad.searchQuery);
          emit(stateAfterLoad.copyWith(
            exercises: exercises,
            filteredExercises: filtered,
            selectedBodyPart: event.bodyPart ?? stateAfterLoad.selectedBodyPart,
            selectedTarget: event.target ?? stateAfterLoad.selectedTarget,
            selectedEquipment: event.equipment ?? stateAfterLoad.selectedEquipment,
            nextCursor: response.meta.nextCursor,
            hasNextPage: response.meta.hasNextPage,
            isLoadingMore: false,
            isLoading: false,
          ));
        } else {
          final filtered = _applySearch(response.exercises, '');
          emit(WorkoutLoaded(
            exercises: response.exercises,
            filteredExercises: filtered,
            bodyParts: [],
            targets: [],
            equipment: [],
            selectedBodyPart: event.bodyPart,
            selectedTarget: event.target,
            selectedEquipment: event.equipment,
            nextCursor: response.meta.nextCursor,
            hasNextPage: response.meta.hasNextPage,
            isLoading: false,
          ));
        }
      },
    );
  }

  Future<void> _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutLoaded) return;

    emit(current.copyWith(
      selectedBodyPart: event.bodyPart,
      selectedTarget: event.target,
      selectedEquipment: event.equipment,
    ));

    add(LoadExercisesEvent(
      reset: true,
      bodyPart: event.bodyPart,
      target: event.target,
      equipment: event.equipment,
      searchName: current.searchQuery.isNotEmpty ? current.searchQuery : null,
    ));
  }

  void _onSearchExercises(SearchExercisesEvent event, Emitter<WorkoutState> emit) {
    final current = state;
    if (current is! WorkoutLoaded) return;

    final filtered = _applySearch(current.exercises, event.query);
    emit(current.copyWith(
      searchQuery: event.query,
      filteredExercises: filtered,
    ));
  }

  List<Exercise> _applySearch(List<Exercise> exercises, String query) {
    if (query.isEmpty) return List.from(exercises);
    final lower = query.toLowerCase();
    return exercises.where((e) => e.name.toLowerCase().contains(lower)).toList();
  }

  Future<void> _onLoadMoreExercises(
    LoadMoreExercisesEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutLoaded ||
        !current.hasNextPage ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    add(LoadExercisesEvent(
      reset: false,
      cursor: current.nextCursor,
      bodyPart: current.selectedBodyPart,
      target: current.selectedTarget,
      equipment: current.selectedEquipment,
      searchName: current.searchQuery.isNotEmpty ? current.searchQuery : null,
    ));
  }

  @override
  Future<void> close() {
    AppLogger.d('WorkoutBloc: Closing');
    return super.close();
  }
}
