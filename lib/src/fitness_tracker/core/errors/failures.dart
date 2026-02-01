import 'package:equatable/equatable.dart';

/// Base class for all fitness-related failures
abstract class FitnessFailure extends Equatable {
  final String message;

  const FitnessFailure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure when Google Fit is not available or not installed
class GoogleFitNotAvailableFailure extends FitnessFailure {
  const GoogleFitNotAvailableFailure()
      : super('Google Fit is not available on this device');
}

/// Failure when permissions are not granted
class PermissionDeniedFailure extends FitnessFailure {
  const PermissionDeniedFailure()
      : super('Permission to access fitness data was denied');
}

/// Failure when data cannot be retrieved
class DataRetrievalFailure extends FitnessFailure {
  const DataRetrievalFailure([String? message])
      : super(message ?? 'Failed to retrieve fitness data');
}

/// Failure when data cannot be written
class DataWriteFailure extends FitnessFailure {
  const DataWriteFailure([String? message])
      : super(message ?? 'Failed to write fitness data');
}

