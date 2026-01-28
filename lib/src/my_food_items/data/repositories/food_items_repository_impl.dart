import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/my_food_items/data/datasources/food_items_remote_data_source.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/entities/food_item.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/repositories/food_items_repository.dart';

/// Repository implementation for food items
class FoodItemsRepositoryImpl implements FoodItemsRepository {
  final FoodItemsRemoteDataSource remoteDataSource;

  FoodItemsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<FoodItem>>> getFoodItems() async {
    try {
      final foodItems = await remoteDataSource.getFoodItems();
      return Right(foodItems);
    } catch (e) {
      final errorMessage = e.toString();
      
      // Check if it's a network error
      if (errorMessage.contains('network') || 
          errorMessage.contains('NetworkError') ||
          errorMessage.contains('SocketException')) {
        return Left(NetworkFailure(errorMessage));
      }
      
      // Check if it's an authentication error
      if (errorMessage.contains('not authenticated') || 
          errorMessage.contains('permission')) {
        return Left(AuthFailure(errorMessage));
      }
      
      // Default to server failure
      return Left(ServerFailure(errorMessage));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFoodItem(String docId, String type) async {
    try {
      await remoteDataSource.deleteFoodItem(docId, type);
      return const Right(null);
    } catch (e) {
      final errorMessage = e.toString();
      
      // Check if it's a network error
      if (errorMessage.contains('network') || 
          errorMessage.contains('NetworkError') ||
          errorMessage.contains('SocketException')) {
        return Left(NetworkFailure(errorMessage));
      }
      
      // Check if it's an authentication error
      if (errorMessage.contains('not authenticated') || 
          errorMessage.contains('permission')) {
        return Left(AuthFailure(errorMessage));
      }
      
      // Default to server failure
      return Left(ServerFailure(errorMessage));
    }
  }

  @override
  Future<Either<Failure, void>> updateFoodItem(String docId, String type, FoodItem item) async {
    try {
      await remoteDataSource.updateFoodItem(docId, type, item);
      return const Right(null);
    } catch (e) {
      final errorMessage = e.toString();
      
      // Check if it's a network error
      if (errorMessage.contains('network') || 
          errorMessage.contains('NetworkError') ||
          errorMessage.contains('SocketException')) {
        return Left(NetworkFailure(errorMessage));
      }
      
      // Check if it's an authentication error
      if (errorMessage.contains('not authenticated') || 
          errorMessage.contains('permission')) {
        return Left(AuthFailure(errorMessage));
      }
      
      // Default to server failure
      return Left(ServerFailure(errorMessage));
    }
  }

  @override
  Future<Either<Failure, void>> renameFoodItem(String docId, String type, String newName) async {
    try {
      await remoteDataSource.renameFoodItem(docId, type, newName);
      return const Right(null);
    } catch (e) {
      final errorMessage = e.toString();
      
      // Check if it's a network error
      if (errorMessage.contains('network') || 
          errorMessage.contains('NetworkError') ||
          errorMessage.contains('SocketException')) {
        return Left(NetworkFailure(errorMessage));
      }
      
      // Check if it's an authentication error
      if (errorMessage.contains('not authenticated') || 
          errorMessage.contains('permission')) {
        return Left(AuthFailure(errorMessage));
      }
      
      // Default to server failure
      return Left(ServerFailure(errorMessage));
    }
  }
}
