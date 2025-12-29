import 'package:equatable/equatable.dart';

/// Base class for home events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// Event to fetch home data (health metrics and user profile)
class FetchHomeDataEvent extends HomeEvent {
  final String email;

  const FetchHomeDataEvent(this.email);

  @override
  List<Object> get props => [email];
}

/// Event to refresh home data
class RefreshHomeDataEvent extends HomeEvent {
  final String email;

  const RefreshHomeDataEvent(this.email);

  @override
  List<Object> get props => [email];
}

/// Event to fetch fitness data
class FetchFitnessDataEvent extends HomeEvent {
  const FetchFitnessDataEvent();
}

/// Event to register with Health Connect
class RegisterWithHealthConnectEvent extends HomeEvent {
  const RegisterWithHealthConnectEvent();
}

