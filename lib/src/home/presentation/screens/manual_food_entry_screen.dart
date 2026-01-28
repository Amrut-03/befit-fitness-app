import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/food_storage_service.dart';
import 'package:befit_fitness_app/src/home/domain/models/food_unit.dart';

/// Screen for manually adding food items with ingredients and macros
class ManualFoodEntryScreen extends StatefulWidget {
  static const String route = '/manual-food-entry';

  final FoodProduct? product;
  final String? docId;
  final String? type;

  const ManualFoodEntryScreen({
    super.key,
    this.product,
    this.docId,
    this.type,
  });

  @override
  State<ManualFoodEntryScreen> createState() => _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends State<ManualFoodEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final FoodStorageService _storageService = FoodStorageService(
    firestore: FirebaseFirestore.instance,
  );

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '100');

  FoodUnit _selectedUnit = FoodUnit.grams;
  bool _isSaving = false;
  bool get _isEditing => widget.docId != null;

  @override
  void initState() {
    super.initState();
    // Load product data if in edit mode
    if (widget.product != null && widget.docId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductData(widget.product!);
      });
    }
  }

  void _loadProductData(FoodProduct product) {
    setState(() {
      _nameController.text = product.name;
      _brandController.text = product.brand ?? '';
      _ingredientsController.text = product.ingredients ?? '';
      _caloriesController.text = product.nutrition.calories?.toStringAsFixed(0) ?? '';
      _proteinController.text = product.nutrition.protein?.toStringAsFixed(1) ?? '';
      _carbsController.text = product.nutrition.carbs?.toStringAsFixed(1) ?? '';
      _fatController.text = product.nutrition.fat?.toStringAsFixed(1) ?? '';
      
      if (product.nutrition.servingSize != null) {
        _servingSizeController.text = product.nutrition.servingSize!.toStringAsFixed(0);
      }
      
      if (product.nutrition.servingUnit != null) {
        try {
          _selectedUnit = FoodUnit.values.firstWhere(
            (unit) => unit.name == product.nutrition.servingUnit,
            orElse: () => FoodUnit.grams,
          );
        } catch (e) {
          _selectedUnit = FoodUnit.grams;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveFoodItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Get the serving size quantity from input
      final servingSizeInput = double.tryParse(_servingSizeController.text);
      if (servingSizeInput == null || servingSizeInput <= 0) {
        throw Exception('Invalid serving size');
      }

      // Handle edge cases for pieces: 0.5 = 0, 1.25 = 1
      double finalServingSize = servingSizeInput;
      if (_selectedUnit.isCount) {
        finalServingSize = FoodUnitConverter.handlePiecesEdgeCase(servingSizeInput);
        if (finalServingSize == 0) {
          throw Exception('Minimum quantity is 1 ${_selectedUnit.displayName.toLowerCase()}');
        }
      }

      // Store the serving size exactly as user entered it
      // No conversion to grams - store the raw value and unit
      // Example: User enters "5 pieces" -> servingSize = 5, servingUnit = "pieces"

      final product = FoodProduct(
        barcode: '', // No barcode for manual entries
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        imageUrl: null,
        category: null,
        ingredients: _ingredientsController.text.trim().isEmpty
            ? null
            : _ingredientsController.text.trim(),
        allergens: null,
        nutrition: NutritionInfo(
          // Store nutritional values exactly as user entered (for the serving size they specified)
          calories: double.tryParse(_caloriesController.text) ?? 0.0,
          protein: double.tryParse(_proteinController.text) ?? 0.0,
          carbs: double.tryParse(_carbsController.text) ?? 0.0,
          fat: double.tryParse(_fatController.text) ?? 0.0,
          fiber: null,
          sugar: null,
          sodium: null,
          servingSize: finalServingSize, // Store exactly as user entered (e.g., 5 for "5 pieces")
          servingUnit: _selectedUnit.name, // Store the unit name (e.g., 'grams', 'cups', 'pieces')
        ),
      );

      if (_isEditing && widget.docId != null && widget.type != null) {
        // Update existing food item
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final collection = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('foodItems')
            .doc(widget.type == 'manual' ? 'manualFilledFood' : 'barcodeScannedFood')
            .collection('foodItems');

        final normalizedName = _normalizeFoodName(product.name);
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
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await collection.doc(widget.docId).update(productData);
      } else {
        // Save new food item
        await _storageService.saveManualFoodItem(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? '${product.name} updated successfully!'
                : '${product.name} saved successfully!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop(product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _normalizeFoodName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _onUnitChanged(FoodUnit? newUnit) {
    if (newUnit == null || newUnit == _selectedUnit) return;

    // Get current quantity
    final currentQty = double.tryParse(_servingSizeController.text) ?? 0.0;

    if (currentQty > 0) {
      // Convert from old unit to grams, then to new unit
      final grams = FoodUnitConverter.convertToGrams(
        quantity: currentQty,
        fromUnit: _selectedUnit,
        servingSize: 100.0, // Base reference
      );

      final newQty = FoodUnitConverter.convertFromGrams(
        grams: grams,
        toUnit: newUnit,
        servingSize: 100.0, // Base reference
      );

      // Update controller with converted quantity
      setState(() {
        _selectedUnit = newUnit;
        _servingSizeController.text = newQty.toStringAsFixed(
          newUnit.isCount ? 0 : (newQty == newQty.floorToDouble() ? 0 : 1),
        );
      });
    } else {
      setState(() {
        _selectedUnit = newUnit;
      });
    }
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
          _isEditing ? 'Edit Food Item' : 'Add Food Manually',
          style: GoogleFonts.ubuntu(
            color: AppColors.textOnPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Name
              Text(
                'Food Name *',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.ubuntu(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Grilled Chicken Breast',
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Food name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // Brand (Optional)
              Text(
                'Brand (Optional)',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _brandController,
                style: GoogleFonts.ubuntu(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Brand Name',
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Ingredients (Optional)
              Text(
                'Ingredients (Optional)',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _ingredientsController,
                style: GoogleFonts.ubuntu(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'List ingredients separated by commas',
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Serving Size with Unit Selection
              Text(
                'Serving Size *',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _servingSizeController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: !_selectedUnit.isCount,
                      ),
                      style: GoogleFonts.ubuntu(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _selectedUnit.isCount ? '1' : '100',
                        hintStyle: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Serving size is required';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Enter a valid serving size';
                        }

                        // Validate based on unit type
                        final validationError = FoodUnitConverter.validateQuantity(num, _selectedUnit);
                        if (validationError != null) {
                          return validationError;
                        }

                        // Handle edge cases for pieces
                        if (_selectedUnit.isCount) {
                          final processedQty = FoodUnitConverter.handlePiecesEdgeCase(num);
                          if (processedQty == 0) {
                            return 'Minimum quantity is 1 ${_selectedUnit.displayName.toLowerCase()}';
                          }
                          // Realistic validation for pieces: 1-100 pieces
                          if (num > 100) {
                            return 'Serving size seems too large. Please enter a realistic value (1-100 pieces)';
                          }
                        } else {
                          // Realistic validation for weight/volume units
                          // Convert to grams for validation
                          final grams = FoodUnitConverter.convertToGrams(
                            quantity: num,
                            fromUnit: _selectedUnit,
                            servingSize: 100.0,
                          );
                          
                          // Realistic serving size: 1g to 2000g (2kg)
                          if (grams < 1) {
                            return 'Serving size is too small. Minimum is 1g';
                          }
                          if (grams > 2000) {
                            return 'Serving size seems too large. Please enter a realistic value (max 2000g)';
                          }
                        }

                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<FoodUnit>(
                      value: _selectedUnit,
                      dropdownColor: Colors.grey[900],
                      style: GoogleFonts.ubuntu(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: GoogleFonts.ubuntu(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      items: FoodUnit.getAllAvailableUnits().map((unit) {
                        return DropdownMenuItem<FoodUnit>(
                          value: unit,
                          child: Text(
                            unit.displayName,
                            style: GoogleFonts.ubuntu(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: _onUnitChanged,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              if (_selectedUnit == FoodUnit.pieces)
                Text(
                  'Note: Partial pieces will be rounded down (0.5 = 0, 1.25 = 1)',
                  style: GoogleFonts.ubuntu(
                    color: Colors.orange,
                    fontSize: 11.sp,
                  ),
                ),
              if (_selectedUnit == FoodUnit.customServing)
                Text(
                  'Note: Enter the number of servings. Each serving equals the base serving size.',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11.sp,
                  ),
                ),
              SizedBox(height: 30.h),

              // Macros Section
              Text(
                'Nutritional Information *',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Enter values for the serving size specified above',
                style: GoogleFonts.ubuntu(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // Calories
              _buildMacroField(
                label: 'Calories (kcal)',
                controller: _caloriesController,
                icon: Icons.local_fire_department,
                color: AppColors.primary,
              ),
              SizedBox(height: 16.h),

              // Protein
              _buildMacroField(
                label: 'Protein (g)',
                controller: _proteinController,
                icon: Icons.fitness_center,
                color: const Color(0xFF2196F3),
              ),
              SizedBox(height: 16.h),

              // Carbs
              _buildMacroField(
                label: 'Carbohydrates (g)',
                controller: _carbsController,
                icon: Icons.grain,
                color: const Color(0xFF4CAF50),
              ),
              SizedBox(height: 16.h),

              // Fat
              _buildMacroField(
                label: 'Fat (g)',
                controller: _fatController,
                icon: Icons.water_drop,
                color: const Color(0xFFFF9800),
              ),
              SizedBox(height: 30.h),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveFoodItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Food Item' : 'Save Food Item',
                          style: GoogleFonts.ubuntu(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.ubuntu(color: Colors.white),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.5),
            ),
            filled: true,
            fillColor: color.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            final num = double.tryParse(value);
            if (num == null || num < 0) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }
}
