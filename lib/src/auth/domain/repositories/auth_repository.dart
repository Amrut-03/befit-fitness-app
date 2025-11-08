import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart';

import '../../core/errors/failures.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Sign in with Google
  /// Returns either a [Failure] or a [User] entity
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign out the current user
  /// Returns either a [Failure] or void
  Future<Either<Failure, void>> signOut();

  /// Get the current authenticated user
  /// Returns either a [Failure] or a [User] entity (null if not authenticated)
  Future<Either<Failure, User?>> getCurrentUser();
}
