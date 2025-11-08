import 'package:equatable/equatable.dart';

/// Base class for authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Event to trigger Google Sign-In
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Event to sign out the current user
class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

/// Event to check the current authentication state
class CheckAuthStateEvent extends AuthEvent {
  const CheckAuthStateEvent();
}
