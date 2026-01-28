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

/// Failure for cache-related errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure for cancellation errors (user canceled sign-in)
class CancellationFailure extends Failure {
  const CancellationFailure() : super('Sign-in was cancelled');
}

/// Failure when Google Fit is not available or not installed
class GoogleFitNotAvailableFailure extends Failure {
  const GoogleFitNotAvailableFailure()
      : super('Google Fit is not available on this device');
}

/// Failure when permissions are not granted
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure()
      : super('Permission to access fitness data was denied');
}

/// Failure when data cannot be retrieved
class DataRetrievalFailure extends Failure {
  const DataRetrievalFailure([String? message])
      : super(message ?? 'Failed to retrieve fitness data');
}

/// Failure when data cannot be written
class DataWriteFailure extends Failure {
  const DataWriteFailure([String? message])
      : super(message ?? 'Failed to write fitness data');
}
