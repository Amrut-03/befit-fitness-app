import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/home/core/errors/failures.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';
import 'package:befit_fitness_app/src/home/domain/repositories/home_repository.dart';

/// Use case for fetching user profile
class GetUserProfileUseCase {
  final HomeRepository repository;

  GetUserProfileUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(String email) {
    return repository.getUserProfile(email);
  }
}

