import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/plan_your_diet_screen.dart';

/// Screen for viewing and editing diet plan details
class DietPlanDetailScreen extends StatefulWidget {
  static const String route = '/diet-plan-detail';
  
  final String planId;
  final Map<String, dynamic> planData;

  const DietPlanDetailScreen({
    super.key,
    required this.planId,
    required this.planData,
  });

  @override
  State<DietPlanDetailScreen> createState() => _DietPlanDetailScreenState();
}

class _DietPlanDetailScreenState extends State<DietPlanDetailScreen> {
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  List<Map<String, dynamic>> _meals = []; // Local copy of meals with consumed state
  bool _hasChanges = false; // Track if there are unsaved changes
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  /// Safely get meals as a list (Firestore may return List or Map).
  static List<dynamic> _mealsAsList(dynamic value) {
    if (value == null) return [];
    if (value is List<dynamic>) return value;
    if (value is Map) {
      final map = value as Map;
      final keys = map.keys.whereType<String>().toList()
        ..sort((a, b) {
          final na = int.tryParse(a);
          final nb = int.tryParse(b);
          if (na != null && nb != null) return na.compareTo(nb);
          return a.compareTo(b);
        });
      return keys.map((k) => map[k]).whereType<dynamic>().toList();
    }
    return [];
  }

  /// True if [timeHHmm] (24h "HH:mm") has passed today (or its scheduled occurrence has passed).
  static bool _hasAlarmTimePassed(String? timeHHmm) {
    if (timeHHmm == null || timeHHmm.isEmpty) return false;
    final parts = timeHHmm.trim().split(RegExp(r'[:\s.]'));
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return false;
    final now = DateTime.now();
    final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    return !scheduled.isAfter(now);
  }

  /// Format "HH:mm" (24h) as 12h with AM/PM.
  static String _formatTime12h(String timeHHmm) {
    final parts = timeHHmm.trim().split(RegExp(r'[:\s.]'));
    if (parts.length < 2) return timeHHmm;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return timeHHmm;
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h12:${minute.toString().padLeft(2, '0')} $ampm';
  }

