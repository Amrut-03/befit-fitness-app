import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// General failure for unexpected errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure for authentication-related errors
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure for network-related errors
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure for cancellation errors (user canceled sign-in)
class CancellationFailure extends Failure {
  const CancellationFailure() : super('Sign-in was cancelled');
}
