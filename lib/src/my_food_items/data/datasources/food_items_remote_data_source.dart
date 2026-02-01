import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/entities/food_item.dart';

/// Remote data source for food items
abstract class FoodItemsRemoteDataSource {
  Future<List<FoodItem>> getFoodItems();
  Future<void> deleteFoodItem(String docId, String type);
  Future<void> updateFoodItem(String docId, String type, FoodItem item);
  Future<void> renameFoodItem(String docId, String type, String newName);
}

class FoodItemsRemoteDataSourceImpl implements FoodItemsRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FoodItemsRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  String get _userId => auth.currentUser?.uid ?? '';

  @override
  Future<List<FoodItem>> getFoodItems() async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final List<FoodItem> allItems = [];

      // Load manual food items
      final manualCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('manualFilledFood')
          .collection('foodItems');

      final manualSnapshot = await manualCollection.get();
      for (var doc in manualSnapshot.docs) {
        final data = doc.data();
        final nutritionData = data['nutrition'] as Map<String, dynamic>? ?? {};
        
        final product = FoodProduct(
          barcode: data['barcode'] ?? '',
          name: data['name'] ?? 'Unknown',
          brand: data['brand'],
          imageUrl: data['imageUrl'],
          category: data['category'],
          ingredients: data['ingredients'],
          allergens: data['allergens'],
          nutrition: NutritionInfo(
            calories: nutritionData['calories']?.toDouble(),
            protein: nutritionData['protein']?.toDouble(),
            carbs: nutritionData['carbs']?.toDouble(),
            fat: nutritionData['fat']?.toDouble(),
            fiber: nutritionData['fiber']?.toDouble(),
            sugar: nutritionData['sugar']?.toDouble(),
            sodium: nutritionData['sodium']?.toDouble(),
            servingSize: nutritionData['servingSize']?.toDouble() ?? 100.0,
            servingUnit: nutritionData['servingUnit'] as String?,
          ),
        );

        allItems.add(FoodItem(
          docId: doc.id,
          type: 'manual',
          product: product,
        ));
      }

      // Load barcode scanned food items
      final scannedCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('barcodeScannedFood')
          .collection('foodItems');

      final scannedSnapshot = await scannedCollection.get();
      for (var doc in scannedSnapshot.docs) {
        final data = doc.data();
        final nutritionData = data['nutrition'] as Map<String, dynamic>? ?? {};
        
        final product = FoodProduct(
          barcode: data['barcode'] ?? '',
          name: data['name'] ?? 'Unknown',
          brand: data['brand'],
          imageUrl: data['imageUrl'],
          category: data['category'],
          ingredients: data['ingredients'],
          allergens: data['allergens'],
          nutrition: NutritionInfo(
            calories: nutritionData['calories']?.toDouble(),
            protein: nutritionData['protein']?.toDouble(),
            carbs: nutritionData['carbs']?.toDouble(),
            fat: nutritionData['fat']?.toDouble(),
            fiber: nutritionData['fiber']?.toDouble(),
            sugar: nutritionData['sugar']?.toDouble(),
            sodium: nutritionData['sodium']?.toDouble(),
            servingSize: nutritionData['servingSize']?.toDouble() ?? 100.0,
            servingUnit: nutritionData['servingUnit'] as String?,
          ),
        );

        allItems.add(FoodItem(
          docId: doc.id,
          type: 'scanned',
          product: product,
        ));
      }

      // Sort by name
      allItems.sort((a, b) {
        return a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
      });

      return allItems;
    } catch (e) {
      throw Exception('Failed to get food items: $e');
    }
  }

  @override
  Future<void> deleteFoodItem(String docId, String type) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc(type == 'manual' ? 'manualFilledFood' : 'barcodeScannedFood')
          .collection('foodItems');

      await collection.doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete food item: $e');
    }
  }

  @override
  Future<void> updateFoodItem(String docId, String type, FoodItem item) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc(type == 'manual' ? 'manualFilledFood' : 'barcodeScannedFood')
          .collection('foodItems');

      final productData = {
        'name': item.product.name,
        'barcode': item.product.barcode,
        'brand': item.product.brand,
        'imageUrl': item.product.imageUrl,
        'category': item.product.category,
        'ingredients': item.product.ingredients,
        'allergens': item.product.allergens,
        'nutrition': {
          'calories': item.product.nutrition?.calories,
          'protein': item.product.nutrition?.protein,
          'carbs': item.product.nutrition?.carbs,
          'fat': item.product.nutrition?.fat,
          'fiber': item.product.nutrition?.fiber,
          'sugar': item.product.nutrition?.sugar,
          'sodium': item.product.nutrition?.sodium,
          'servingSize': item.product.nutrition?.servingSize ?? 100.0,
          'servingUnit': item.product.nutrition?.servingUnit,
        },
      };

      await collection.doc(docId).update(productData);
    } catch (e) {
      throw Exception('Failed to update food item: $e');
    }
  }

  @override
  Future<void> renameFoodItem(String docId, String type, String newName) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final collection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc(type == 'manual' ? 'manualFilledFood' : 'barcodeScannedFood')
          .collection('foodItems');

      await collection.doc(docId).update({'name': newName});
    } catch (e) {
      throw Exception('Failed to rename food item: $e');
    }
  }
}
