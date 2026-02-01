import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to calculate and save user macros based on daily calories and purpose
class MacroCalculationService {
  final FirebaseFirestore firestore;

  MacroCalculationService({required this.firestore});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Macro ratios based on user purpose/goal
  /// Returns a map with 'carbs', 'protein', 'fat' percentages
  Map<String, double> _getMacroRatios(String? purpose) {
    // Normalize purpose string
    final normalizedPurpose = purpose?.toLowerCase().trim() ?? 'general_fitness';

    // Define macro ratios for different goals
    if (normalizedPurpose.contains('weight_loss') || 
        normalizedPurpose.contains('fat_loss') ||
        normalizedPurpose.contains('lose_weight')) {
      // Weight loss: Lower carbs, higher protein, moderate fat
      return {
        'carbs': 0.30,    // 30% carbs
        'protein': 0.35,  // 35% protein
        'fat': 0.35,      // 35% fat
      };
    } else if (normalizedPurpose.contains('muscle_gain') ||
               normalizedPurpose.contains('bulk') ||
               normalizedPurpose.contains('gain_muscle')) {
      // Muscle gain: Moderate carbs, high protein, moderate fat
      return {
        'carbs': 0.35,    // 35% carbs
        'protein': 0.40,  // 40% protein
        'fat': 0.25,      // 25% fat
      };
    } else if (normalizedPurpose.contains('maintain') ||
               normalizedPurpose.contains('maintenance')) {
      // Maintenance: Balanced macros
      return {
        'carbs': 0.40,    // 40% carbs
        'protein': 0.30,  // 30% protein
        'fat': 0.30,      // 30% fat
      };
    } else {
      // General fitness: Balanced macros (default)
      return {
        'carbs': 0.40,    // 40% carbs
        'protein': 0.30,  // 30% protein
        'fat': 0.30,      // 30% fat
      };
    }
  }

  /// Calculate macros from daily calories and purpose
  /// Returns a map with 'carbs', 'protein', 'fat' in grams
  Map<String, double> calculateMacros({
    required double dailyCalories,
    String? purpose,
  }) {
    final ratios = _getMacroRatios(purpose);

    // Calories per gram for each macro
    const caloriesPerGramCarbs = 4.0;
    const caloriesPerGramProtein = 4.0;
    const caloriesPerGramFat = 9.0;

    // Calculate calories for each macro
    final carbsCalories = dailyCalories * ratios['carbs']!;
    final proteinCalories = dailyCalories * ratios['protein']!;
    final fatCalories = dailyCalories * ratios['fat']!;

    // Convert calories to grams
    final carbs = carbsCalories / caloriesPerGramCarbs;
    final protein = proteinCalories / caloriesPerGramProtein;
    final fat = fatCalories / caloriesPerGramFat;

    return {
      'carbs': carbs.roundToDouble(),
      'protein': protein.roundToDouble(),
      'fat': fat.roundToDouble(),
    };
  }

  /// Save macros to Firestore at users/{userId}/profile.macros
  Future<void> saveMacros({
    required String userId,
    required double carbs,
    required double protein,
    required double fat,
  }) async {
    try {
      if (userId.isEmpty) {
        if (kDebugMode) debugPrint('MacroCalculationService: Cannot save macros - userId is empty');
        return;
      }

      final docRef = firestore.collection('users').doc(userId);
      
      // Use dot notation to update nested macros map
      await docRef.set({
        'profile.macros.carbs': carbs,
        'profile.macros.protein': protein,
        'profile.macros.fat': fat,
      }, SetOptions(merge: true));

      if (kDebugMode) debugPrint('MacroCalculationService: Successfully saved macros - Carbs: ${carbs}g, Protein: ${protein}g, Fat: ${fat}g');
    } catch (e) {
      if (kDebugMode) debugPrint('MacroCalculationService: Error saving macros: $e');
      throw Exception('Failed to save macros: ${e.toString()}');
    }
  }

  /// Save calories to profile.calorie
  Future<void> saveCaloriesToProfile({
    required String userId,
    required double calories,
  }) async {
    try {
      if (userId.isEmpty) {
        if (kDebugMode) debugPrint('MacroCalculationService: Cannot save calories - userId is empty');
        return;
      }

      final docRef = firestore.collection('users').doc(userId);
      
      // Save calories to profile.calorie using dot notation
      await docRef.set({
        'profile.calorie': calories,
      }, SetOptions(merge: true));

      if (kDebugMode) debugPrint('MacroCalculationService: Successfully saved calories to profile.calorie: $calories');
    } catch (e) {
      if (kDebugMode) debugPrint('MacroCalculationService: Error saving calories to profile: $e');
      throw Exception('Failed to save calories to profile: ${e.toString()}');
    }
  }

  /// Calculate and save macros in one operation
  /// Also saves calories to profile.calorie
  Future<void> calculateAndSaveMacros({
    required String userId,
    required double dailyCalories,
    String? purpose,
    bool shouldSaveCaloriesToProfile = true,
  }) async {
    try {
      // Save calories to profile.calorie first
      if (shouldSaveCaloriesToProfile) {
        await saveCaloriesToProfile(
          userId: userId,
          calories: dailyCalories,
        );
      }

      final macros = calculateMacros(
        dailyCalories: dailyCalories,
        purpose: purpose,
      );

      await saveMacros(
        userId: userId,
        carbs: macros['carbs']!,
        protein: macros['protein']!,
        fat: macros['fat']!,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('MacroCalculationService: Error calculating and saving macros: $e');
      rethrow;
    }
  }
}

