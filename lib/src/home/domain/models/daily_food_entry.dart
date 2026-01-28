import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/home/domain/models/food_unit.dart';

/// Model for a daily food entry with quantity
class DailyFoodEntry {
  final String id;
  final FoodProduct product;
  final double quantity; // in the same unit as product's servingUnit
  final DateTime addedAt;
  final String mealTime; // e.g., "08:00", "12:30", "18:00"
  final String mealName; // e.g., "Breakfast", "Lunch", "Dinner", "Snack"
  final int order; // Order for drag and drop

  DailyFoodEntry({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
    this.mealTime = '12:00',
    this.mealName = 'Meal',
    this.order = 0,
  });

  /// Get the serving unit from product, defaulting to grams
  FoodUnit get servingUnit {
    if (product.nutrition.servingUnit != null) {
      try {
        return FoodUnit.values.firstWhere(
          (unit) => unit.name == product.nutrition.servingUnit,
          orElse: () => FoodUnit.grams,
        );
      } catch (e) {
        return FoodUnit.grams;
      }
    }
    return FoodUnit.grams;
  }

  /// Get display quantity in the original unit
  /// quantity is stored in the same unit as servingUnit (not converted to grams)
  double get displayQuantity {
    return quantity; // Quantity is already in the serving unit
  }

  /// Calculate nutrition based on quantity and serving size
  /// Nutrition values are for the serving size specified (e.g., for 5 pieces)
  /// So we calculate: (nutrition per serving) * (quantity / servingSize)
  double get calculatedCalories {
    final baseCalories = product.nutrition.calories ?? 0.0;
    final servingSize = product.nutrition.servingSize ?? 1.0;
    // If user consumed quantity=3 pieces and servingSize=5 pieces, that's 3/5 of the nutrition
    return (baseCalories * quantity / servingSize);
  }

  double get calculatedProtein {
    final baseProtein = product.nutrition.protein ?? 0.0;
    final servingSize = product.nutrition.servingSize ?? 1.0;
    return (baseProtein * quantity / servingSize);
  }

  double get calculatedCarbs {
    final baseCarbs = product.nutrition.carbs ?? 0.0;
    final servingSize = product.nutrition.servingSize ?? 1.0;
    return (baseCarbs * quantity / servingSize);
  }

  double get calculatedFat {
    final baseFat = product.nutrition.fat ?? 0.0;
    final servingSize = product.nutrition.servingSize ?? 1.0;
    return (baseFat * quantity / servingSize);
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'product': {
        'barcode': product.barcode,
        'name': product.name,
        'brand': product.brand,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'ingredients': product.ingredients,
        'allergens': product.allergens,
        'nutrition': {
          'calories': product.nutrition.calories,
          'protein': product.nutrition.protein,
          'carbs': product.nutrition.carbs,
          'fat': product.nutrition.fat,
          'fiber': product.nutrition.fiber,
          'sugar': product.nutrition.sugar,
          'sodium': product.nutrition.sodium,
          'servingSize': product.nutrition.servingSize,
          'servingUnit': product.nutrition.servingUnit,
        },
      },
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'mealTime': mealTime,
      'mealName': mealName,
      'order': order,
    };
  }

  /// Create from Firestore document
  factory DailyFoodEntry.fromFirestore(String id, Map<String, dynamic> data) {
    final productData = data['product'] as Map<String, dynamic>;
    final nutritionData = productData['nutrition'] as Map<String, dynamic>;
    
    final product = FoodProduct(
      barcode: productData['barcode'] ?? '',
      name: productData['name'] ?? 'Unknown',
      brand: productData['brand'],
      imageUrl: productData['imageUrl'],
      category: productData['category'],
      ingredients: productData['ingredients'],
      allergens: productData['allergens'],
      nutrition: NutritionInfo(
        calories: nutritionData['calories']?.toDouble(),
        protein: nutritionData['protein']?.toDouble(),
        carbs: nutritionData['carbs']?.toDouble(),
        fat: nutritionData['fat']?.toDouble(),
        fiber: nutritionData['fiber']?.toDouble(),
        sugar: nutritionData['sugar']?.toDouble(),
        sodium: nutritionData['sodium']?.toDouble(),
        servingSize: nutritionData['servingSize']?.toDouble(),
        servingUnit: nutritionData['servingUnit'] as String?,
      ),
    );

    return DailyFoodEntry(
      id: id,
      product: product,
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
      addedAt: DateTime.parse(data['addedAt'] ?? DateTime.now().toIso8601String()),
      mealTime: data['mealTime'] as String? ?? '12:00',
      mealName: data['mealName'] as String? ?? 'Meal',
      order: (data['order'] as int?) ?? 0,
    );
  }

  DailyFoodEntry copyWith({
    String? id,
    FoodProduct? product,
    double? quantity,
    DateTime? addedAt,
    String? mealTime,
    String? mealName,
    int? order,
  }) {
    return DailyFoodEntry(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      mealTime: mealTime ?? this.mealTime,
      mealName: mealName ?? this.mealName,
      order: order ?? this.order,
    );
  }
}
