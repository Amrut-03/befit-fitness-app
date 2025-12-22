import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';

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

  const HomeLoaded({
    required this.healthMetrics,
    required this.userProfile,
  });

  @override
  List<Object?> get props => [healthMetrics, userProfile];
}

/// Error state
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

