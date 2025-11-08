import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/auth/core/errors/failures.dart';
import 'package:befit_fitness_app/src/auth/data/datasources/auth_remote_data_source.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository]
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } catch (e) {
      final errorMessage = e.toString();
      
      // Check if it's a cancellation
      if (errorMessage.contains('cancelled') || 
          errorMessage.contains('Sign-in was cancelled')) {
        return const Left(CancellationFailure());
      }
      
      // Check if it's a network error
      if (errorMessage.contains('network') || 
          errorMessage.contains('NetworkError') ||
          errorMessage.contains('SocketException')) {
        return Left(NetworkFailure(errorMessage));
      }
      
      // Default to auth failure
      return Left(AuthFailure(errorMessage));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
