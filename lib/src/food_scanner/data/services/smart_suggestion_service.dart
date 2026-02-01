import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';

/// Service for generating smart suggestions based on user's profile purpose
class SmartSuggestionService {
  final FirebaseFirestore firestore;
  
  SmartSuggestionService({required this.firestore});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Get user's profile purpose from Firestore
  Future<String?> getUserPurpose() async {
    try {
      if (_userId.isEmpty) {
        return null;
      }

      final userDoc = await firestore.collection('users').doc(_userId).get();
      
      if (!userDoc.exists) {
        return null;
      }

      final data = userDoc.data();
      final profile = data?['profile'] as Map<String, dynamic>? ?? {};
      
      return profile['purpose'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('SmartSuggestionService: Error getting user purpose: $e');
      return null;
    }
  }

  /// Analyze product and generate smart suggestions based on user purpose
  Future<List<String>> generateSuggestions(FoodProduct product) async {
    final suggestions = <String>[];
    
    try {
      final purpose = await getUserPurpose();
      if (purpose == null) {
        return suggestions;
      }

      final nutrition = product.nutrition;
      final ingredients = (product.ingredients ?? '').toLowerCase();
      
      // Analyze based on purpose
      switch (purpose.toLowerCase()) {
        case 'weight_loss':
        case 'fat_loss':
          suggestions.addAll(_getWeightLossSuggestions(nutrition, ingredients));
          break;
        case 'muscle_gain':
        case 'bulk':
          suggestions.addAll(_getMuscleGainSuggestions(nutrition, ingredients));
          break;
        case 'general_fitness':
        case 'maintenance':
          suggestions.addAll(_getGeneralFitnessSuggestions(nutrition, ingredients));
          break;
        default:
          suggestions.addAll(_getGeneralFitnessSuggestions(nutrition, ingredients));
      }

      // Add time-based suggestions
      suggestions.addAll(_getTimeBasedSuggestions(nutrition, ingredients));
      
      // Add ingredient-based suggestions
      suggestions.addAll(_getIngredientBasedSuggestions(ingredients));
      
    } catch (e) {
      if (kDebugMode) debugPrint('SmartSuggestionService: Error generating suggestions: $e');
    }
    
    return suggestions;
  }

  List<String> _getWeightLossSuggestions(NutritionInfo nutrition, String ingredients) {
    final suggestions = <String>[];
    
    // Check calories
    if (nutrition.calories != null && nutrition.calories! < 150) {
      suggestions.add('✅ Great for weight loss - Low calorie option');
    } else if (nutrition.calories != null && nutrition.calories! > 300) {
      suggestions.add('⚠️ High calorie - Consume in moderation for weight loss');
    }
    
    // Check protein
    if (nutrition.protein != null && nutrition.protein! > 15) {
      suggestions.add('💪 High protein - Helps maintain muscle during weight loss');
    }
    
    // Check fiber
    if (nutrition.fiber != null && nutrition.fiber! > 5) {
      suggestions.add('🌾 High fiber - Keeps you full longer');
    }
    
    // Check sugar
    if (nutrition.sugar != null && nutrition.sugar! > 20) {
      suggestions.add('🍬 High sugar - Limit intake for better weight loss results');
    }
    
    // Check ingredients
    if (ingredients.contains('whole grain') || ingredients.contains('wholegrain')) {
      suggestions.add('🌾 Whole grain - Better choice for weight management');
    }
    
    return suggestions;
  }

  List<String> _getMuscleGainSuggestions(NutritionInfo nutrition, String ingredients) {
    final suggestions = <String>[];
    
    // Check protein
    if (nutrition.protein != null && nutrition.protein! > 20) {
      suggestions.add('💪 Excellent protein source - Perfect for muscle building');
    } else if (nutrition.protein != null && nutrition.protein! < 5) {
      suggestions.add('⚠️ Low protein - Pair with a protein source for muscle gain');
    }
    
    // Check calories
    if (nutrition.calories != null && nutrition.calories! > 250) {
      suggestions.add('🔥 High calorie - Great for bulking');
    }
    
    // Check carbs
    if (nutrition.carbs != null && nutrition.carbs! > 30) {
      suggestions.add('⚡ High carbs - Good for post-workout recovery');
    }
    
    // Check ingredients
    if (ingredients.contains('whey') || ingredients.contains('casein')) {
      suggestions.add('🥛 Protein-rich - Ideal for muscle recovery');
    }
    
    return suggestions;
  }

  List<String> _getGeneralFitnessSuggestions(NutritionInfo nutrition, String ingredients) {
    final suggestions = <String>[];
    
    // Balanced nutrition check
    if (nutrition.protein != null && nutrition.protein! > 10 && 
        nutrition.carbs != null && nutrition.carbs! > 15) {
      suggestions.add('⚖️ Balanced nutrition - Good for overall fitness');
    }
    
    // Check fiber
    if (nutrition.fiber != null && nutrition.fiber! > 3) {
      suggestions.add('🌾 Contains fiber - Supports digestive health');
    }
    
    return suggestions;
  }

  List<String> _getTimeBasedSuggestions(NutritionInfo nutrition, String ingredients) {
    final suggestions = <String>[];
    final hour = DateTime.now().hour;
    
    // Breakfast suggestions (6 AM - 10 AM)
    if (hour >= 6 && hour < 10) {
      if (nutrition.carbs != null && nutrition.carbs! > 20) {
        suggestions.add('🌅 Great for breakfast - Provides morning energy');
      }
      if (ingredients.contains('oats') || ingredients.contains('cereal')) {
        suggestions.add('🥣 Perfect breakfast option');
      }
    }
    
    // Post-workout suggestions (any time, but especially after typical workout hours)
    if (hour >= 17 && hour < 21) {
      if (nutrition.protein != null && nutrition.protein! > 15) {
        suggestions.add('🏋️ Ideal post-workout snack - High protein');
      }
      if (nutrition.carbs != null && nutrition.carbs! > 20) {
        suggestions.add('⚡ Good for post-workout recovery');
      }
    }
    
    // Evening suggestions (after 8 PM)
    if (hour >= 20) {
      if (nutrition.calories != null && nutrition.calories! < 200) {
        suggestions.add('🌙 Light option - Good for evening');
      } else if (nutrition.calories != null && nutrition.calories! > 300) {
        suggestions.add('⚠️ High calorie - Consider lighter option for evening');
      }
    }
    
    return suggestions;
  }

  List<String> _getIngredientBasedSuggestions(String ingredients) {
    final suggestions = <String>[];
    
    // Check for healthy ingredients
    final healthyIngredients = [
      'almond', 'walnut', 'chia', 'flax', 'quinoa', 'brown rice',
      'sweet potato', 'avocado', 'spinach', 'kale', 'broccoli'
    ];
    
    for (final ingredient in healthyIngredients) {
      if (ingredients.contains(ingredient)) {
        suggestions.add('✨ Contains $ingredient - Nutrient-dense ingredient');
        break; // Only add one to avoid too many suggestions
      }
    }
    
    // Check for processed ingredients
    if (ingredients.contains('artificial') || ingredients.contains('preservative')) {
      suggestions.add('⚠️ Contains artificial ingredients - Check label');
    }
    
    return suggestions;
  }
}

