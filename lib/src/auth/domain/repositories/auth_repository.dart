import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart';

import '../../core/errors/failures.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Sign in with Google
  /// Returns either a [Failure] or a [User] entity
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in with email and password
  /// Returns either a [Failure] or a [User] entity
  Future<Either<Failure, User>> signInWithEmailPassword(String email, String password);

  /// Sign up with email and password
  /// Returns either a [Failure] or a [User] entity
  Future<Either<Failure, User>> signUpWithEmailPassword(String email, String password);

  /// Send email verification
  /// Returns either a [Failure] or void
  Future<Either<Failure, void>> sendEmailVerification();

  /// Reset password via email
  /// Returns either a [Failure] or void
  Future<Either<Failure, void>> resetPassword(String email);

  /// Sign out the current user
  /// Returns either a [Failure] or void
  Future<Either<Failure, void>> signOut();

  /// Get the current authenticated user
  /// Returns either a [Failure] or a [User] entity (null if not authenticated)
  Future<Either<Failure, User?>> getCurrentUser();
}