  void _loadMeals() {
    final meals = _mealsAsList(widget.planData['meals']);
    var anyAutoMarked = false;
    _meals = meals.map((meal) {
      final mealMap = Map<String, dynamic>.from(meal as Map<String, dynamic>);
      final product = mealMap['product'] as Map<String, dynamic>? ?? {};
      if (!product.containsKey('isConsumed')) {
        product['isConsumed'] = false;
      }
      final alarmTime = mealMap['alarmTime'] as String? ?? mealMap['mealTime'] as String?;
      if (alarmTime != null && alarmTime.isNotEmpty && _hasAlarmTimePassed(alarmTime)) {
        if (product['isConsumed'] != true) {
          product['isConsumed'] = true;
          anyAutoMarked = true;
        }
      }
      mealMap['product'] = product;
      return mealMap;
    }).toList();
    if (anyAutoMarked) {
      _hasChanges = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _saveConsumedMeals());
    }
  }

  bool _isMealConsumed(int mealIndex) {
    if (mealIndex >= _meals.length) return false;
    final meal = _meals[mealIndex];
    final product = meal['product'] as Map<String, dynamic>? ?? {};
    return product['isConsumed'] as bool? ?? false;
  }

  Future<void> _saveConsumedMeals() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update the meals array in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dietPlan')
          .doc(widget.planId)
          .update({
        'meals': _meals,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal status saved successfully'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        // Notify parent to refresh
        context.pop(true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving consumed meals: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save meal status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  double _calculateTotalCalories(List<dynamic> meals) {
    double total = 0.0;
    for (var meal in meals) {
      final nutrition = meal['nutrition'] as Map<String, dynamic>?;
      if (nutrition != null) {
        total += (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  double _calculateTotalMacro(List<dynamic> meals, String macroName) {
    double total = 0.0;
    for (var meal in meals) {
      final nutrition = meal['nutrition'] as Map<String, dynamic>?;
      if (nutrition != null) {
        total += (nutrition[macroName] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  Future<void> _editDietPlan() async {
    // Navigate to Plan Your Diet screen with the plan data
    final result = await context.push<bool>(
      PlanYourDietScreen.route,
      extra: {
        'planId': widget.planId,
        'planData': widget.planData,
      },
    );
    
    if (result == true && mounted) {
      // Reload meals and notify parent
      _loadMeals();
      context.pop(true);
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planName = widget.planData['name'] as String? ?? 'Untitled Plan';
    final date = widget.planData['date'] as String? ?? '';
    final createdAt = widget.planData['createdAt'] as String? ?? '';
    final updatedAt = widget.planData['updatedAt'] as String? ?? '';
    final status = widget.planData['status'] as String? ?? 'active';
    final isActive = status == 'active';

    final totalCalories = _calculateTotalCalories(_meals);
    final totalProtein = _calculateTotalMacro(_meals, 'protein');
    final totalCarbs = _calculateTotalMacro(_meals, 'carbs');
    final totalFat = _calculateTotalMacro(_meals, 'fat');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () {
            // Return true if changes were saved, false otherwise
            context.pop(_hasChanges == false);
          },
        ),
        title: Text(
          'Diet Plan Details',
          style: GoogleFonts.ubuntu(
            color: AppColors.textOnPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isActive) ...[
            if (_hasChanges && !_isSaving)
              IconButton(
                icon: Icon(Icons.save, color: AppColors.primary),
                onPressed: _saveConsumedMeals,
                tooltip: 'Save changes',
              ),
            if (_isSaving)
              Padding(
                padding: EdgeInsets.all(16.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
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
                    planName,
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Date: ${_formatDate(date)}',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${_meals.length} meals',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  if (createdAt.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Created: ${_formatDateTime(createdAt)}',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Total Macros Summary
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(20.w),
              padding: EdgeInsets.all(20.w),
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
                  Text(
                    'Total Nutrition',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMacroChip(
                          'Calories',
                          totalCalories.toStringAsFixed(0),
                          'kcal',
                          AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMacroChip(
                          'Protein',
                          totalProtein.toStringAsFixed(1),
                          'g',
                          const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMacroChip(
                          'Carbs',
                          totalCarbs.toStringAsFixed(1),
                          'g',
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMacroChip(
                          'Fat',
                          totalFat.toStringAsFixed(1),
                          'g',
                          const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Meals List
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meals',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            ..._meals.asMap().entries.map((entry) {
              final mealIndex = entry.key;
              final meal = entry.value as Map<String, dynamic>;
              return _buildMealCard(meal, mealIndex, isActive);
            }).toList(),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, String unit, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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
              color: color,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, int index, bool isActive) {
    final isConsumed = _isMealConsumed(index);
    final product = meal['product'] as Map<String, dynamic>? ?? {};
    final nutrition = meal['nutrition'] as Map<String, dynamic>? ?? {};
    final mealName = meal['mealName'] as String? ?? 'Meal';
    final alarmTime = meal['alarmTime'] as String? ?? meal['mealTime'] as String?;
    final quantity = (nutrition['quantity'] as num?)?.toDouble() ?? 0.0;
    final servingUnit = nutrition['servingUnit'] as String? ?? 'grams';
    final productName = product['name'] as String? ?? 'Unknown';
    final productBrand = product['brand'] as String?;
    final imageUrl = product['imageUrl'] as String?;
    final calories = (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (nutrition['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (nutrition['fat'] as num?)?.toDouble() ?? 0.0;

    return Container(
        margin: EdgeInsets.only(bottom: 16.h, left: 20.w, right: 20.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isConsumed ? Colors.grey.withOpacity(0.2) : Colors.black,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isConsumed 
                ? Colors.grey.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image
                imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 60.w,
                        height: 60.h,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.fastfood,
                            color: AppColors.primary,
                            size: 30.sp,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.fastfood,
                        color: AppColors.primary,
                        size: 30.sp,
                      ),
                    ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.ubuntu(
                        color: isConsumed 
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        decoration: isConsumed 
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (productBrand != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        productBrand,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Meal Name, Alarm time, Quantity
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  mealName,
                  style: GoogleFonts.ubuntu(
                    color: const Color(0xFF4CAF50),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (alarmTime != null && alarmTime.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alarm,
                        color: Colors.orange,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatTime12h(alarmTime),
                        style: GoogleFonts.ubuntu(
                          color: Colors.orange,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Quantity: ${quantity.toStringAsFixed(servingUnit == 'pieces' ? 0 : 1)} $servingUnit',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Nutrition Info
          Row(
            children: [
              Expanded(
                child: _buildNutritionChip('Calories', calories.toStringAsFixed(0), 'kcal'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildNutritionChip('Carbs', carbs.toStringAsFixed(1), 'g'),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildNutritionChip('Protein', protein.toStringAsFixed(1), 'g'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildNutritionChip('Fat', fat.toStringAsFixed(1), 'g'),
              ),
            ],
          ),
        ],
      ),
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
