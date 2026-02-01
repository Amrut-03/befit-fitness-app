import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/shimmer_widget.dart';
import 'package:befit_fitness_app/src/home/data/services/enhanced_goal_service.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/repositories/google_fit_repository.dart';

/// Separate page for editing daily goals
class GoalEditingPage extends StatefulWidget {
  static const String route = '/goal-editing';

  const GoalEditingPage({super.key});

  @override
  State<GoalEditingPage> createState() => _GoalEditingPageState();
}

class _GoalEditingPageState extends State<GoalEditingPage> {
  late TextEditingController _stepsController;
  late TextEditingController _caloriesController;
  late TextEditingController _moveMinController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPaused = false;
  String? _pauseReason;
  bool _isBeforeNoon = true;
  String? _errorMessage;
  String? _pauseReasonError; // Separate error for pause reason
  bool _isInitialized = false;
  Map<String, dynamic>? _currentGoals;
  Map<String, dynamic>? _smartSuggestions;
  late EnhancedGoalService _goalService;

  @override
  void initState() {
    super.initState();
    _goalService = EnhancedGoalService(firestore: FirebaseFirestore.instance);
    _stepsController = TextEditingController();
    _caloriesController = TextEditingController();
    _moveMinController = TextEditingController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final goals = await _goalService.getCurrentGoals();
      final isBeforeNoon = DateTime.now().hour < 12;

      setState(() {
        _currentGoals = goals;
        _isBeforeNoon = isBeforeNoon;
        _stepsController.text = goals['steps'].toString();
        _caloriesController.text = goals['calories'].toStringAsFixed(0);
        _moveMinController.text = goals['moveMin'].toString();
        _isInitialized = true;
      });

      // Load smart suggestions in background
      _loadSmartSuggestions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load goals: ${e.toString()}';
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadSmartSuggestions() async {
    try {
      // Get user profile for smart suggestions
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final profileRepo = getIt<UserProfileRepository>();
      final userProfile = await profileRepo.getUserProfile(userId);
      
      double? weight;
      double? height;
      int? age;
      String? gender;
      String? activityLevel;
      
      if (userProfile != null) {
        // Calculate age
        if (userProfile.dateOfBirth != null) {
          final now = DateTime.now();
          final dob = userProfile.dateOfBirth!;
          age = now.year - dob.year;
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
        }
        
        weight = userProfile.weight;
        height = userProfile.height;
        gender = userProfile.gender;
        
        // Map workoutType to activity level
        if (userProfile.workoutType != null) {
          final workoutType = userProfile.workoutType!.toLowerCase();
          if (workoutType.contains('cardio') || workoutType.contains('active')) {
            activityLevel = 'active';
          } else if (workoutType.contains('strength') || workoutType.contains('moderate')) {
            activityLevel = 'moderate';
          } else if (workoutType.contains('light') || workoutType.contains('yoga')) {
            activityLevel = 'light';
          } else if (workoutType.contains('sedentary') || workoutType.contains('none')) {
            activityLevel = 'sedentary';
          } else {
            activityLevel = 'moderate'; // Default
          }
        }
        
        // Try Google Fit if not in profile
        if (weight == null || height == null) {
          try {
            final googleFitRepo = getIt<GoogleFitRepository>();
            if (weight == null) {
              final weightResult = await googleFitRepo.getWeight();
              weightResult.fold(
                (failure) => null,
                (value) => weight = value,
              );
            }
            if (height == null) {
              final heightResult = await googleFitRepo.getHeight();
              heightResult.fold(
                (failure) => null,
                (value) => height = value != null ? value * 100 : null, // Convert meters to cm
              );
            }
          } catch (e) {
            if (kDebugMode) debugPrint('Error fetching from Google Fit: $e');
          }
        }
      }
      
      // Get current fitness data for better suggestions
      int currentSteps = 0;
      double currentCalories = 0.0;
      int? currentMoveMin;
      
      try {
        final currentGoals = await _goalService.getCurrentGoals();
        currentSteps = currentGoals['steps'] as int;
        currentCalories = currentGoals['calories'] as double;
        currentMoveMin = currentGoals['moveMin'] as int;
      } catch (e) {
        if (kDebugMode) debugPrint('Error getting current goals: $e');
      }
      
      final suggestions = await _goalService.getSmartGoalSuggestions(
        currentSteps: currentSteps,
        currentCalories: currentCalories,
        currentMoveMin: currentMoveMin,
        weight: weight,
        height: height,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        purpose: userProfile?.purpose,
        workoutType: userProfile?.workoutType,
      );
      if (mounted) {
        setState(() {
          _smartSuggestions = suggestions;
        });
      }
    } catch (e) {
      // Silently fail - smart suggestions are optional
      if (kDebugMode) debugPrint('Failed to load smart suggestions: $e');
    }
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _moveMinController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate pause reason if pause is checked
    if (_isPaused && (_pauseReason == null || _pauseReason!.isEmpty)) {
      setState(() {
        _pauseReasonError = 'Please select a reason for pausing your goal.';
        _isLoading = false;
      });
      return;
    }
    
    // Clear pause reason error if validation passes
    setState(() {
      _pauseReasonError = null;
    });

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If pause is checked, use existing goal values (don't use edited values)
      int steps;
      double calories;
      int moveMin;
      
      if (_isPaused) {
        // When pausing, always use existing goal values, not edited values
        final existingGoals = _currentGoals!;
        steps = existingGoals['steps'] as int;
        calories = existingGoals['calories'] as double;
        moveMin = existingGoals['moveMin'] as int;
      } else {
        // When not pausing, use values from text controllers
        steps = int.parse(_stepsController.text);
        calories = double.parse(_caloriesController.text);
        moveMin = int.parse(_moveMinController.text);

        // Validate only if not pausing
        final stepsError = _goalService.validateStepsGoal(steps);
        final caloriesError = _goalService.validateCaloriesGoal(calories);
        final moveMinError = _goalService.validateMoveMinGoal(moveMin);

        if (stepsError != null || caloriesError != null || moveMinError != null) {
          setState(() {
            _errorMessage = stepsError ?? caloriesError ?? moveMinError;
            _isLoading = false;
          });
          return;
        }
      }
      
      await _goalService.saveDailyGoals(
        stepCountGoalValue: steps,
        caloriesBurnGoalValue: calories,
        moveMinGoalValue: moveMin,
        isPaused: _isPaused,
        pauseReason: _isPaused ? _pauseReason : null,
        isGoalCompleted: false,
      );

      if (mounted) {
        if (_isPaused) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Goal paused successfully!',
                style: GoogleFonts.ubuntu(),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Show motivational message
          _showMotivationalSnackbar();
        }
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save goals: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applySmartSuggestion() {
    // Don't apply smart suggestion if pause is checked
    if (_isPaused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please uncheck "Pause Goal Today" to apply smart goal suggestions.',
            style: GoogleFonts.ubuntu(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (_smartSuggestions != null) {
      setState(() {
        _stepsController.text = _smartSuggestions!['steps'].toString();
        _caloriesController.text = _smartSuggestions!['calories'].toStringAsFixed(0);
        _moveMinController.text = _smartSuggestions!['moveMin'].toString();
      });
    }
  }

  /// Show motivational snackbar when goals are set
  void _showMotivationalSnackbar() {
    final hour = DateTime.now().hour;
    String greeting = '';
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning! ';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon! ';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening! ';
    } else {
      greeting = 'Good Night! ';
    }

    final messages = [
      '🎯 Your goals are set! Let\'s crush them today!',
      '💪 Ready to make today count? You\'ve got this!',
      '🚀 Goals locked in! Time to shine!',
      '⭐ Your fitness journey continues! Let\'s go!',
      '🔥 Goals updated! Time to show what you\'re made of!',
      '✨ Today is your day! Let\'s achieve greatness!',
    ];
    
    final randomMessage = messages[DateTime.now().millisecond % messages.length];
    final timeMessage = _isBeforeNoon 
        ? 'Goals updated for today!' 
        : 'Goals will be applied tomorrow!';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$greeting$randomMessage\n$timeMessage',
          style: GoogleFonts.ubuntu(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Edit Daily Goals',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const ShimmerGoalEditing(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Daily Goals',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_smartSuggestions != null)
            TextButton.icon(
              onPressed: _applySmartSuggestion,
              icon: Icon(
                Icons.lightbulb_outline, 
                color: AppColors.primary, 
                size: 18.sp,
              ),
              label: Text(
                'Smart Goal',
                style: GoogleFonts.ubuntu(
                  color: AppColors.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instruction text
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _isBeforeNoon
                            ? 'Editing before 12 PM will apply to today. After 12 PM, changes apply tomorrow.'
                            : 'Editing after 12 PM will apply to tomorrow.',
                        style: GoogleFonts.ubuntu(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.ubuntu(
                            fontSize: 11.sp,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              // Steps goal
              _buildGoalField(
                label: 'Daily Steps Goal',
                controller: _stepsController,
                icon: Icons.directions_walk,
                color: const Color(0xFF00D4AA),
                enabled: !_isPaused,
                maxLength: 5,
                validator: (value) {
                  if (_isPaused) return null; // Skip validation when paused
                  if (value == null || value.isEmpty) return 'Please enter steps goal';
                  final steps = int.tryParse(value);
                  if (steps == null) return 'Please enter a valid number';
                  final validationError = _goalService.validateStepsGoal(steps);
                  if (validationError != null) return validationError;
                  // Additional check for unrealistic values
                  if (steps > 30000) return 'Steps goal should not exceed 30,000 steps (realistic daily limit)';
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              // Calories goal
              _buildGoalField(
                label: 'Daily Calories Goal',
                controller: _caloriesController,
                icon: Icons.local_fire_department,
                color: const Color(0xFFFF6B35),
                enabled: !_isPaused,
                validator: (value) {
                  if (_isPaused) return null; // Skip validation when paused
                  if (value == null || value.isEmpty) return 'Please enter calories goal';
                  final calories = double.tryParse(value);
                  if (calories == null) return 'Please enter a valid number';
                  return _goalService.validateCaloriesGoal(calories);
                },
              ),
              SizedBox(height: 16.h),
              // Move minutes goal
              _buildGoalField(
                label: 'Daily Move Minutes Goal',
                controller: _moveMinController,
                icon: Icons.fitness_center,
                color: const Color(0xFFFF006E),
                enabled: !_isPaused,
                validator: (value) {
                  if (_isPaused) return null; // Skip validation when paused
                  if (value == null || value.isEmpty) return 'Please enter move minutes goal';
                  final moveMin = int.tryParse(value);
                  if (moveMin == null) return 'Please enter a valid number';
                  return _goalService.validateMoveMinGoal(moveMin);
                },
              ),
              SizedBox(height: 20.h),
              // Pause goal option
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
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
                        Checkbox(
                          value: _isPaused,
                          onChanged: (value) {
                            setState(() {
                              _isPaused = value ?? false;
                              if (!_isPaused) _pauseReason = null;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Text(
                            'Pause Goal Today',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isPaused) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _pauseReason,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Select Reason',
                            labelStyle: GoogleFonts.ubuntu(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13.sp,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          dropdownColor: Colors.black,
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          items: ['Sick', 'Rest Day', 'Other'].map((reason) {
                            return DropdownMenuItem(
                              value: reason.toLowerCase().replaceAll(' ', '_'),
                              child: Text(reason),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _pauseReason = value;
                              _pauseReasonError = null; // Clear error when reason is selected
                            });
                          },
                        ),
                      ),
                      // Show error message below dropdown if pause reason is not selected
                      if (_pauseReasonError != null) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  _pauseReasonError!,
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 11.sp,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              // Save button - always show, but enable based on conditions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'Save Goals',
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

  Widget _buildGoalField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    required String? Function(String?) validator,
    bool enabled = true,
    int? maxLength,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: TextInputType.number,
              enabled: enabled,
              readOnly: !enabled,
              maxLength: maxLength,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: GoogleFonts.ubuntu(
                color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '', // Hide character counter
                labelText: label,
                labelStyle: GoogleFonts.ubuntu(
                  color: enabled ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.4),
                  fontSize: 14.sp,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: enabled ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                  ),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: color, width: 2),
                ),
                errorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

