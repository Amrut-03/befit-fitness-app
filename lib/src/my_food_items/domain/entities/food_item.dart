import 'package:equatable/equatable.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';

/// Food item entity representing a food item in the user's collection
class FoodItem extends Equatable {
  final String docId;
  final String type; // 'manual' or 'scanned'
  final FoodProduct product;

  const FoodItem({
    required this.docId,
    required this.type,
    required this.product,
  });

  @override
  List<Object?> get props => [docId, type, product];
}
