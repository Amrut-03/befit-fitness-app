import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/shimmer_widget.dart';
import 'package:befit_fitness_app/src/home/data/services/macro_calculation_service.dart';
import 'package:befit_fitness_app/src/home/data/services/goal_service.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';

/// Screen to display user's daily macros
class DailyMacrosScreen extends StatefulWidget {
  static const String route = '/daily-macros';

  const DailyMacrosScreen({super.key});

  @override
  State<DailyMacrosScreen> createState() => _DailyMacrosScreenState();
}

class _DailyMacrosScreenState extends State<DailyMacrosScreen> {
  bool _isLoading = true;
  double? _carbs;
  double? _protein;
  double? _fat;
  double? _dailyCalories;
  String? _errorMessage;
  String? _purpose;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadMacros();
  }

  Future<void> _loadMacros() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get macros from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        
        // Try to get macros from nested structure
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final macros = profile['macros'] as Map<String, dynamic>? ?? {};
        
        // Also try flat keys for compatibility
        final carbsValue = macros['carbs'] ?? data['profile.macros.carbs'];
        final proteinValue = macros['protein'] ?? data['profile.macros.protein'];
        final fatValue = macros['fat'] ?? data['profile.macros.fat'];
        
        // Get purpose
        _purpose = profile['purpose'] ?? data['profile.purpose'];
        
        // Get daily calories from profile.calorie field
        final calorieValue = profile['calorie'] ?? data['profile.calorie'];
        if (calorieValue != null) {
          _dailyCalories = (calorieValue as num).toDouble();
        } else {
          // Fallback to GoalService if profile.calorie doesn't exist
          _dailyCalories = await GoalService.getCaloriesGoal();
        }

        if (carbsValue != null || proteinValue != null || fatValue != null) {
          setState(() {
            _carbs = carbsValue != null ? (carbsValue as num).toDouble() : null;
            _protein = proteinValue != null ? (proteinValue as num).toDouble() : null;
            _fat = fatValue != null ? (fatValue as num).toDouble() : null;
            _isLoading = false;
          });
        } else {
          // If macros don't exist, calculate and save them
          await _calculateAndLoadMacros();
        }
      } else {
        // User document doesn't exist, try to calculate
        await _calculateAndLoadMacros();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load macros: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateAndLoadMacros() async {
    try {
      // Get user profile to calculate macros
      final profileRepo = getIt<UserProfileRepository>();
      final userProfile = await profileRepo.getUserProfile(_userId);
      
      if (userProfile == null) {
        setState(() {
          _errorMessage = 'User profile not found. Please complete your profile first.';
          _isLoading = false;
        });
        return;
      }

      // Get daily calories from profile.calorie field
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final calorieValue = profile['calorie'] ?? data['profile.calorie'];
        if (calorieValue != null) {
          _dailyCalories = (calorieValue as num).toDouble();
        } else {
          // Fallback to GoalService if profile.calorie doesn't exist
          _dailyCalories = await GoalService.getCaloriesGoal();
        }
      } else {
        // Fallback to GoalService if document doesn't exist
        _dailyCalories = await GoalService.getCaloriesGoal();
      }
      
      if (_dailyCalories == null || _dailyCalories == 0) {
        setState(() {
          _errorMessage = 'Daily calories not calculated. Please set your goals first.';
          _isLoading = false;
        });
        return;
      }

      // Calculate and save macros
      final macroService = MacroCalculationService(firestore: FirebaseFirestore.instance);
      await macroService.calculateAndSaveMacros(
        userId: _userId,
        dailyCalories: _dailyCalories!,
        purpose: userProfile.purpose,
      );

      // Reload macros
      await _loadMacros();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to calculate macros: ${e.toString()}';
        _isLoading = false;
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
          'Daily Diet Goal',
          style: GoogleFonts.ubuntu(
            color: AppColors.textOnPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const ShimmerMacrosPage()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 64.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ubuntu(
                            color: AppColors.textOnPrimary,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _loadMacros,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.ubuntu(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daily Calories Card
                      if (_dailyCalories != null) ...[
                        _buildCaloriesCard(),
                        SizedBox(height: 24.h),
                      ],
                      
                      // Macros Overview
                      Text(
                        'Daily Macros',
                        style: GoogleFonts.ubuntu(
                          color: AppColors.textOnPrimary,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      // Macro Cards
                      if (_carbs != null)
                        _buildMacroCard(
                          icon: Icons.grain,
                          title: 'Carbohydrates',
                          value: _carbs!,
                          unit: 'g',
                          color: const Color(0xFF4CAF50),
                          calories: _carbs! * 4,
                        ),
                      SizedBox(height: 16.h),
                      
                      if (_protein != null)
                        _buildMacroCard(
                          icon: Icons.fitness_center,
                          title: 'Protein',
                          value: _protein!,
                          unit: 'g',
                          color: const Color(0xFF2196F3),
                          calories: _protein! * 4,
                        ),
                      SizedBox(height: 16.h),
                      
                      if (_fat != null)
                        _buildMacroCard(
                          icon: Icons.water_drop,
                          title: 'Fat',
                          value: _fat!,
                          unit: 'g',
                          color: const Color(0xFFFF9800),
                          calories: _fat! * 9,
                        ),
                      
                      SizedBox(height: 24.h),
                      
                      // Purpose/Goal Info
                      if (_purpose != null) ...[
                        _buildPurposeCard(),
                        SizedBox(height: 24.h),
                      ],
                      
                      // Info Card
                      _buildInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCaloriesCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: AppColors.primary,
                size: 32.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Daily Calories',
                style: GoogleFonts.ubuntu(
                  color: AppColors.textOnPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '${_dailyCalories!.toStringAsFixed(0)}',
            style: GoogleFonts.ubuntu(
              color: AppColors.primary,
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'kcal',
            style: GoogleFonts.ubuntu(
              color: AppColors.textOnPrimary.withOpacity(0.7),
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard({
    required IconData icon,
    required String title,
    required double value,
    required String unit,
    required Color color,
    required double calories,
  }) {
    final totalCalories = _dailyCalories ?? 1;
    final percentage = (calories / totalCalories * 100).clamp(0.0, 100.0);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ubuntu(
                        color: AppColors.textOnPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${calories.toStringAsFixed(0)} kcal (${percentage.toStringAsFixed(1)}%)',
                      style: GoogleFonts.ubuntu(
                        color: AppColors.textOnPrimary.withOpacity(0.7),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)} $unit',
                style: GoogleFonts.ubuntu(
                  color: color,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeCard() {
    String purposeText = _purpose ?? 'General Fitness';
    
    // Format purpose text for display
    purposeText = purposeText
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag,
            color: AppColors.primary,
            size: 24.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Goal',
                  style: GoogleFonts.ubuntu(
                    color: AppColors.textOnPrimary.withOpacity(0.7),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  purposeText,
                  style: GoogleFonts.ubuntu(
                    color: AppColors.textOnPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'Macros are calculated based on your daily calorie goal and fitness purpose. They are automatically updated when your goals change.',
              style: GoogleFonts.ubuntu(
                color: AppColors.textOnPrimary.withOpacity(0.7),
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

