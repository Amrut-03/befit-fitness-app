import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/utils/app_snackbar.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/food_storage_service.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/smart_suggestion_service.dart';
import 'package:befit_fitness_app/src/home/domain/models/daily_food_entry.dart';
import 'package:befit_fitness_app/src/home/data/services/daily_food_service.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/diet_planning_screen.dart';

/// Screen displaying detailed food product information
class FoodProductDetailsScreen extends StatefulWidget {
  static const String route = '/food-product-details';
  
  final FoodProduct product;

  const FoodProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<FoodProductDetailsScreen> createState() => _FoodProductDetailsScreenState();
}

class _FoodProductDetailsScreenState extends State<FoodProductDetailsScreen> {
  final FoodStorageService _storageService = FoodStorageService(
    firestore: FirebaseFirestore.instance,
  );
  final SmartSuggestionService _suggestionService = SmartSuggestionService(
    firestore: FirebaseFirestore.instance,
  );
  final DailyFoodService _foodService = DailyFoodService(
    firestore: FirebaseFirestore.instance,
  );
  
  bool _isSaving = false;
  bool _isSaved = false;
  bool _isAddingToDiet = false;
  bool _isLoadingSuggestions = true;
  List<String> _suggestions = [];
  bool _hasShownPrivacyMessage = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _loadSuggestions();
    _showPrivacyMessage();
  }

  Future<void> _checkIfSaved() async {
    try {
      final saved = await _storageService.isFoodItemSaved(widget.product.name);
      if (mounted) {
        setState(() {
          _isSaved = saved;
        });
      }
    } catch (e) {
      debugPrint('Error checking if saved: $e');
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await _suggestionService.generateSuggestions(widget.product);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  void _showPrivacyMessage() {
    if (!_hasShownPrivacyMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPrivacyBottomSheet();
          _hasShownPrivacyMessage = true;
        }
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('FoodProductDetailsScreen: Attempting to save product: ${widget.product.name}');
      final success = await _storageService.saveScannedFoodItem(widget.product);
      debugPrint('FoodProductDetailsScreen: Save result: $success');
      
      if (mounted) {
        if (success) {
          setState(() {
            _isSaved = true;
            _isSaving = false;
          });
          _showSuccessSnackBar('Product saved successfully!');
          // Re-check if saved to update UI
          _checkIfSaved();
        } else {
          setState(() {
            _isSaving = false;
          });
          _showErrorSnackBar('Failed to save product');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('FoodProductDetailsScreen: Error saving product: $e');
      debugPrint('FoodProductDetailsScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<void> _addToDiet() async {
    if (_isAddingToDiet) return;

    setState(() {
      _isAddingToDiet = true;
    });

    try {
      final entry = DailyFoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: widget.product,
        quantity: widget.product.nutrition.servingSize ?? 100.0,
        addedAt: DateTime.now(),
      );

      await _foodService.addFoodEntry(entry);
      
      if (mounted) {
        setState(() {
          _isAddingToDiet = false;
        });
        _showSuccessSnackBar('${widget.product.name} added to your diet!');
        // Navigate to diet planning screen
        await context.push(DietPlanningScreen.route);
      }
    } catch (e) {
      debugPrint('FoodProductDetailsScreen: Error adding to diet: $e');
      if (mounted) {
        setState(() {
          _isAddingToDiet = false;
        });
        _showErrorSnackBar('Failed to add to diet: $e');
      }
    }
  }

  void _showPrivacyBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPrivacyBottomSheet(),
    );
  }

  Widget _buildPrivacyBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: AppColors.primary,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Privacy & Data',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'Your Privacy Matters',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          Text(
            '• We only store product data if you choose to save it\n'
            '• Your scanned products are stored securely in your account\n'
            '• We never share your data with third parties\n'
            '• You can delete saved products anytime',
            style: GoogleFonts.ubuntu(
              color: Colors.white70,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
          
          SizedBox(height: 24.h),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Got it!',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Share Feedback',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: 'Tell us what you think about this product...',
            hintStyle: GoogleFonts.ubuntu(
              color: Colors.white54,
              fontSize: 14.sp,
            ),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Save feedback to Firestore
              _submitFeedback(feedbackController.text);
              Navigator.of(context).pop();
            },
            child: Text(
              'Submit',
              style: GoogleFonts.ubuntu(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(String feedback) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          _showErrorSnackBar('Please login to submit feedback');
        }
        return;
      }

      // Get current date in YYYY-MM-DD format
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      debugPrint('FoodProductDetailsScreen: Submitting feedback - userId: $userId, dateKey: $dateKey');

      // Reference to the foodFeedbacks subcollection
      // Structure: feedbacks/{userId}/foodFeedbacks/{foodFeedbackId}
      final foodFeedbacksRef = FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(userId)
          .collection('foodFeedbacks');

      // Use date as document ID, or create with auto-generated ID and store date as field
      // Check if document with this date field exists
      final existingDocs = await foodFeedbacksRef
          .where(dateKey, isNull: false)
          .limit(1)
          .get();

      // Prepare feedback data with date as field key
      final feedbackData = {
        dateKey: {
          'createdAt': FieldValue.serverTimestamp(),
          'feedback': feedback,
          'productBarcode': widget.product.barcode,
          'productName': widget.product.name,
        },
      };

      if (existingDocs.docs.isNotEmpty) {
        // Update existing document that has this date field
        final docId = existingDocs.docs.first.id;
        await foodFeedbacksRef.doc(docId).update(feedbackData);
        debugPrint('FoodProductDetailsScreen: Updated existing feedback document: $docId');
      } else {
        // Create new document with auto-generated ID (foodFeedbackId)
        await foodFeedbacksRef.add(feedbackData);
        debugPrint('FoodProductDetailsScreen: Created new feedback document with date: $dateKey');
      }

      if (mounted) {
        _showSuccessSnackBar('Thank you for your feedback!');
      }
    } catch (e, stackTrace) {
      debugPrint('FoodProductDetailsScreen: Error submitting feedback: $e');
      debugPrint('FoodProductDetailsScreen: Stack trace: $stackTrace');
      if (mounted) {
        _showErrorSnackBar('Failed to submit feedback: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    AppSnackBar.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    AppSnackBar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with back button
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Product Details',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Feedback button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.feedback_outlined, color: Colors.white),
                        onPressed: _showFeedbackDialog,
                      ),
                    ),
                  ],
                ),
              ),

              // Product image
              if (widget.product.imageUrl != null)
                Container(
                  width: double.infinity,
                  height: 250.h,
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 60.sp,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200.h,
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    color: Colors.grey[600],
                    size: 80.sp,
                  ),
                ),

              SizedBox(height: 20.h),

              // Product name and brand
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.product.brand != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        widget.product.brand!,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white70,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                    if (widget.product.category != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.product.category!,
                          style: GoogleFonts.ubuntu(
                            color: AppColors.primary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Smart Suggestions
              if (_suggestions.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Smart Suggestions',
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        ..._suggestions.map((suggestion) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: GoogleFonts.ubuntu(
                                    color: Colors.white70,
                                    fontSize: 14.sp,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],

              // Action buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    // Add to Diet button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAddingToDiet ? null : _addToDiet,
                        icon: _isAddingToDiet
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.restaurant_menu,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isAddingToDiet ? 'Adding...' : 'Add to Diet',
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Save button
                    Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaved ? null : _saveProduct,
                    icon: _isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isSaved ? Icons.check_circle : Icons.save,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isSaved
                          ? 'Saved'
                          : _isSaving
                              ? 'Saving...'
                                  : 'Save',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved
                          ? Colors.grey[700]
                              : Colors.grey[800],
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Nutrition facts card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[900]!,
                        Colors.grey[800]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
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
                          Icon(
                            Icons.restaurant_menu,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nutrition Facts',
                                  style: GoogleFonts.ubuntu(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'per 100g',
                                  style: GoogleFonts.ubuntu(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      SizedBox(height: 20.h),
                      
                      // Calories
                      _buildNutritionRow(
                        'Calories',
                        widget.product.nutrition.formattedCalories,
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Protein
                      _buildNutritionRow(
                        'Protein',
                        widget.product.nutrition.formattedProtein,
                        Icons.fitness_center,
                        Colors.blue,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Carbs
                      _buildNutritionRow(
                        'Carbohydrates',
                        widget.product.nutrition.formattedCarbs,
                        Icons.energy_savings_leaf,
                        Colors.green,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Fat
                      _buildNutritionRow(
                        'Fat',
                        widget.product.nutrition.formattedFat,
                        Icons.water_drop,
                        Colors.red,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Fiber
                      if (widget.product.nutrition.fiber != null)
                        _buildNutritionRow(
                          'Fiber',
                          widget.product.nutrition.formattedFiber,
                          Icons.eco,
                          Colors.teal,
                        ),
                      if (widget.product.nutrition.fiber != null) SizedBox(height: 16.h),
                      
                      // Sugar
                      if (widget.product.nutrition.sugar != null)
                        _buildNutritionRow(
                          'Sugar',
                          widget.product.nutrition.formattedSugar,
                          Icons.cake,
                          Colors.pink,
                        ),
                      if (widget.product.nutrition.sugar != null) SizedBox(height: 16.h),
                      
                      // Sodium
                      if (widget.product.nutrition.sodium != null)
                        _buildNutritionRow(
                          'Sodium',
                          widget.product.nutrition.formattedSodium,
                          Icons.science,
                          Colors.purple,
                        ),
                    ],
                  ),
                ),
              ),

              // Ingredients
              if (widget.product.ingredients != null) ...[
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[900]!,
                          Colors.grey[800]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
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
                            Icon(
                              Icons.list,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Ingredients',
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          widget.product.ingredients!,
                          style: GoogleFonts.ubuntu(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Allergens
              if (widget.product.allergens != null && widget.product.allergens!.isNotEmpty) ...[
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Allergens',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.red,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                widget.product.allergens!,
                                style: GoogleFonts.ubuntu(
                                  color: Colors.red[200],
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            color: AppColors.primary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
