import 'package:equatable/equatable.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/entities/fitness_data.dart';

/// Base class for home states
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading state
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Loaded state with data
class HomeLoaded extends HomeState {
  final HealthMetrics healthMetrics;
  final UserProfile userProfile;
  final FitnessData? fitnessData;
  final List<FitnessData> weeklyFitnessData;
  final bool isFetchingFitnessData;
  final bool isFetchingWeeklyData;
  // Body Chart state
  final Set<Muscle> selectedMuscles;
  final Set<Muscle> disabledMuscles;
  final bool isFrontView;

  const HomeLoaded({
    required this.healthMetrics,
    required this.userProfile,
    this.fitnessData,
    this.weeklyFitnessData = const [],
    this.isFetchingFitnessData = false,
    this.isFetchingWeeklyData = false,
    this.selectedMuscles = const {},
    this.disabledMuscles = const {},
    this.isFrontView = true,
  });

  HomeLoaded copyWith({
    HealthMetrics? healthMetrics,
    UserProfile? userProfile,
    FitnessData? fitnessData,
    List<FitnessData>? weeklyFitnessData,
    bool? isFetchingFitnessData,
    bool? isFetchingWeeklyData,
    Set<Muscle>? selectedMuscles,
    Set<Muscle>? disabledMuscles,
    bool? isFrontView,
  }) {
    return HomeLoaded(
      healthMetrics: healthMetrics ?? this.healthMetrics,
      userProfile: userProfile ?? this.userProfile,
      fitnessData: fitnessData ?? this.fitnessData,
      weeklyFitnessData: weeklyFitnessData ?? this.weeklyFitnessData,
      isFetchingFitnessData: isFetchingFitnessData ?? this.isFetchingFitnessData,
      isFetchingWeeklyData: isFetchingWeeklyData ?? this.isFetchingWeeklyData,
      selectedMuscles: selectedMuscles ?? this.selectedMuscles,
      disabledMuscles: disabledMuscles ?? this.disabledMuscles,
      isFrontView: isFrontView ?? this.isFrontView,
    );
  }

  @override
  List<Object?> get props => [
        healthMetrics,
        userProfile,
        fitnessData,
        weeklyFitnessData,
        isFetchingFitnessData,
        isFetchingWeeklyData,
        selectedMuscles,
        disabledMuscles,
        isFrontView,
      ];
}

/// Error state
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

