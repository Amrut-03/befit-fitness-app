import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/src/home/domain/models/daily_food_entry.dart';

/// Service for managing daily food entries
class DailyFoodService {
  final FirebaseFirestore firestore;

  DailyFoodService({required this.firestore});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Get today's date string in YYYY-MM-DD format
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Add a food entry for today
  Future<void> addFoodEntry(DailyFoodEntry entry) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final dateString = _getTodayDateString();
      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyFoodEntries')
          .doc(dateString)
          .collection('entries');

      await collection.doc(entry.id).set(entry.toFirestore());
    } catch (e) {
      throw Exception('Failed to add food entry: $e');
    }
  }

  /// Get all food entries for today
  Future<List<DailyFoodEntry>> getTodayFoodEntries() async {
    try {
      if (_userId.isEmpty) {
        return [];
      }

      final dateString = _getTodayDateString();
      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyFoodEntries')
          .doc(dateString)
          .collection('entries');

      final snapshot = await collection.get();
      return snapshot.docs
          .map((doc) => DailyFoodEntry.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get food entries: $e');
    }
  }

  /// Update quantity of a food entry
  Future<void> updateFoodEntryQuantity(String entryId, double quantity) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final dateString = _getTodayDateString();
      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyFoodEntries')
          .doc(dateString)
          .collection('entries');

      await collection.doc(entryId).update({'quantity': quantity});
    } catch (e) {
      throw Exception('Failed to update food entry: $e');
    }
  }

  /// Update alarm/reminder time for a food entry
  Future<void> updateAlarmTime(String entryId, String? alarmTime) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final dateString = _getTodayDateString();
      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyFoodEntries')
          .doc(dateString)
          .collection('entries');

      if (alarmTime == null) {
        await collection.doc(entryId).update({'alarmTime': FieldValue.delete()});
      } else {
        await collection.doc(entryId).update({'alarmTime': alarmTime});
      }
    } catch (e) {
      throw Exception('Failed to update alarm time: $e');
    }
  }

  /// Delete a food entry
  Future<void> deleteFoodEntry(String entryId) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final dateString = _getTodayDateString();
      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyFoodEntries')
          .doc(dateString)
          .collection('entries');

      await collection.doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete food entry: $e');
    }
  }

  /// Get total consumed macros for today
  Future<Map<String, double>> getTodayTotalMacros() async {
    try {
      final entries = await getTodayFoodEntries();
      double totalCalories = 0.0;
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFat = 0.0;

      for (var entry in entries) {
        totalCalories += entry.calculatedCalories;
        totalProtein += entry.calculatedProtein;
        totalCarbs += entry.calculatedCarbs;
        totalFat += entry.calculatedFat;
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      };
    } catch (e) {
      throw Exception('Failed to calculate total macros: $e');
    }
  }

  /// Delete all food entries for today
  Future<void> deleteAllTodayFoodEntries() async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final dateString = _getTodayDateString();
      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyFoodEntries')
          .doc(dateString)
          .collection('entries');

      final snapshot = await collection.get();
      
      // Delete all documents in batch
      final batch = firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all food entries: $e');
    }
  }
}
