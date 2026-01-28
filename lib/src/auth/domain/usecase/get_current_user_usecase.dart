import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/core/usecase/usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';

/// Use case for getting the current authenticated user
class GetCurrentUserUseCase extends UseCaseNoParams<User?> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, User?>> call() {
    return repository.getCurrentUser();
  }
}
