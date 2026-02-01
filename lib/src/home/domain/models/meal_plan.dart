import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';

/// Model for a scheduled meal item with timing
class ScheduledMeal {
  final String id;
  final FoodProduct product;
  final double quantity; // in the same unit as product's servingUnit
  final String mealTime; // e.g., "08:00", "12:30", "18:00"
  final String mealName; // e.g., "Breakfast", "Lunch", "Dinner", "Snack"
  final int order; // Order for drag and drop

  ScheduledMeal({
    required this.id,
    required this.product,
    required this.quantity,
    required this.mealTime,
    required this.mealName,
    required this.order,
  });

  /// Calculate nutrition based on quantity and serving size
  /// Nutrition values are for the serving size specified (e.g., for 5 pieces)
  /// So we calculate: (nutrition per serving) * (quantity / servingSize)
  double get calculatedCalories {
    final baseCalories = product.nutrition.calories ?? 0.0;
    final servingSize = product.nutrition.servingSize ?? 1.0;
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
      'mealTime': mealTime,
      'mealName': mealName,
      'order': order,
    };
  }

  factory ScheduledMeal.fromFirestore(String id, Map<String, dynamic> data) {
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

    return ScheduledMeal(
      id: id,
      product: product,
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
      mealTime: data['mealTime'] ?? '12:00',
      mealName: data['mealName'] ?? 'Meal',
      order: (data['order'] as int?) ?? 0,
    );
  }

  ScheduledMeal copyWith({
    String? id,
    FoodProduct? product,
    double? quantity,
    String? mealTime,
    String? mealName,
    int? order,
  }) {
    return ScheduledMeal(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      mealTime: mealTime ?? this.mealTime,
      mealName: mealName ?? this.mealName,
      order: order ?? this.order,
    );
  }
}

/// Model for a daily meal plan
class MealPlan {
  final String id;
  final String name;
  final String date; // YYYY-MM-DD
  final List<ScheduledMeal> meals;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlan({
    required this.id,
    required this.name,
    required this.date,
    required this.meals,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'date': date,
      'meals': meals.map((meal) => meal.toFirestore()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealPlan.fromFirestore(String id, Map<String, dynamic> data) {
    final mealsData = data['meals'] as List<dynamic>? ?? [];
    final meals = mealsData.asMap().entries.map((entry) {
      final mealData = entry.value as Map<String, dynamic>;
      mealData['order'] = entry.key; // Add order from index
      return ScheduledMeal.fromFirestore(
        'meal_${entry.key}',
        mealData,
      );
    }).toList();

    return MealPlan(
      id: id,
      name: data['name'] ?? 'Untitled Plan',
      date: data['date'] ?? '',
      meals: meals,
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
