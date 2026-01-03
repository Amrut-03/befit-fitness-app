import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart';

import '../../core/errors/failures.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  Future<Either<Failure, User>> signInWithGoogle();

  Future<Either<Failure, void>> signOut();

  /// Get the current authenticated user
  /// Returns either a [Failure] or a [User] entity (null if not authenticated)
  Future<Either<Failure, User?>> getCurrentUser();
}
