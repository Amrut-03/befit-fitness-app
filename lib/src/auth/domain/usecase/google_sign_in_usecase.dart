import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';
import 'package:befit_fitness_app/src/auth/core/errors/failures.dart';

/// Use case for Google Sign-In
class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  /// Execute Google Sign-In
  /// Returns either a [Failure] or a [User] entity
  Future<Either<Failure, User>> call() async {
    return await repository.signInWithGoogle();
  }
}
