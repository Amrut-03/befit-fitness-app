import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';

/// Screen displaying detailed food product information
class FoodProductDetailsScreen extends StatelessWidget {
  static const String route = '/food-product-details';
  
  final FoodProduct product;

  const FoodProductDetailsScreen({
    super.key,
    required this.product,
  });

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
                  ],
                ),
              ),

              // Product image
              if (product.imageUrl != null)
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
                      imageUrl: product.imageUrl!,
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
                      product.name,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.brand != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        product.brand!,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white70,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                    if (product.category != null) ...[
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
                          product.category!,
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

              SizedBox(height: 30.h),

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
                          Text(
                            'Nutrition Facts',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
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
                        product.nutrition.formattedCalories,
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Protein
                      _buildNutritionRow(
                        'Protein',
                        product.nutrition.formattedProtein,
                        Icons.fitness_center,
                        Colors.blue,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Carbs
                      _buildNutritionRow(
                        'Carbohydrates',
                        product.nutrition.formattedCarbs,
                        Icons.energy_savings_leaf,
                        Colors.green,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Fat
                      _buildNutritionRow(
                        'Fat',
                        product.nutrition.formattedFat,
                        Icons.water_drop,
                        Colors.red,
                      ),
                      SizedBox(height: 16.h),
                      
                      // Fiber
                      if (product.nutrition.fiber != null)
                        _buildNutritionRow(
                          'Fiber',
                          product.nutrition.formattedFiber,
                          Icons.eco,
                          Colors.teal,
                        ),
                      if (product.nutrition.fiber != null) SizedBox(height: 16.h),
                      
                      // Sugar
                      if (product.nutrition.sugar != null)
                        _buildNutritionRow(
                          'Sugar',
                          product.nutrition.formattedSugar,
                          Icons.cake,
                          Colors.pink,
                        ),
                      if (product.nutrition.sugar != null) SizedBox(height: 16.h),
                      
                      // Sodium
                      if (product.nutrition.sodium != null)
                        _buildNutritionRow(
                          'Sodium',
                          product.nutrition.formattedSodium,
                          Icons.science,
                          Colors.purple,
                        ),
                    ],
                  ),
                ),
              ),

              // Ingredients
              if (product.ingredients != null) ...[
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
                          product.ingredients!,
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
              if (product.allergens != null && product.allergens!.isNotEmpty) ...[
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
                                product.allergens!,
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

