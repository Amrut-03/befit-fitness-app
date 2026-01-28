import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/entities/food_item.dart';

/// Repository interface for food items operations
abstract class FoodItemsRepository {
  /// Get all food items for the current user
  Future<Either<Failure, List<FoodItem>>> getFoodItems();

  /// Delete a food item
  Future<Either<Failure, void>> deleteFoodItem(String docId, String type);

  /// Update a food item
  Future<Either<Failure, void>> updateFoodItem(String docId, String type, FoodItem item);

  /// Rename a food item
  Future<Either<Failure, void>> renameFoodItem(String docId, String type, String newName);
}
