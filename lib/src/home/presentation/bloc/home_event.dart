import 'package:equatable/equatable.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart';

/// Base class for home events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// Event to fetch home data (health metrics and user profile)
class FetchHomeDataEvent extends HomeEvent {
  final String userId;

  const FetchHomeDataEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Event to refresh home data
class RefreshHomeDataEvent extends HomeEvent {
  final String userId;

  const RefreshHomeDataEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Event to fetch fitness data
class FetchFitnessDataEvent extends HomeEvent {
  const FetchFitnessDataEvent();
}

/// Event to fetch weekly fitness data for charts
class FetchWeeklyFitnessDataEvent extends HomeEvent {
  const FetchWeeklyFitnessDataEvent();
}

/// Event to fetch last 15 days fitness data for weight chart
class FetchWeightChartDataEvent extends HomeEvent {
  const FetchWeightChartDataEvent();
}

/// Event to register with Google Fit
class RegisterWithGoogleFitEvent extends HomeEvent {
  const RegisterWithGoogleFitEvent();
}

// Body Chart Events

/// Event to initialize body chart
class InitializeBodyChartEvent extends HomeEvent {
  const InitializeBodyChartEvent();
}

/// Event to toggle muscle selection
class ToggleMuscleEvent extends HomeEvent {
  final Muscle muscle;

  const ToggleMuscleEvent(this.muscle);

  @override
  List<Object> get props => [muscle];
}

/// Event to select multiple muscles
class SelectMultipleMusclesEvent extends HomeEvent {
  final Set<Muscle> muscles;

  const SelectMultipleMusclesEvent(this.muscles);

  @override
  List<Object> get props => [muscles];
}

/// Event to clear all selected muscles
class ClearAllMusclesEvent extends HomeEvent {
  const ClearAllMusclesEvent();
}

/// Event to toggle view (front/back)
class ToggleViewEvent extends HomeEvent {
  const ToggleViewEvent();
}

/// Event to disable/enable muscle
class ToggleMuscleDisabledEvent extends HomeEvent {
  final Muscle muscle;

  const ToggleMuscleDisabledEvent(this.muscle);

  @override
  List<Object> get props => [muscle];
}
