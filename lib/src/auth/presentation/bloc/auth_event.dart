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

/// Event to sign in with email and password
class SignInWithEmailPasswordEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailPasswordEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Event to sign up with email and password
class SignUpWithEmailPasswordEvent extends AuthEvent {
  final String email;
  final String password;

  const SignUpWithEmailPasswordEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Event to send email verification
class SendEmailVerificationEvent extends AuthEvent {
  const SendEmailVerificationEvent();
}

/// Event to reset password
class ResetPasswordEvent extends AuthEvent {
  final String email;

  const ResetPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}