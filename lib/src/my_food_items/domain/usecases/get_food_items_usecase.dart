import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/core/usecase/usecase.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/entities/food_item.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/repositories/food_items_repository.dart';

/// Use case for getting all food items
class GetFoodItemsUseCase extends UseCaseNoParams<List<FoodItem>> {
  final FoodItemsRepository repository;

  GetFoodItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FoodItem>>> call() {
    return repository.getFoodItems();
  }
}
