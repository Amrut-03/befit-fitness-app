/// Model for food product with nutritional information
class FoodProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final NutritionInfo nutrition;
  final String? ingredients;
  final String? allergens;
  final String? category;

  FoodProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.nutrition,
    this.ingredients,
    this.allergens,
    this.category,
  });

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final nutriments = product['nutriments'] ?? {};
    
    return FoodProduct(
      barcode: product['code'] ?? json['code'] ?? '',
      name: product['product_name'] ?? product['product_name_en'] ?? 'Unknown Product',
      brand: product['brands'] ?? product['brand'],
      imageUrl: product['image_url'] ?? product['image_front_url'],
      nutrition: NutritionInfo.fromJson(nutriments),
      ingredients: product['ingredients_text'] ?? product['ingredients_text_en'],
      allergens: product['allergens'] ?? product['allergens_tags']?.join(', '),
      category: product['categories'] ?? product['categories_tags']?.first,
    );
  }
}

/// Nutritional information model
class NutritionInfo {
  final double? calories; // kcal
  final double? protein; // g
  final double? carbs; // g
  final double? fat; // g
  final double? fiber; // g
  final double? sugar; // g
  final double? sodium; // mg
  final double? servingSize; // g

  NutritionInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.servingSize,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: _parseDouble(json['energy-kcal_100g'] ?? json['energy-kcal']),
      protein: _parseDouble(json['proteins_100g'] ?? json['proteins']),
      carbs: _parseDouble(json['carbohydrates_100g'] ?? json['carbohydrates']),
      fat: _parseDouble(json['fat_100g'] ?? json['fat']),
      fiber: _parseDouble(json['fiber_100g'] ?? json['fiber']),
      sugar: _parseDouble(json['sugars_100g'] ?? json['sugars']),
      sodium: _parseDouble(json['sodium_100g'] ?? json['sodium']),
      servingSize: _parseDouble(json['serving_size'] ?? 100),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Get formatted nutrition values
  String get formattedCalories => calories != null ? '${calories!.toStringAsFixed(0)} kcal' : 'N/A';
  String get formattedProtein => protein != null ? '${protein!.toStringAsFixed(1)} g' : 'N/A';
  String get formattedCarbs => carbs != null ? '${carbs!.toStringAsFixed(1)} g' : 'N/A';
  String get formattedFat => fat != null ? '${fat!.toStringAsFixed(1)} g' : 'N/A';
  String get formattedFiber => fiber != null ? '${fiber!.toStringAsFixed(1)} g' : 'N/A';
  String get formattedSugar => sugar != null ? '${sugar!.toStringAsFixed(1)} g' : 'N/A';
  String get formattedSodium => sodium != null ? '${sodium!.toStringAsFixed(0)} mg' : 'N/A';
}

