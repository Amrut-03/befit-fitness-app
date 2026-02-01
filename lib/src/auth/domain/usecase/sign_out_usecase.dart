import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/core/usecase/usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';

/// Use case for signing out
class SignOutUseCase extends UseCaseNoParams<void> {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.signOut();
  }
}
