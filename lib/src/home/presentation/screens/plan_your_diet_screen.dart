import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/domain/models/daily_food_entry.dart';
import 'package:befit_fitness_app/src/home/data/services/daily_food_service.dart';
import 'package:befit_fitness_app/src/home/data/services/macro_calculation_service.dart';
import 'package:befit_fitness_app/src/home/data/services/goal_service.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/food_product_details_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/food_storage_service.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/add_food_bottom_sheet.dart';
import 'package:befit_fitness_app/src/home/domain/models/food_unit.dart';

/// Screen for planning daily diet by adding food products
class PlanYourDietScreen extends StatefulWidget {
  static const String route = '/plan-your-diet';

  final String? planId;
  final Map<String, dynamic>? planData;

  const PlanYourDietScreen({
    super.key,
    this.planId,
    this.planData,
  });

  @override
  State<PlanYourDietScreen> createState() => _PlanYourDietScreenState();
}

class _PlanYourDietScreenState extends State<PlanYourDietScreen> {
  final DailyFoodService _foodService = DailyFoodService(
    firestore: FirebaseFirestore.instance,
  );
  final FoodStorageService _storageService = FoodStorageService(
    firestore: FirebaseFirestore.instance,
  );

  List<DailyFoodEntry> _foodEntries = [];
  bool _isLoading = true;
  bool _isMacroSectionExpanded = true;
  final TextEditingController _dietPlanNameController = TextEditingController();
  bool _isSaving = false;
  
  // Macro goals
  double? _carbsGoal;
  double? _proteinGoal;
  double? _fatGoal;
  double? _caloriesGoal;

