import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';
import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';

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
  final bool isFetchingFitnessData;

  const HomeLoaded({
    required this.healthMetrics,
    required this.userProfile,
    this.fitnessData,
    this.isFetchingFitnessData = false,
  });

  HomeLoaded copyWith({
    HealthMetrics? healthMetrics,
    UserProfile? userProfile,
    FitnessData? fitnessData,
    bool? isFetchingFitnessData,
  }) {
    return HomeLoaded(
      healthMetrics: healthMetrics ?? this.healthMetrics,
      userProfile: userProfile ?? this.userProfile,
      fitnessData: fitnessData ?? this.fitnessData,
      isFetchingFitnessData: isFetchingFitnessData ?? this.isFetchingFitnessData,
    );
  }

  @override
  List<Object?> get props => [healthMetrics, userProfile, fitnessData, isFetchingFitnessData];
}

/// Error state
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

