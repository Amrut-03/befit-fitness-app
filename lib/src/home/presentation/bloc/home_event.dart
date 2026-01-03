import 'package:equatable/equatable.dart';

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

/// Event to register with Google Fit
class RegisterWithGoogleFitEvent extends HomeEvent {
  const RegisterWithGoogleFitEvent();
}

