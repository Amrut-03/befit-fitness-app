import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/entities/food_item.dart';

/// Base class for my food items events
abstract class MyFoodItemsEvent extends Equatable {
  const MyFoodItemsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load food items
class LoadFoodItemsEvent extends MyFoodItemsEvent {
  const LoadFoodItemsEvent();
}

/// Event to delete a food item
class DeleteFoodItemEvent extends MyFoodItemsEvent {
  final String docId;
  final String type;

  const DeleteFoodItemEvent({
    required this.docId,
    required this.type,
  });

  @override
  List<Object?> get props => [docId, type];
}

/// Event to update a food item
class UpdateFoodItemEvent extends MyFoodItemsEvent {
  final String docId;
  final String type;
  final FoodItem item;

  const UpdateFoodItemEvent({
    required this.docId,
    required this.type,
    required this.item,
  });

  @override
  List<Object?> get props => [docId, type, item];
}

/// Event to rename a food item
class RenameFoodItemEvent extends MyFoodItemsEvent {
  final String docId;
  final String type;
  final String newName;

  const RenameFoodItemEvent({
    required this.docId,
    required this.type,
    required this.newName,
  });

  @override
  List<Object?> get props => [docId, type, newName];
}

/// Event to refresh food items
class RefreshFoodItemsEvent extends MyFoodItemsEvent {
  const RefreshFoodItemsEvent();
}
