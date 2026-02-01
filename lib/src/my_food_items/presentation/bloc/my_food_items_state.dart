import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/entities/food_item.dart';

/// Base class for my food items states
abstract class MyFoodItemsState extends Equatable {
  const MyFoodItemsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MyFoodItemsInitial extends MyFoodItemsState {
  const MyFoodItemsInitial();
}

/// Loading state
class MyFoodItemsLoading extends MyFoodItemsState {
  const MyFoodItemsLoading();
}

/// Loaded state with food items
class MyFoodItemsLoaded extends MyFoodItemsState {
  final List<FoodItem> foodItems;

  const MyFoodItemsLoaded(this.foodItems);

  @override
  List<Object?> get props => [foodItems];
}

/// Error state
class MyFoodItemsError extends MyFoodItemsState {
  final String message;

  const MyFoodItemsError(this.message);

  @override
  List<Object?> get props => [message];
}
