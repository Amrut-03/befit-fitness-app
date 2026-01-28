import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/src/home/domain/models/meal_plan.dart';

/// Service for managing meal plans
class MealPlanService {
  final FirebaseFirestore firestore;

  MealPlanService({required this.firestore});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Get today's date string in YYYY-MM-DD format
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Save or update meal plan for today
  Future<void> saveMealPlan(MealPlan plan) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('mealPlans')
          .doc(plan.date);

      await collection.set(plan.toFirestore());
    } catch (e) {
      throw Exception('Failed to save meal plan: $e');
    }
  }

  /// Get meal plan for a specific date
  Future<MealPlan?> getMealPlan(String date) async {
    try {
      if (_userId.isEmpty) {
        return null;
      }

      final doc = await firestore
          .collection('users')
          .doc(_userId)
          .collection('mealPlans')
          .doc(date)
          .get();

      if (doc.exists) {
        return MealPlan.fromFirestore(date, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get meal plan: $e');
    }
  }

  /// Get today's meal plan
  Future<MealPlan?> getTodayMealPlan() async {
    return getMealPlan(_getTodayDateString());
  }

  /// Delete meal plan for a date
  Future<void> deleteMealPlan(String date) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      await firestore
          .collection('users')
          .doc(_userId)
          .collection('mealPlans')
          .doc(date)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete meal plan: $e');
    }
  }
}
