import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';

/// Base class for authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no authentication attempt has been made
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - authentication operation is in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is signed in
class Authenticated extends AuthState {
  final User user;
  final bool? isProfileComplete;
  final UserProfile? mergedProfile;

  const Authenticated(
    this.user, {
    this.isProfileComplete,
    this.mergedProfile,
  });

  @override
  List<Object?> get props => [user, isProfileComplete, mergedProfile];
}

/// Unauthenticated state - user is not signed in
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Error state - authentication operation failed
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
