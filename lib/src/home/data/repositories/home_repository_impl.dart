import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/home/core/errors/failures.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';
import 'package:befit_fitness_app/src/home/domain/repositories/home_repository.dart';
import 'package:befit_fitness_app/src/home/data/datasources/home_remote_data_source.dart';

/// Implementation of home repository
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetrics(String userId) async {
    try {
      final healthMetrics = await remoteDataSource.getHealthMetrics(userId);
      return Right(healthMetrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    try {
      final userProfile = await remoteDataSource.getUserProfile(userId);
      return Right(userProfile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