  // Consumed macros
  double _consumedCalories = 0.0;
  double _consumedProtein = 0.0;
  double _consumedCarbs = 0.0;
  double _consumedFat = 0.0;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isEditing => widget.planId != null && widget.planData != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.planData != null) {
      _dietPlanNameController.text = widget.planData!['name'] as String? ?? 'My Meal Plan';
      _loadPlanData();
    } else {
      _dietPlanNameController.text = 'My Meal Plan'; // Default name
      _loadData();
    }
  }

  @override
  void dispose() {
    _dietPlanNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadMacroGoals(),
        _loadFoodEntries(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMacroGoals() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final macros = profile['macros'] as Map<String, dynamic>? ?? {};
        
        final carbsValue = macros['carbs'] ?? data['profile.macros.carbs'];
        final proteinValue = macros['protein'] ?? data['profile.macros.protein'];
        final fatValue = macros['fat'] ?? data['profile.macros.fat'];
        final calorieValue = profile['calorie'] ?? data['profile.calorie'];

        if (mounted) {
          setState(() {
            _carbsGoal = carbsValue != null ? (carbsValue as num).toDouble() : null;
            _proteinGoal = proteinValue != null ? (proteinValue as num).toDouble() : null;
            _fatGoal = fatValue != null ? (fatValue as num).toDouble() : null;
            _caloriesGoal = calorieValue != null ? (calorieValue as num).toDouble() : null;
          });
        }

        // Fallback to GoalService if not found
        if (_caloriesGoal == null) {
          final calories = await GoalService.getCaloriesGoal();
          if (mounted) {
            setState(() {
              _caloriesGoal = calories;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading macro goals: $e');
    }
  }

  Future<void> _loadFoodEntries() async {
    try {
      final entries = await _foodService.getTodayFoodEntries();
      if (mounted) {
        // Sort by order, then by addedAt if order is the same
        entries.sort((a, b) {
          if (a.order != b.order) {
            return a.order.compareTo(b.order);
          }
          return a.addedAt.compareTo(b.addedAt);
        });
        
        setState(() {
          _foodEntries = entries;
          _calculateConsumedMacros();
        });
      }
    } catch (e) {
      debugPrint('Error loading food entries: $e');
    }
  }

  Future<void> _loadPlanData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadMacroGoals();
      
      if (widget.planData != null) {
        final meals = widget.planData!['meals'] as List<dynamic>? ?? [];
        final entries = <DailyFoodEntry>[];
        
        for (var mealEntry in meals.asMap().entries) {
          final mealIndex = mealEntry.key;
          final meal = mealEntry.value as Map<String, dynamic>;
          final mealData = meal;
          final productData = mealData['product'] as Map<String, dynamic>? ?? {};
          final nutritionData = mealData['nutrition'] as Map<String, dynamic>? ?? {};
          
          // Get base nutrition from product.nutrition if available, otherwise use calculated values
          final productNutrition = productData['nutrition'] as Map<String, dynamic>?;
          final savedServingSize = (nutritionData['servingSize'] as num?)?.toDouble() ?? 
                                   (productNutrition?['servingSize'] as num?)?.toDouble() ?? 100.0;
          final savedQuantity = (nutritionData['quantity'] as num?)?.toDouble() ?? 1.0;
          
          // Use base nutrition from product.nutrition if available
          final baseNutrition = productNutrition ?? nutritionData;
          
          final product = FoodProduct(
            barcode: productData['barcode'] as String? ?? '',
            name: productData['name'] as String? ?? 'Unknown',
            brand: productData['brand'] as String?,
            imageUrl: productData['imageUrl'] as String?,
            category: productData['category'] as String?,
            ingredients: productData['ingredients'] as String?,
            allergens: productData['allergens'] as String?,
            nutrition: NutritionInfo(
              calories: (baseNutrition['calories'] as num?)?.toDouble(),
              protein: (baseNutrition['protein'] as num?)?.toDouble(),
              carbs: (baseNutrition['carbs'] as num?)?.toDouble(),
              fat: (baseNutrition['fat'] as num?)?.toDouble(),
              fiber: (baseNutrition['fiber'] as num?)?.toDouble(),
              sugar: (baseNutrition['sugar'] as num?)?.toDouble(),
              sodium: (baseNutrition['sodium'] as num?)?.toDouble(),
              servingSize: savedServingSize,
              servingUnit: baseNutrition['servingUnit'] as String? ?? nutritionData['servingUnit'] as String?,
            ),
          );
          
          final entry = DailyFoodEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_$mealIndex',
            product: product,
            quantity: savedQuantity,
            addedAt: DateTime.now(),
            mealTime: mealData['mealTime'] as String? ?? '12:00',
            mealName: mealData['mealName'] as String? ?? 'Meal',
            order: mealData['order'] as int? ?? mealIndex,
          );
          
          entries.add(entry);
        }
        
        // Sort by order
        entries.sort((a, b) => a.order.compareTo(b.order));
        
        if (mounted) {
          setState(() {
            _foodEntries = entries;
            _calculateConsumedMacros();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading plan data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateConsumedMacros() {
    double calories = 0.0;
    double protein = 0.0;
    double carbs = 0.0;
    double fat = 0.0;

    for (var entry in _foodEntries) {
      calories += entry.calculatedCalories;
      protein += entry.calculatedProtein;
      carbs += entry.calculatedCarbs;
      fat += entry.calculatedFat;
    }

    setState(() {
      _consumedCalories = calories;
      _consumedProtein = protein;
      _consumedCarbs = carbs;
      _consumedFat = fat;
    });
  }

  Future<void> _addFoodFromScanner() async {
    showAddFoodBottomSheet(context, (List<FoodProduct> products) async {
      for (var product in products) {
        await _addFoodProduct(product);
      }
    });
  }

  Future<void> _addFoodProduct(FoodProduct product, {double? quantity}) async {
    try {
      // Use the product's serving size as default (in the same unit as stored)
      // If servingSize is 5 pieces, defaultQuantity should be 5 pieces (not converted to grams)
      final defaultQuantity = quantity ?? product.nutrition.servingSize ?? 1.0;
      
      // Determine default meal time and name based on current time
      final now = DateTime.now();
      String defaultMealTime = '12:00';
      String defaultMealName = 'Meal';
      
      if (now.hour < 10) {
        defaultMealTime = '08:00';
        defaultMealName = 'Breakfast';
      } else if (now.hour < 14) {
        defaultMealTime = '12:00';
        defaultMealName = 'Lunch';
      } else if (now.hour < 18) {
        defaultMealTime = '15:00';
        defaultMealName = 'Snack';
      } else {
        defaultMealTime = '18:00';
        defaultMealName = 'Dinner';
      }
      
      final entry = DailyFoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: defaultQuantity, // Store in the same unit as servingSize (e.g., 5 pieces = 5)
        addedAt: DateTime.now(),
        mealTime: defaultMealTime,
        mealName: defaultMealName,
        order: _foodEntries.length,
      );

      await _foodService.addFoodEntry(entry);
      await _loadFoodEntries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to your diet'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(DailyFoodEntry entry, double newQuantity) async {
    try {
      await _foodService.updateFoodEntryQuantity(entry.id, newQuantity);
      await _loadFoodEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quantity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    // Haptic feedback for better UX
    HapticFeedback.mediumImpact();
    
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _foodEntries.removeAt(oldIndex);
      _foodEntries.insert(newIndex, item);
      // Update order
      _foodEntries = _foodEntries.asMap().entries.map((entry) {
        return entry.value.copyWith(order: entry.key);
      }).toList();
      
      // Save updated order to backend
      _saveEntriesOrder();
    });
  }

  Future<void> _saveEntriesOrder() async {
    try {
      final dateString = _getTodayDateString();
      for (var entry in _foodEntries) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dailyFoodEntries')
            .doc(dateString)
            .collection('entries')
            .doc(entry.id)
            .update({
          'mealTime': entry.mealTime,
          'mealName': entry.mealName,
          'order': entry.order,
        });
      }
    } catch (e) {
      debugPrint('Error saving entries order: $e');
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _clearAllState() {
    setState(() {
      // Clear food entries
      _foodEntries = [];
      
      // Reset consumed macros
      _consumedCalories = 0.0;
      _consumedProtein = 0.0;
      _consumedCarbs = 0.0;
      _consumedFat = 0.0;
      
      // Reset diet plan name
      _dietPlanNameController.text = 'My Meal Plan';
      
      // Reset macro section expanded state
      _isMacroSectionExpanded = true;
    });
  }

  Future<bool> _checkDuplicateDietPlanName(String planName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dietPlan')
          .where('name', isEqualTo: planName)
          .get();

      // If editing, exclude the current plan from duplicate check
      if (_isEditing && widget.planId != null) {
        final duplicateDocs = snapshot.docs.where((doc) => doc.id != widget.planId);
        return duplicateDocs.isNotEmpty;
      }
      
      // If creating new plan, check if any plan with this name exists
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking duplicate diet plan name: $e');
      return false; // If error, allow save to proceed
    }
  }

  Future<String?> _getExistingPlanId(String planName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dietPlan')
          .where('name', isEqualTo: planName)
          .get();

      // If editing, exclude the current plan
      if (_isEditing && widget.planId != null) {
        final duplicateDoc = snapshot.docs.firstWhere(
          (doc) => doc.id != widget.planId,
          orElse: () => snapshot.docs.first,
        );
        return duplicateDoc.id;
      }

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting existing plan ID: $e');
      return null;
    }
  }

  Future<bool> _showDuplicateNameDialog(String planName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Duplicate Diet Plan Name',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'A diet plan with the name "$planName" already exists. Saving this plan will override the existing one. Do you want to continue?',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(
              'Override',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveDietPlan() async {
    if (_foodEntries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add at least one food item to save the diet plan'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final planName = _dietPlanNameController.text.trim();
    if (planName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a diet plan name'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check for duplicate diet plan name (only for new plans or if name changed)
    String? existingPlanId;
    if (!_isEditing || (widget.planData?['name'] as String? ?? '') != planName) {
      final isDuplicate = await _checkDuplicateDietPlanName(planName);
      if (isDuplicate) {
        if (mounted) {
          final result = await _showDuplicateNameDialog(planName);
          if (result == null || result == false) {
            return;
          }
          // Get the existing plan ID to delete it
          existingPlanId = await _getExistingPlanId(planName);
        }
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final dateString = _getTodayDateString();
      
      // Convert DailyFoodEntry list to the required format
      final meals = _foodEntries.map((entry) {
        // Calculate nutrition values based on quantity
        final servingSize = entry.product.nutrition.servingSize ?? 1.0;
        final baseFiber = entry.product.nutrition.fiber;
        final baseSodium = entry.product.nutrition.sodium;
        final baseSugar = entry.product.nutrition.sugar;
        
        final calculatedFiber = baseFiber != null 
            ? (baseFiber * entry.quantity / servingSize) 
            : null;
        final calculatedSodium = baseSodium != null 
            ? (baseSodium * entry.quantity / servingSize) 
            : null;
        final calculatedSugar = baseSugar != null 
            ? (baseSugar * entry.quantity / servingSize) 
            : null;
        
        return {
          'mealName': entry.mealName,
          'mealTime': entry.mealTime,
          'order': entry.order,
          'product': {
            'name': entry.product.name,
            'barcode': entry.product.barcode ?? '',
            'brand': entry.product.brand,
            'category': entry.product.category,
            'imageUrl': entry.product.imageUrl,
            'ingredients': entry.product.ingredients,
            'allergens': entry.product.allergens,
            'nutrition': {
              'calories': entry.product.nutrition.calories,
              'protein': entry.product.nutrition.protein,
              'carbs': entry.product.nutrition.carbs,
              'fat': entry.product.nutrition.fat,
              'fiber': entry.product.nutrition.fiber,
              'sugar': entry.product.nutrition.sugar,
              'sodium': entry.product.nutrition.sodium,
              'servingSize': entry.product.nutrition.servingSize,
              'servingUnit': entry.product.nutrition.servingUnit,
            },
          },
          'nutrition': {
            'calories': entry.calculatedCalories,
            'carbs': entry.calculatedCarbs,
            'fat': entry.calculatedFat,
            'fiber': calculatedFiber,
            'protein': entry.calculatedProtein,
            'sodium': calculatedSodium,
            'sugar': calculatedSugar,
            'servingSize': entry.product.nutrition.servingSize,
            'servingUnit': entry.product.nutrition.servingUnit ?? 'grams',
            'quantity': entry.quantity,
          },
        };
      }).toList();

      final dietPlanData = {
        'name': planName,
        'date': dateString,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'meals': meals,
        'status': 'inactive', // New plans are set to inactive by default
      };

      // Delete existing plan if duplicate name was confirmed (only for new plans)
      if (existingPlanId != null && !_isEditing) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .doc(existingPlanId)
            .delete();
      }

      // Update existing plan or create new one
      if (_isEditing && widget.planId != null) {
        // Update existing plan - preserve existing status
        final updateData = {
          'name': planName,
          'date': dateString,
          'updatedAt': now.toIso8601String(),
          'meals': meals,
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .doc(widget.planId)
            .update(updateData);
      } else {
        // Create new plan with inactive status
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .add(dietPlanData);
      }

      // Clear all daily food entries after saving (only for new plans, not when editing)
      if (!_isEditing) {
        await _foodService.deleteAllTodayFoodEntries();
        // Clear all state
        _clearAllState();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diet plan saved successfully!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        // Navigate back after saving with result to trigger refresh
        context.pop(true);
      }
    } catch (e) {
      debugPrint('Error saving diet plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save diet plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showTimePicker(DailyFoodEntry entry) async {
    final timeParts = entry.mealTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        final timeString = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
        final index = _foodEntries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _foodEntries[index] = entry.copyWith(mealTime: timeString);
        }
      });
      await _saveEntriesOrder();
    }
  }

  void _showMealNameDialog(DailyFoodEntry entry) {
    final controller = TextEditingController(text: entry.mealName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Meal Name',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.ubuntu(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Meal Name',
            labelStyle: GoogleFonts.ubuntu(color: Colors.white.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  final index = _foodEntries.indexWhere((e) => e.id == entry.id);
                  if (index != -1) {
                    _foodEntries[index] = entry.copyWith(mealName: newName);
                  }
                });
                _saveEntriesOrder();
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(DailyFoodEntry entry) async {
    try {
      await _foodService.deleteFoodEntry(entry.id);
      await _loadFoodEntries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.product.name} removed'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQuantityDialog(DailyFoodEntry entry) {
    // Get the display quantity in the original unit
    final displayQty = entry.displayQuantity;
    final servingUnit = entry.servingUnit;
    final controller = TextEditingController(
      text: displayQty.toStringAsFixed(
        servingUnit.isCount ? 0 : (displayQty == displayQty.floorToDouble() ? 0 : 1),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Edit Quantity',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.product.name,
              style: GoogleFonts.ubuntu(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !servingUnit.isCount,
              ),
              style: GoogleFonts.ubuntu(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Quantity (${servingUnit.displayName})',
                labelStyle: GoogleFonts.ubuntu(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            if (servingUnit == FoodUnit.pieces) ...[
              SizedBox(height: 8.h),
              Text(
                'Note: Partial pieces will be rounded down',
                style: GoogleFonts.ubuntu(
                  color: Colors.orange,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final inputQty = double.tryParse(controller.text);
              if (inputQty == null || inputQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Handle edge cases for pieces
              double finalQty = inputQty;
              if (servingUnit == FoodUnit.pieces) {
                finalQty = FoodUnitConverter.handlePiecesEdgeCase(inputQty);
                if (finalQty == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Minimum quantity is 1 piece'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              // Store quantity directly in the same unit (no conversion)
              // If servingUnit is "pieces" and user enters 3, store 3 (not converted to grams)
              Navigator.of(context).pop();
              _updateQuantity(entry, finalQty);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Diet Plan' : 'Plan Your Diet',
          style: GoogleFonts.ubuntu(
            color: AppColors.textOnPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.save, color: AppColors.primary),
              onPressed: _saveDietPlan,
              tooltip: 'Save Diet Plan',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                // Diet Plan Name Input
                Flexible(
                  flex: 0,
                  child: _buildDietPlanNameSection(),
                ),
                
                // Macro Goals and Progress
                Flexible(
                  flex: 0,
                  child: _buildMacroProgressSection(),
                ),
                
                // Food Entries List
                Expanded(
                  child: _foodEntries.isEmpty
                      ? _buildEmptyState()
                      : _buildFoodEntriesList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "add_food_button",
        onPressed: _addFoodFromScanner,
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text(
          'Add Food',
          style: GoogleFonts.ubuntu(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDietPlanNameSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diet Plan Name',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _dietPlanNameController,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Enter diet plan name',
              hintStyle: GoogleFonts.ubuntu(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16.sp,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMacroSectionExpanded = !_isMacroSectionExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.35,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Macros',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AnimatedRotation(
                  turns: _isMacroSectionExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isMacroSectionExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 12.h),
                        if (_caloriesGoal != null)
                          _buildMacroProgressItem(
                            'Calories',
                            _consumedCalories,
                            _caloriesGoal!,
                            'kcal',
                            AppColors.primary,
                          ),
                        if (_caloriesGoal != null) SizedBox(height: 10.h),
                        if (_carbsGoal != null)
                          _buildMacroProgressItem(
                            'Carbs',
                            _consumedCarbs,
                            _carbsGoal!,
                            'g',
                            const Color(0xFF4CAF50),
                          ),
                        if (_carbsGoal != null) SizedBox(height: 10.h),
                        if (_proteinGoal != null)
                          _buildMacroProgressItem(
                            'Protein',
                            _consumedProtein,
                            _proteinGoal!,
                            'g',
                            const Color(0xFF2196F3),
                          ),
                        if (_proteinGoal != null) SizedBox(height: 10.h),
                        if (_fatGoal != null)
                          _buildMacroProgressItem(
                            'Fat',
                            _consumedFat,
                            _fatGoal!,
                            'g',
                            const Color(0xFFFF9800),
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroProgressItem(
    String label,
    double consumed,
    double goal,
    String unit,
    Color color,
  ) {
    final percentage = (consumed / goal * 100).clamp(0.0, 100.0);
    final isOverGoal = consumed > goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
              style: GoogleFonts.ubuntu(
                color: isOverGoal ? Colors.red : Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverGoal ? Colors.red : color,
            ),
            minHeight: 6.h,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: GoogleFonts.ubuntu(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 80.sp,
                color: Colors.white.withOpacity(0.3),
              ),
              SizedBox(height: 16.h),
              Text(
                'No food items added yet',
                style: GoogleFonts.ubuntu(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tap the button below to add food',
                style: GoogleFonts.ubuntu(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodEntriesList() {
    return ReorderableListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _foodEntries.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            
            try {
              final animValue = animation.value.clamp(0.0, 1.0);
              if (animValue.isNaN || !animValue.isFinite) {
                return child;
              }
              
              final curveValue = Curves.easeInOut.transform(animValue);
              if (curveValue.isNaN || !curveValue.isFinite) {
                return child;
              }
              
              final elevation = (ui.lerpDouble(2, 8, curveValue) ?? 2.0).clamp(0.0, 20.0);
              final scale = (ui.lerpDouble(1.0, 1.05, curveValue) ?? 1.0).clamp(0.5, 2.0);
              
              // Ensure no NaN values
              if (elevation.isNaN || scale.isNaN || !elevation.isFinite || !scale.isFinite) {
                return child;
              }
              
              final screenWidth = MediaQuery.of(context).size.width;
              final width = (screenWidth - 40.w).clamp(0.0, screenWidth);
              
              if (width.isNaN || !width.isFinite || width <= 0) {
                return child;
              }
              
              return Material(
                elevation: elevation,
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.transparent,
                shadowColor: AppColors.primary.withOpacity(0.5),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: width,
                    constraints: BoxConstraints(
                      minHeight: 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: OverflowBox(
                        maxHeight: double.infinity,
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: EdgeInsets.only(bottom: -20.h), // Negative margin to exclude bottom space
                          child: Opacity(
                            opacity: 0.9,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } catch (e) {
              // If any error occurs, just return the child
              debugPrint('Error in proxyDecorator: $e');
              return child;
            }
          },
          child: child,
        );
      },
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final entry = _foodEntries[index];
        return _buildFoodEntryCard(entry, index);
      },
    );
  }

  Widget _buildFoodEntryCard(DailyFoodEntry entry, int index) {
    return Container(
      key: ValueKey(entry.id),
      margin: EdgeInsets.only(bottom: 20.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            // Optional: Add haptic feedback
            // HapticFeedback.lightImpact();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Enhanced Drag Handle
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.drag_handle,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Product Image with enhanced styling
                    Hero(
                      tag: 'food_image_${entry.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: entry.product.imageUrl != null
                            ? Container(
                                width: 60.w,
                                height: 60.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  image: DecorationImage(
                                    image: NetworkImage(entry.product.imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                width: 60.w,
                                height: 60.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.fastfood,
                                  color: AppColors.primary,
                                  size: 30.sp,
                                ),
                              ),
                      ),
                    ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.product.name,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.product.brand != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        entry.product.brand!,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteEntry(entry),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Time and Meal Name
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              GestureDetector(
                onTap: () => _showTimePicker(entry),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.primary,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        entry.mealTime,
                        style: GoogleFonts.ubuntu(
                          color: AppColors.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showMealNameDialog(entry),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    entry.mealName,
                    style: GoogleFonts.ubuntu(
                      color: const Color(0xFF4CAF50),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildNutritionChip(
                  'Calories',
                  entry.calculatedCalories.toStringAsFixed(0),
                  'kcal',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildNutritionChip(
                  'Carbs',
                  entry.calculatedCarbs.toStringAsFixed(1),
                  'g',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildNutritionChip(
                  'Protein',
                  entry.calculatedProtein.toStringAsFixed(1),
                  'g',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildNutritionChip(
                  'Fat',
                  entry.calculatedFat.toStringAsFixed(1),
                  'g',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => _showQuantityDialog(entry),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Quantity: ${FoodUnitConverter.formatQuantity(entry.displayQuantity, entry.servingUnit)}',
                    style: GoogleFonts.ubuntu(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
      ),),
    );
  }

  Widget _buildNutritionChip(String label, String value, String unit) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$value $unit',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
