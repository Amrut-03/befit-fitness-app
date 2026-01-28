import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';

/// Service for saving and retrieving scanned food items from Firestore
class FoodStorageService {
  final FirebaseFirestore firestore;
  
  FoodStorageService({required this.firestore});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Normalize food item name for storage key
  /// Converts to lowercase, removes special characters, numbers, and spaces
  String _normalizeFoodName(String name) {
    // Convert to lowercase
    String normalized = name.toLowerCase();
    
    // Remove special characters, numbers, and spaces
    normalized = normalized.replaceAll(RegExp(r'[^a-z]'), '');
    
    return normalized;
  }

  /// Save scanned food item to Firestore
  /// Structure: users/{userId}/foodItems/barcodeScannedFood/foodItems/{randomDocId} -> productData
  Future<bool> saveScannedFoodItem(FoodProduct product) async {
    try {
      if (_userId.isEmpty) {
        debugPrint('FoodStorageService: User not authenticated');
        throw Exception('User not authenticated');
      }

      final normalizedName = _normalizeFoodName(product.name);
      debugPrint('FoodStorageService: Saving product - userId: $_userId, normalizedName: $normalizedName');
      
      // Reference to the foodItems collection
      // Structure: users/{userId}/foodItems/barcodeScannedFood/foodItems/{randomDocId}
      final foodItemsCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('barcodeScannedFood')
          .collection('foodItems');

      // Check if a document with this normalized name already exists
      final existingDocs = await foodItemsCollection
          .where('normalizedName', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      // Prepare product data
      final productData = {
        'normalizedName': normalizedName,
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
        },
        'scannedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingDocs.docs.isNotEmpty) {
        // Document exists, update it
        final docId = existingDocs.docs.first.id;
        await foodItemsCollection.doc(docId).update(productData);
        debugPrint('FoodStorageService: Updated existing document: $docId');
      } else {
        // Document doesn't exist, create new one with random ID
        await foodItemsCollection.add({
          ...productData,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FoodStorageService: Created new document with random ID');
      }

      debugPrint('FoodStorageService: Successfully saved food item');
      return true;
    } catch (e, stackTrace) {
      debugPrint('FoodStorageService: Error saving food item: $e');
      debugPrint('FoodStorageService: Stack trace: $stackTrace');
      throw Exception('Failed to save food item: $e');
    }
  }

  /// Check if a food item is already saved
  Future<bool> isFoodItemSaved(String productName) async {
    try {
      if (_userId.isEmpty) {
        return false;
      }

      final normalizedName = _normalizeFoodName(productName);
      
      final foodItemsCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('barcodeScannedFood')
          .collection('foodItems');

      // Check if a document with this normalized name exists
      final existingDocs = await foodItemsCollection
          .where('normalizedName', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      return existingDocs.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FoodStorageService: Error checking if food item is saved: $e');
      return false;
    }
  }

  /// Get all saved food items
  Future<Map<String, dynamic>> getAllSavedFoodItems() async {
    try {
      if (_userId.isEmpty) {
        return {};
      }

      final foodItemsCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('barcodeScannedFood')
          .collection('foodItems');

      final querySnapshot = await foodItemsCollection.get();
      
      if (querySnapshot.docs.isEmpty) {
        return {};
      }

      // Convert documents to a map with normalizedName as key
      final Map<String, dynamic> foodItemsMap = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final normalizedName = data['normalizedName'] as String?;
        if (normalizedName != null) {
          foodItemsMap[normalizedName] = data;
        }
      }
      
      return foodItemsMap;
    } catch (e) {
      throw Exception('Failed to get saved food items: $e');
    }
  }

  /// Get all saved food items as FoodProduct list
  Future<List<FoodProduct>> getAllSavedFoodProducts() async {
    try {
      if (_userId.isEmpty) {
        return [];
      }

      final foodItemsCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('barcodeScannedFood')
          .collection('foodItems');

      final querySnapshot = await foodItemsCollection.get();
      
      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final List<FoodProduct> products = [];
      for (var doc in querySnapshot.docs) {
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
        products.add(product);
      }
      
      return products;
    } catch (e) {
      throw Exception('Failed to get saved food products: $e');
    }
  }

  /// Save manually added food item
  Future<bool> saveManualFoodItem(FoodProduct product) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final normalizedName = _normalizeFoodName(product.name);
      
      // Use a different collection for manually added items
      final foodItemsCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('manualFilledFood')
          .collection('foodItems');

      // Check if a document with this normalized name already exists
      final existingDocs = await foodItemsCollection
          .where('normalizedName', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      // Prepare product data
      final productData = {
        'normalizedName': normalizedName,
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
        'isManual': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingDocs.docs.isNotEmpty) {
        // Document exists, update it
        final docId = existingDocs.docs.first.id;
        await foodItemsCollection.doc(docId).update(productData);
      } else {
        // Document doesn't exist, create new one
        await foodItemsCollection.add(productData);
      }

      return true;
    } catch (e) {
      throw Exception('Failed to save manual food item: $e');
    }
  }

  /// Get all food items (both scanned and manual)
  Future<List<FoodProduct>> getAllFoodProducts() async {
    try {
      final scanned = await getAllSavedFoodProducts();
      
      // Also get manually added items
      if (_userId.isEmpty) {
        return scanned;
      }

      final manualFoodCollection = firestore
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('manualFilledFood')
          .collection('foodItems');

      final manualSnapshot = await manualFoodCollection.get();
      final List<FoodProduct> manualProducts = [];
      
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
          ),
        );
        manualProducts.add(product);
      }
      
      return [...scanned, ...manualProducts];
    } catch (e) {
      throw Exception('Failed to get all food products: $e');
    }
  }
}

