import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_remote_data_source.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise_response.dart';
import 'package:befit_fitness_app/src/workout/domain/repositories/exercise_repository.dart';

/// Repository implementation (DIP: depends on abstraction ExerciseRemoteDataSource)
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseRemoteDataSource remoteDataSource;

  ExerciseRepositoryImpl(this.remoteDataSource);

  static Failure _toServerFailure(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 429) {
        return const ServerFailure(
          'Too many requests. Please wait a minute and try again.',
        );
      }
      if (code == 404) {
        return const ServerFailure(
          'Exercises could not be loaded. The service may be temporarily unavailable. Try again later or tap "Load exercises anyway" to retry.',
        );
      }
    }
    return ServerFailure(e.toString());
  }

  @override
  Future<Either<Failure, ExerciseResponse>> getExercises(ExerciseQueryParams params) async {
    try {
      final response = await remoteDataSource.getExercises(
        limit: params.limit,
        cursor: params.cursor,
        bodyPart: params.bodyPart,
        target: params.target,
        equipment: params.equipment,
        name: params.name,
      );
      return Right(response);
    } catch (e) {
      return Left(_toServerFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> getAllExercisesAllPages({int limitPerPage = 50}) async {
    try {
      final list = await remoteDataSource.getAllExercisesAllPages(limitPerPage: limitPerPage);
      return Right(list);
    } catch (e) {
      return Left(_toServerFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBodyPartList() async {
    try {
      final list = await remoteDataSource.getBodyPartList();
      return Right(list);
    } catch (e) {
      return Left(_toServerFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getTargetList() async {
    try {
      final list = await remoteDataSource.getTargetList();
      return Right(list);
    } catch (e) {
      return Left(_toServerFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getEquipmentList() async {
    try {
      final list = await remoteDataSource.getEquipmentList();
      return Right(list);
    } catch (e) {
      return Left(_toServerFailure(e));
    }
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseById(String id) async {
    try {
      final exercise = await remoteDataSource.getExerciseById(id);
      return Right(exercise);
    } catch (e) {
      return Left(_toServerFailure(e));
    }
  }
}
