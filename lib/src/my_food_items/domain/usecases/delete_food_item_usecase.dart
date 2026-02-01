import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/core/usecase/usecase.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/repositories/food_items_repository.dart';

/// Parameters for delete food item use case
class DeleteFoodItemParams {
  final String docId;
  final String type;

  const DeleteFoodItemParams({
    required this.docId,
    required this.type,
  });
}

/// Use case for deleting a food item
class DeleteFoodItemUseCase extends UseCase<void, DeleteFoodItemParams> {
  final FoodItemsRepository repository;

  DeleteFoodItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteFoodItemParams params) {
    return repository.deleteFoodItem(params.docId, params.type);
  }
}
