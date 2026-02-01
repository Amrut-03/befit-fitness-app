/// Enum for different food measurement units
enum FoodUnit {
  grams('g', 'Grams', false),
  milliliters('ml', 'Milliliters', false),
  pieces('piece', 'Pieces', true),
  cups('cup', 'Cups', false),
  tablespoons('tbsp', 'Tablespoons', false),
  teaspoons('tsp', 'Teaspoons', false),
  customServing('serving', 'Custom Serving', false);

  final String abbreviation;
  final String displayName;
  final bool isCount; // If true, quantity must be whole numbers

  const FoodUnit(this.abbreviation, this.displayName, this.isCount);

  /// Get all available units
  static List<FoodUnit> getAllUnits() => FoodUnit.values;

  /// Get units suitable for liquid foods
  static List<FoodUnit> getLiquidUnits() => [
        milliliters,
        cups,
        tablespoons,
        teaspoons,
        customServing,
      ];

  /// Get units suitable for solid foods
  static List<FoodUnit> getSolidUnits() => [
        grams,
        pieces,
        cups,
        tablespoons,
        teaspoons,
        customServing,
      ];

  /// Get all units (for manual entry where food type is unknown)
  static List<FoodUnit> getAllAvailableUnits() => FoodUnit.values;
}

/// Utility class for converting between different food units
class FoodUnitConverter {
  /// Convert quantity from any unit to grams
  /// servingSize is the base serving size in grams (e.g., 100g)
  static double convertToGrams({
    required double quantity,
    required FoodUnit fromUnit,
    required double? servingSize, // Base serving size in grams
  }) {
    final baseServing = servingSize ?? 100.0;

    switch (fromUnit) {
      case FoodUnit.grams:
        return quantity;
      case FoodUnit.milliliters:
        // For most liquids, 1ml ≈ 1g (water density)
        return quantity;
      case FoodUnit.pieces:
        // For pieces, use the serving size as the weight per piece
        // If servingSize is 100g and user enters 2 pieces, that's 200g
        return quantity * baseServing;
      case FoodUnit.cups:
        // 1 cup ≈ 240ml ≈ 240g (for liquids) or varies for solids
        // For simplicity, we'll use servingSize as reference
        // If servingSize is 100g per cup, then 2 cups = 200g
        return quantity * baseServing;
      case FoodUnit.tablespoons:
        // 1 tbsp ≈ 15ml ≈ 15g
        // Using servingSize as reference: if 1 serving = 100g, then 1 tbsp might be different
        // For simplicity, assume 1 tbsp = servingSize / 6.67 (if serving is 1 cup = 240ml)
        // But we'll use a more direct approach: if servingSize is per cup, then tbsp = servingSize / 16
        return quantity * (baseServing / 16.0); // Approximate: 1 cup = 16 tbsp
      case FoodUnit.teaspoons:
        // 1 tsp ≈ 5ml ≈ 5g
        // Similar to tbsp: 1 cup = 48 tsp
        return quantity * (baseServing / 48.0); // Approximate: 1 cup = 48 tsp
      case FoodUnit.customServing:
        // Custom serving uses the servingSize directly
        // If user enters 1.5 servings and servingSize is 100g, that's 150g
        return quantity * baseServing;
    }
  }

  /// Convert quantity from grams to any unit
  static double convertFromGrams({
    required double grams,
    required FoodUnit toUnit,
    required double? servingSize,
  }) {
    final baseServing = servingSize ?? 100.0;

    switch (toUnit) {
      case FoodUnit.grams:
        return grams;
      case FoodUnit.milliliters:
        // For most liquids, 1ml ≈ 1g
        return grams;
      case FoodUnit.pieces:
        // If servingSize is 100g per piece, then 200g = 2 pieces
        return grams / baseServing;
      case FoodUnit.cups:
        // If servingSize is 100g per cup, then 200g = 2 cups
        return grams / baseServing;
      case FoodUnit.tablespoons:
        // If servingSize is per cup (100g), then tbsp = grams / (servingSize / 16)
        return grams / (baseServing / 16.0);
      case FoodUnit.teaspoons:
        // If servingSize is per cup (100g), then tsp = grams / (servingSize / 48)
        return grams / (baseServing / 48.0);
      case FoodUnit.customServing:
        // If servingSize is 100g per serving, then 200g = 2 servings
        return grams / baseServing;
    }
  }

  /// Validate quantity based on unit type
  /// Returns error message if invalid, null if valid
  static String? validateQuantity(double quantity, FoodUnit unit) {
    if (quantity < 0) {
      return 'Quantity cannot be negative';
    }

    if (unit.isCount) {
      // For count-based units (pieces), quantity must be >= 0.5 to be valid
      // But we'll handle rounding in the UI
      if (quantity < 0.5) {
        return 'Minimum quantity is 0.5 ${unit.displayName.toLowerCase()}';
      }
    } else {
      // For weight/volume units, must be > 0
      if (quantity <= 0) {
        return 'Quantity must be greater than 0';
      }
    }

    return null;
  }

  /// Format quantity for display
  static String formatQuantity(double quantity, FoodUnit unit) {
    if (unit.isCount) {
      // For pieces, show as whole number
      return '${quantity.floor()} ${unit.displayName.toLowerCase()}';
    } else {
      // For other units, show with 1 decimal place if needed
      if (quantity == quantity.floorToDouble()) {
        return '${quantity.toInt()} ${unit.abbreviation}';
      } else {
        return '${quantity.toStringAsFixed(1)} ${unit.abbreviation}';
      }
    }
  }

  /// Handle edge cases for pieces (round down)
  /// 0.5 serving = 0, 1.25 serving = 1
  static double handlePiecesEdgeCase(double quantity) {
    if (quantity < 0.5) {
      return 0.0;
    }
    return quantity.floorToDouble();
  }
}
