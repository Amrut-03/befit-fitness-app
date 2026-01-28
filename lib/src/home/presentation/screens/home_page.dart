import 'dart:async';
import 'package:befit_fitness_app/src/fitness_tracker/presentation/services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/animated_text_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activities_tile.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activity_item.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/health_metrics_chart.dart';
import 'package:befit_fitness_app/src/activity_tracking/presentation/screens/activity_tracking_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/drawer_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/discover_section.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/macros_radar_chart.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/motivation_message_widget.dart';
import 'package:confetti/confetti.dart';
import 'package:befit_fitness_app/src/home/data/services/goal_service.dart';
import 'package:befit_fitness_app/src/home/data/services/enhanced_goal_service.dart';
import 'package:befit_fitness_app/src/home/data/services/macro_calculation_service.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/goal_editing_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/diet_plan_detail_screen.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/repositories/google_fit_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Home page screen
class HomePage extends StatefulWidget {
  static const String route = '/home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  Timer? _goalCheckTimer; // Timer to check for midnight goal setting
  double _scrollOffset = 0.0;
  double _scrollStep = 400.0;
  bool _scrollingForward = true;
  int _currentNavIndex = 0;
  bool _arePermissionsGranted = false;
  bool _isCheckingPermissions = true;
  bool _hasRequestedPermissions =
      false; // Track if we've already requested permissions
  late ConfettiController _confettiController;

  // Store previous values for trend calculation
  int _previousSteps = 0;
  double _previousCalories = 0.0;
  int? _previousMoveMin;

  // Macros data
  double? _carbsGoal;
  double? _proteinGoal;
  double? _fatGoal;
  double _carbsConsumed = 0.0;
  double _proteinConsumed = 0.0;
  double _fatConsumed = 0.0;
  double _caloriesConsumed = 0.0;

  // Active diet plan
  Map<String, dynamic>? _activeDietPlan;
  bool _isLoadingActivePlan = false;
  String? _activeDietPlanId; // Track active plan ID from dailyGoal

  // Body part selector - selected body parts
  Set<Muscle> _selectedBodyParts = {};
  BodyMapController? _bodyMapController;
  bool _isFrontView = true;


  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0:
        // Already on home
        break;
      case 2:
        // Navigate to More
        // TODO: Navigate to More screen
        break;
    }
  }

  void _onCenterButtonTapped() {
    // Center button expansion is handled by CustomBottomNavBar
    // This can be used for additional actions if needed
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _startAutoScroll();
    _startGoalCheckTimer();
    _checkPermissions();
    _checkAndAutoCalculateGoals();
    // Load macros data
    _loadMacrosData();
    // Load consumed macros using the same function as bottom sheet to ensure consistency
    _loadMacrosForBottomSheet();
    // Load active diet plan
    _loadActiveDietPlan();

    // Set up a listener to refresh consumed macros when returning to this screen
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Fetch home data first - fitness data will be fetched automatically via BlocListener
        context.read<HomeBloc>().add(FetchHomeDataEvent(_userId));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check permissions when returning from permissions screen (but don't auto-request again)
    if (!_hasRequestedPermissions) {
      _checkPermissions();
    }
    // Initialize body map controller if not already initialized
    _bodyMapController ??= BodyMapController(
      initialSelectedMuscles: _selectedBodyParts,
      initialIsFront: _isFrontView,
    );
    _bodyMapController!.addListener(() {
      if (mounted) {
        setState(() {
          _selectedBodyParts = _bodyMapController!.selectedMuscles;
          _isFrontView = _bodyMapController!.isFront;
        });
      }
    });
    // Refresh consumed macros and active diet plan when returning to this screen
    // This ensures data is up-to-date when navigating back from other screens
    _loadActiveDietPlan();
    _loadMacrosForBottomSheet();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadActiveDietPlan();
      _loadMacrosForBottomSheet();
    }
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final permissionService = PermissionService();
      final areGranted = await permissionService.areAllPermissionsGranted();

      if (mounted) {
        setState(() {
          _arePermissionsGranted = areGranted;
          _isCheckingPermissions = false;
        });

        // If permissions are not granted, automatically request them (only once)
        if (!areGranted && !_hasRequestedPermissions) {
          _hasRequestedPermissions = true;

          // Request Android permissions (this will show system dialog)
          await permissionService.requestAndroidPermissions();

          // Recheck after requesting
          final recheckGranted = await permissionService
              .areAllPermissionsGranted();
          if (mounted) {
            setState(() {
              _arePermissionsGranted = recheckGranted;
            });

            // If Android permissions are granted but Google Fit is not, request it
            if (recheckGranted) {
              await permissionService.requestGoogleFitPermissions();
              // Final check
              final finalCheck = await permissionService
                  .areAllPermissionsGranted();
              if (mounted) {
                setState(() {
                  _arePermissionsGranted = finalCheck;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _arePermissionsGranted = false;
          _isCheckingPermissions = false;
        });
      }
    }
  }

  void _startGoalCheckTimer() {
    // Check immediately on app start
    _checkAndAutoCalculateGoals();

    // Then check every minute to catch midnight
    _goalCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _checkAndAutoCalculateGoals();
      }
    });
  }

  Future<void> _checkAndAutoCalculateGoals() async {
    try {
      final goalService = EnhancedGoalService(
        firestore: FirebaseFirestore.instance,
      );
      final now = DateTime.now();
      final todayDateString = _getTodayDateString();
      final prefs = await SharedPreferences.getInstance();

      final lastAutoCalcDate = prefs.getString('last_auto_calc_date');

      // Check if it's a new day (different date than last auto-calc)
      final isNewDay = lastAutoCalcDate != todayDateString;

      // Check today's document in Firestore
      final todayDoc = await goalService.firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(todayDateString)
          .get();

      bool shouldCalculate = false;

      if (isNewDay) {
        // It's a new day - check if today's document exists
        if (!todayDoc.exists) {
          // No document for today - need to calculate
          shouldCalculate = true;
          debugPrint(
            'Auto goal: New day detected, no document exists - calculating goals',
          );
        } else {
          // Document exists - check if it has default values
          final existingData = todayDoc.data()!;
          final existingCalories =
              (existingData['caloriesBurnGoalValue'] as num?)?.toDouble() ??
              2000.0;
          final existingSteps =
              (existingData['stepCountGoalValue'] as num?)?.toInt() ?? 10000;
          final existingMoveMin =
              (existingData['moveMinGoalValue'] as num?)?.toInt() ?? 30;

          // If goals are defaults, recalculate from user data
          if (existingCalories == 2000.0 &&
              existingSteps == 10000 &&
              existingMoveMin == 30) {
            shouldCalculate = true;
            debugPrint(
              'Auto goal: New day detected, document has default values - recalculating from user data',
            );
          } else {
            // Document exists with non-default values - ensure completion fields exist and reset them
            await goalService.firestore
                .collection('users')
                .doc(_userId)
                .collection('dailyGoals')
                .doc(todayDateString)
                .set({
                  'stepCountCompleted': 0,
                  'caloriesBurnt': 0.0,
                  'moveMinCompleted': 0,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

            await prefs.setInt('daily_steps_goal', existingSteps);
            await prefs.setDouble('daily_calories_goal', existingCalories);
            await prefs.setInt('daily_move_min_goal', existingMoveMin);
            debugPrint(
              'Auto goal: New day detected, loading existing non-default goals and resetting completion values',
            );
          }
        }
      } else {
        // Same day - just load existing goals if document exists
        if (todayDoc.exists) {
          final existingData = todayDoc.data()!;
          await prefs.setInt(
            'daily_steps_goal',
            (existingData['stepCountGoalValue'] as num?)?.toInt() ?? 10000,
          );
          await prefs.setDouble(
            'daily_calories_goal',
            (existingData['caloriesBurnGoalValue'] as num?)?.toDouble() ??
                2000.0,
          );
          await prefs.setInt(
            'daily_move_min_goal',
            (existingData['moveMinGoalValue'] as num?)?.toInt() ?? 30,
          );
        }
      }

      if (shouldCalculate) {
        // Reset goals for new day first
        await _resetGoalsForNewDay(goalService, todayDateString);
        // Calculate and save goals from user data (weight, height, activity, purpose)
        await _autoCalculateAndSaveGoals(goalService);
        // Update last auto-calc date
        await prefs.setString('last_auto_calc_date', todayDateString);
        debugPrint('Auto goal: Goals calculated and saved to backend');
      }
    } catch (e) {
      debugPrint('Error in auto-calculate goals: $e');
    }
  }

  Future<void> _resetGoalsForNewDay(
    EnhancedGoalService goalService,
    String dateString,
  ) async {
    try {
      // Calculate goals dynamically from user's actual profile data
      final profileRepo = getIt<UserProfileRepository>();
      final userProfile = await profileRepo.getUserProfile(_userId);

      int stepCountGoal = 10000; // Default fallback
      double caloriesGoal = 2000.0; // Default fallback
      int moveMinGoal = 30; // Default fallback

      if (userProfile != null &&
          userProfile.dateOfBirth != null &&
          userProfile.gender != null) {
        // Calculate age
        final now = DateTime.now();
        final dob = userProfile.dateOfBirth!;
        int age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }

        double? weight = userProfile.weight;
        double? height = userProfile.height;

        // Try to get weight and height from Google Fit if not in profile
        if (weight == null || height == null) {
          try {
            final googleFitRepo = getIt<GoogleFitRepository>();
            if (weight == null) {
              final weightResult = await googleFitRepo.getWeight();
              weightResult.fold((failure) => null, (value) => weight = value);
            }
            if (height == null) {
              final heightResult = await googleFitRepo.getHeight();
              heightResult.fold(
                (failure) => null,
                (value) => height = value != null ? value * 100 : null,
              );
            }
          } catch (e) {
            debugPrint('Error fetching from Google Fit: $e');
          }
        }

        if (weight != null && height != null) {
          // Determine activity level from workout type
          String? activityLevel;
          if (userProfile.workoutType != null) {
            final workoutType = userProfile.workoutType!.toLowerCase();
            if (workoutType.contains('cardio') ||
                workoutType.contains('active')) {
              activityLevel = 'active';
            } else if (workoutType.contains('strength') ||
                workoutType.contains('moderate')) {
              activityLevel = 'moderate';
            } else if (workoutType.contains('light') ||
                workoutType.contains('yoga')) {
              activityLevel = 'light';
            } else if (workoutType.contains('sedentary') ||
                workoutType.contains('none')) {
              activityLevel = 'sedentary';
            }
          }

          final finalActivityLevel = activityLevel ?? 'moderate';

          // Calculate calories from user health data
          final calculatedCalories =
              GoalService.calculateCaloriesFromHealthData(
                weight: weight!,
                height: height!,
                age: age,
                gender: userProfile.gender!,
                activityLevel: finalActivityLevel,
              );

          if (calculatedCalories > 0) {
            caloriesGoal = calculatedCalories;
            final calculatedSteps = GoalService.calculateStepsFromCalories(
              calculatedCalories,
            );
            stepCountGoal = calculatedSteps > 0 ? calculatedSteps : 10000;
            moveMinGoal = 30; // Standard move minutes goal
          }
        }
      }

      // Reset goals with calculated values and initialize completion tracking
      await goalService.firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .set({
            'stepCountGoalValue': stepCountGoal,
            'caloriesBurnGoalValue': caloriesGoal,
            'moveMinGoalValue': moveMinGoal,
            'targetDate': dateString,
            'isPaused': false,
            'pauseReason': null,
            'isGoalCompleted': false,
            // Initialize completion tracking fields to 0 at midnight
            'stepCountCompleted': 0,
            'caloriesBurnt': 0.0,
            'moveMinCompleted': 0,
            // Reset dietPlanId to null at midnight (new day)
            'dietPlanId': null,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'resetAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Update SharedPreferences with calculated values
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_steps_goal', stepCountGoal);
      await prefs.setDouble('daily_calories_goal', caloriesGoal);
      await prefs.setInt('daily_move_min_goal', moveMinGoal);
    } catch (e) {
      debugPrint('Error resetting goals: $e');
    }
  }

  Future<void> _autoCalculateAndSaveGoals(
    EnhancedGoalService goalService,
  ) async {
    try {
      final profileRepo = getIt<UserProfileRepository>();
      final userProfile = await profileRepo.getUserProfile(_userId);

      if (userProfile == null ||
          userProfile.dateOfBirth == null ||
          userProfile.gender == null) {
        return;
      }

      final now = DateTime.now();
      final dob = userProfile.dateOfBirth!;
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      double? weight = userProfile.weight;
      double? height = userProfile.height;

      if (weight == null || height == null) {
        try {
          final googleFitRepo = getIt<GoogleFitRepository>();
          if (weight == null) {
            final weightResult = await googleFitRepo.getWeight();
            weightResult.fold((failure) => null, (value) => weight = value);
          }
          if (height == null) {
            final heightResult = await googleFitRepo.getHeight();
            heightResult.fold(
              (failure) => null,
              (value) => height = value != null ? value * 100 : null,
            );
          }
        } catch (e) {
          debugPrint('Error fetching from Google Fit: $e');
        }
      }

      if (weight == null || height == null) {
        return;
      }

      String? activityLevel;
      if (userProfile.workoutType != null) {
        final workoutType = userProfile.workoutType!.toLowerCase();
        if (workoutType.contains('cardio') || workoutType.contains('active')) {
          activityLevel = 'active';
        } else if (workoutType.contains('strength') ||
            workoutType.contains('moderate')) {
          activityLevel = 'moderate';
        } else if (workoutType.contains('light') ||
            workoutType.contains('yoga')) {
          activityLevel = 'light';
        } else if (workoutType.contains('sedentary') ||
            workoutType.contains('none')) {
          activityLevel = 'sedentary';
        }
      }

      final finalActivityLevel = activityLevel ?? 'moderate';

      final calculatedCalories = GoalService.calculateCaloriesFromHealthData(
        weight: weight!,
        height: height!,
        age: age,
        gender: userProfile.gender!,
        activityLevel: finalActivityLevel,
      );

      if (calculatedCalories > 0) {
        final calculatedSteps = GoalService.calculateStepsFromCalories(
          calculatedCalories,
        );
        final calculatedMoveMin = 30;

        await goalService.saveDailyGoals(
          stepCountGoalValue: calculatedSteps > 0 ? calculatedSteps : 10000,
          caloriesBurnGoalValue: calculatedCalories,
          moveMinGoalValue: calculatedMoveMin,
          isPaused: false,
          isGoalCompleted: false,
        );

        // Calculate and save macros based on daily calories and purpose
        try {
          final macroService = MacroCalculationService(
            firestore: FirebaseFirestore.instance,
          );
          await macroService.calculateAndSaveMacros(
            userId: _userId,
            dailyCalories: calculatedCalories,
            purpose: userProfile.purpose,
          );
        } catch (e) {
          debugPrint('Error calculating and saving macros: $e');
        }

        if (mounted) {
          _showMotivationalSnackbar();
        }
      }
    } catch (e) {
      debugPrint('Error auto-calculating goals: $e');
    }
  }

  /// Show motivational snackbar when goals are auto-calculated or set
  void _showMotivationalSnackbar() {
    final messages = [
      '🎯 Your daily goals are set! Let\'s crush them today!',
      '💪 Ready to make today count? Your goals are waiting!',
      '🚀 New day, new goals! Time to shine!',
      '⭐ Your fitness journey starts now! Let\'s go!',
      '🔥 Goals are set! Time to show what you\'re made of!',
      '✨ Today is your day! Let\'s achieve greatness!',
    ];

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

    final randomMessage =
        messages[DateTime.now().millisecond % messages.length];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$greeting$randomMessage',
          style: GoogleFonts.ubuntu(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _goalCheckTimer?.cancel();
    _scrollController.dispose();
    _confettiController.dispose();
    _bodyMapController?.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;

        if (_scrollOffset >= maxScrollExtent) {
          _scrollingForward = false;
        } else if (_scrollOffset <= 0) {
          _scrollingForward = true;
        }

        _scrollOffset += _scrollingForward ? _scrollStep : -_scrollStep;
        _scrollOffset = _scrollOffset.clamp(0.0, maxScrollExtent);

        _scrollController.animateTo(
          _scrollOffset,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showDailyDietGoalBottomSheet(BuildContext context) {
    // The bottom sheet's FutureBuilder will call _loadMacrosForBottomSheet()
    // which already loads consumed macros, so no need to call it here separately
    showModalBottomSheet(
      backgroundColor: Colors.black,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Container(
          height: screenHeight * 0.8,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _loadMacrosForBottomSheet(),
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;
              final macros = snapshot.data ?? {};
              final carbs = macros['carbs'] as double?;
              final protein = macros['protein'] as double?;
              final fat = macros['fat'] as double?;
              final dailyCalories = macros['dailyCalories'] as double?;
              final purpose = macros['purpose'] as String?;
              final carbsConsumed = macros['carbsConsumed'] as double? ?? 0.0;
              final proteinConsumed =
                  macros['proteinConsumed'] as double? ?? 0.0;
              final fatConsumed = macros['fatConsumed'] as double? ?? 0.0;
              final caloriesConsumed =
                  macros['caloriesConsumed'] as double? ?? 0.0;
              final errorMessage = snapshot.hasError
                  ? snapshot.error.toString()
                  : null;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20.w,
                  right: 20.w,
                  top: 12.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Diet Goal',
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          onPressed: () =>
                              Navigator.of(bottomSheetContext).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    if (isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (errorMessage != null)
                      Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 64.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Daily Calories Card
                              if (dailyCalories != null) ...[
                                _buildCaloriesCardForBottomSheet(
                                  dailyCalories,
                                  caloriesConsumed,
                                ),
                                SizedBox(height: 24.h),
                              ],

                              // Macros Overview
                              Text(
                                'Daily Macros',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // Macro Cards
                              if (carbs != null)
                                _buildMacroCardForBottomSheet(
                                  icon: Icons.grain,
                                  title: 'Carbohydrates',
                                  value: carbs,
                                  consumed: carbsConsumed,
                                  unit: 'g',
                                  color: const Color(0xFF4CAF50),
                                  calories: carbs * 4,
                                  dailyCalories: dailyCalories ?? 1,
                                ),
                              if (carbs != null) SizedBox(height: 16.h),

                              if (protein != null)
                                _buildMacroCardForBottomSheet(
                                  icon: Icons.fitness_center,
                                  title: 'Protein',
                                  value: protein,
                                  consumed: proteinConsumed,
                                  unit: 'g',
                                  color: const Color(0xFF2196F3),
                                  calories: protein * 4,
                                  dailyCalories: dailyCalories ?? 1,
                                ),
                              if (protein != null) SizedBox(height: 16.h),

                              if (fat != null)
                                _buildMacroCardForBottomSheet(
                                  icon: Icons.water_drop,
                                  title: 'Fat',
                                  value: fat,
                                  consumed: fatConsumed,
                                  unit: 'g',
                                  color: const Color(0xFFFF9800),
                                  calories: fat * 9,
                                  dailyCalories: dailyCalories ?? 1,
                                ),

                              if (fat != null) SizedBox(height: 24.h),

                              // Purpose/Goal Info
                              if (purpose != null) ...[
                                _buildPurposeCardForBottomSheet(purpose),
                                SizedBox(height: 24.h),
                              ],

                              // Info Card
                              _buildInfoCardForBottomSheet(),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadMacrosForBottomSheet() async {
    try {
      final userId = _userId;
      if (userId.isEmpty) {
        return {
          'error': 'User not logged in',
          'carbsConsumed': 0.0,
          'proteinConsumed': 0.0,
          'fatConsumed': 0.0,
          'caloriesConsumed': 0.0,
        };
      }

      // Load consumed macros FIRST to ensure we have the latest values
      await _loadConsumedMacros();

      // Get macros from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        return {
          'error': 'User document not found',
          'carbsConsumed': _carbsConsumed,
          'proteinConsumed': _proteinConsumed,
          'fatConsumed': _fatConsumed,
          'caloriesConsumed': _caloriesConsumed,
        };
      }

      final data = docSnapshot.data()!;

      // Try to get macros from nested structure
      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      final macros = profile['macros'] as Map<String, dynamic>? ?? {};

      // Also try flat keys for compatibility
      final carbsValue = macros['carbs'] ?? data['profile.macros.carbs'];
      final proteinValue = macros['protein'] ?? data['profile.macros.protein'];
      final fatValue = macros['fat'] ?? data['profile.macros.fat'];

      // Get purpose
      final purpose = profile['purpose'] ?? data['profile.purpose'];

      // Get daily calories from profile.calorie field
      final calorieValue = profile['calorie'] ?? data['profile.calorie'];
      double? dailyCalories;
      if (calorieValue != null) {
        dailyCalories = (calorieValue as num).toDouble();
      } else {
        // Fallback to GoalService if profile.calorie doesn't exist
        dailyCalories = await GoalService.getCaloriesGoal();
      }

      // Return with current consumed values (already loaded above)
      return {
        'carbs': carbsValue != null ? (carbsValue as num).toDouble() : null,
        'protein': proteinValue != null
            ? (proteinValue as num).toDouble()
            : null,
        'fat': fatValue != null ? (fatValue as num).toDouble() : null,
        'dailyCalories': dailyCalories,
        'purpose': purpose,
        'carbsConsumed': _carbsConsumed,
        'proteinConsumed': _proteinConsumed,
        'fatConsumed': _fatConsumed,
        'caloriesConsumed': _caloriesConsumed,
      };
    } catch (e) {
      debugPrint('Error loading macros for bottom sheet: $e');
      return {
        'error': 'Failed to load macros: ${e.toString()}',
        'carbsConsumed': 0.0,
        'proteinConsumed': 0.0,
        'fatConsumed': 0.0,
        'caloriesConsumed': 0.0,
      };
    }
  }

  Widget _buildCaloriesCardForBottomSheet(
    double dailyCalories,
    double caloriesConsumed,
  ) {
    final percentage = dailyCalories > 0
        ? (caloriesConsumed / dailyCalories * 100).clamp(0.0, 100.0)
        : 0.0;
    final isOverGoal = caloriesConsumed > dailyCalories;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary, width: 2),
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
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '${caloriesConsumed.toStringAsFixed(0)} / ${dailyCalories.toStringAsFixed(0)}',
            style: GoogleFonts.ubuntu(
              color: isOverGoal ? Colors.red : AppColors.primary,
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'kcal',
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverGoal ? Colors.red : AppColors.primary,
              ),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCardForBottomSheet({
    required IconData icon,
    required String title,
    required double value,
    required double consumed,
    required String unit,
    required Color color,
    required double calories,
    required double dailyCalories,
  }) {
    final consumedCalories = title == 'Fat' ? consumed * 9 : consumed * 4;
    final percentage = dailyCalories > 0
        ? (consumedCalories / dailyCalories * 100).clamp(0.0, 100.0)
        : 0.0;
    final macroPercentage = value > 0
        ? (consumed / value * 100).clamp(0.0, 100.0)
        : 0.0;
    final isOverGoal = consumed > value;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${consumedCalories.toStringAsFixed(0)} kcal (${percentage.toStringAsFixed(1)}%)',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${consumed.toStringAsFixed(1)} / ${value.toStringAsFixed(0)}',
                    style: GoogleFonts.ubuntu(
                      color: isOverGoal ? Colors.red : color,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: GoogleFonts.ubuntu(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: macroPercentage / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverGoal ? Colors.red : color,
              ),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${macroPercentage.toStringAsFixed(0)}% of goal',
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeCardForBottomSheet(String purpose) {
    String purposeText = purpose;

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
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: AppColors.primary, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Goal',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  purposeText,
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
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

  Widget _buildInfoCardForBottomSheet() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'Macros are calculated based on your daily calorie goal and fitness purpose. They are automatically updated when your goals change.',
              style: GoogleFonts.ubuntu(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthEducationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.black,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20.w,
            right: 20.w,
            top: 12.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'About Health Metrics',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              _buildEducationItem(
                context,
                icon: Icons.directions_walk,
                title: 'Steps Count',
                description:
                    'Track your daily steps to monitor your physical activity. The inner ring (teal) shows your progress toward your daily step goal.',
                color: const Color(0xFF00D4AA),
              ),
              SizedBox(height: 16.h),
              _buildEducationItem(
                context,
                icon: Icons.local_fire_department,
                title: 'Calories Burn',
                description:
                    'Monitor calories burned through physical activity. The middle ring (orange) displays your progress toward your daily calorie burn goal.',
                color: const Color(0xFFFF6B35),
              ),
              SizedBox(height: 16.h),
              _buildEducationItem(
                context,
                icon: Icons.fitness_center,
                title: 'Move Minutes',
                description:
                    'Track active minutes throughout the day. The outer ring (pink) shows how close you are to meeting your daily move minutes goal.',
                color: const Color(0xFFFF006E),
              ),
              SizedBox(height: 20.h),
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
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Tap the rings to view detailed metrics and progress.',
                        style: GoogleFonts.ubuntu(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEducationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  description,
                  style: GoogleFonts.ubuntu(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthMetricsBottomSheet(
    BuildContext parentContext,
    HomeLoaded state, {
    required double stepsPercentage,
    required double caloriesPercentage,
    required double moveMinPercentage,
    required int steps,
    required double calories,
    int? moveMin,
    String? previousSteps,
    String? previousCalories,
    String? previousMoveMin,
  }) {
    showModalBottomSheet(
      backgroundColor: Colors.black,
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadGoalsForBottomSheet(),
          builder: (context, snapshot) {
            final goals = snapshot.data ?? {};
            final stepsGoal = goals['steps'] as int? ?? 10000;
            final caloriesGoal = goals['calories'] as double? ?? 2000.0;
            final moveMinGoal = goals['moveMin'] as int? ?? 30;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 12.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Health Metrics',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            // Close current bottom sheet
                            Navigator.of(bottomSheetContext).pop();
                            // Navigate to goal editing page and refresh on return
                            // Use parentContext which is passed to the method
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted && parentContext.mounted) {
                                parentContext.push(GoalEditingPage.route).then((
                                  result,
                                ) {
                                  // Refresh goals when returning from goal editing page
                                  if (result == true && mounted) {
                                    setState(() {});
                                  }
                                });
                              }
                            });
                          },
                          icon: Icon(
                            Icons.edit,
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                          label: Text(
                            'Edit Goals',
                            style: GoogleFonts.ubuntu(
                              color: AppColors.primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _buildMetricItem(
                    context,
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    value: _formatNumber(steps),
                    goal: _formatNumber(stepsGoal),
                    percentage: stepsPercentage,
                    color: const Color(0xFF00D4AA),
                    previousValue: previousSteps,
                  ),
                  SizedBox(height: 16.h),
                  _buildMetricItem(
                    context,
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '${calories.toStringAsFixed(0)} kcal',
                    goal: '${caloriesGoal.toStringAsFixed(0)} kcal',
                    percentage: caloriesPercentage,
                    color: const Color(0xFFFF6B35),
                    previousValue: previousCalories,
                  ),
                  if (moveMin != null) ...[
                    SizedBox(height: 16.h),
                    _buildMetricItem(
                      context,
                      icon: Icons.fitness_center,
                      label: 'Move Minutes',
                      value: '$moveMin min',
                      goal: '$moveMinGoal min',
                      percentage: moveMinPercentage,
                      color: const Color(0xFFFF006E),
                      previousValue: previousMoveMin,
                    ),
                  ],
                  SizedBox(height: 50.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadGoalsForBottomSheet() async {
    try {
      final goalService = EnhancedGoalService(
        firestore: FirebaseFirestore.instance,
      );
      return await goalService.getCurrentGoals();
    } catch (e) {
      // Fallback to default goals if service fails
      return {'steps': 10000, 'calories': 2000.0, 'moveMin': 30};
    }
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double percentage,
    required Color color,
    String? previousValue,
    String? goal,
  }) {
    final hasPositiveTrend =
        previousValue != null && _calculateTrend(value, previousValue);

    return Container(
      padding: EdgeInsets.all(30.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (previousValue != null) ...[
                      SizedBox(width: 8.w),
                      Icon(
                        hasPositiveTrend
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16.sp,
                        color: hasPositiveTrend ? Colors.green : Colors.red,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (goal != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Goal: $goal',
                    style: GoogleFonts.ubuntu(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6.h,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${percentage.toStringAsFixed(0)}% of goal',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _calculateTrend(String current, String previous) {
    try {
      final currentValue = _parseValue(current);
      final previousValue = _parseValue(previous);
      return currentValue > previousValue;
    } catch (e) {
      return false;
    }
  }

  double _parseValue(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildQuickSelectButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.ubuntu(
            color: AppColors.primary,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Build vertical scrollable muscle picker
  Widget _buildMusclePicker() {
    if (_bodyMapController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get all available muscles
    final allMuscles = Muscle.values;
    
    // Group muscles by category for better organization
    final frontMuscles = allMuscles.where((m) => 
      m == Muscle.chestLeft || m == Muscle.chestRight ||
      m == Muscle.deltsLeft || m == Muscle.deltsRight ||
      m == Muscle.bicepsLeft || m == Muscle.bicepsRight ||
      m == Muscle.tricepsLeft || m == Muscle.tricepsRight ||
      m == Muscle.forearmsLeft || m == Muscle.forearmsRight ||
      m == Muscle.abs ||
      m == Muscle.quadsLeft || m == Muscle.quadsRight ||
      m == Muscle.calvesLeft || m == Muscle.calvesRight ||
      m == Muscle.trapsLeft || m == Muscle.trapsRight
    ).toList();
    
    final backMuscles = allMuscles.where((m) =>
      m == Muscle.latsBackLeft || m == Muscle.latsBackRight ||
      m == Muscle.lowerLatsBackLeft || m == Muscle.lowerLatsBackRight ||
      m == Muscle.glutesLeft || m == Muscle.glutesRight ||
      m == Muscle.hamstringsLeft || m == Muscle.hamstringsRight
    ).toList();

    return AnimatedBuilder(
      animation: _bodyMapController!,
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          children: [
            // Front muscles section
            if (_bodyMapController!.isFront) ...[
              _buildMuscleSection('Front Muscles', frontMuscles),
            ] else ...[
              // Back muscles section
              _buildMuscleSection('Back Muscles', backMuscles),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMuscleSection(String title, List<Muscle> muscles) {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
            title,
                  style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ...muscles.map((muscle) {
          final isSelected = _bodyMapController!.isSelected(muscle);
          final isDisabled = _bodyMapController!.isDisabled(muscle);
          
          return Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: GestureDetector(
              onTap: () {
                _bodyMapController!.toggleMuscle(muscle);
              },
              onLongPress: () {
                // Long press to disable/enable
                if (isDisabled) {
                  _bodyMapController!.enableMuscle(muscle);
                } else {
                  _bodyMapController!.disableMuscle(muscle);
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.withOpacity(0.2)
                      : isSelected
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                    color: isDisabled
                        ? Colors.grey.withOpacity(0.3)
                        : isSelected
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.1),
                    width: 1,
                          ),
                        ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        muscle.displayName,
                            style: GoogleFonts.ubuntu(
                          color: isDisabled
                              ? Colors.grey
                              : isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                          fontSize: 11.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                    if (isDisabled)
                      Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 14.sp,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Maps Muscle enum to ExerciseDB API body part strings
  String? _muscleToBodyPart(Muscle muscle) {
    switch (muscle) {
      // Chest muscles
      case Muscle.chestLeft:
      case Muscle.chestRight:
        return 'chest';
      
      // Shoulder muscles
      case Muscle.deltsLeft:
      case Muscle.deltsRight:
      case Muscle.trapsLeft:
      case Muscle.trapsRight:
        return 'shoulders';
      
      // Arm muscles
      case Muscle.bicepsLeft:
      case Muscle.bicepsRight:
      case Muscle.tricepsLeft:
      case Muscle.tricepsRight:
      case Muscle.forearmsLeft:
      case Muscle.forearmsRight:
        return 'upper arms';
      
      // Back muscles
      case Muscle.latsBackLeft:
      case Muscle.latsBackRight:
      case Muscle.lowerLatsBackLeft:
      case Muscle.lowerLatsBackRight:
        return 'back';
      
      // Core/abs
      case Muscle.abs:
        return 'waist';
      
      // Leg muscles
      case Muscle.quadsLeft:
      case Muscle.quadsRight:
      case Muscle.hamstringsLeft:
      case Muscle.hamstringsRight:
      case Muscle.calvesLeft:
      case Muscle.calvesRight:
        return 'upper legs';
      
      // Glutes
      case Muscle.glutesLeft:
      case Muscle.glutesRight:
        return 'upper legs'; // Glutes are part of upper legs in ExerciseDB
      
      default:
        return null;
    }
  }

  /// Gets the most common body part from selected muscles
  String? _getPrimaryBodyPart(Set<Muscle> muscles) {
    if (muscles.isEmpty) return null;
    
    // Count occurrences of each body part
    final bodyPartCounts = <String, int>{};
    for (final muscle in muscles) {
      final bodyPart = _muscleToBodyPart(muscle);
      if (bodyPart != null) {
        bodyPartCounts[bodyPart] = (bodyPartCounts[bodyPart] ?? 0) + 1;
      }
    }
    
    if (bodyPartCounts.isEmpty) return null;
    
    // Return the most common body part
    return bodyPartCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  void _navigateToWorkoutScreen() {
    if (_selectedBodyParts.isEmpty) return;
    
    final primaryBodyPart = _getPrimaryBodyPart(_selectedBodyParts);
    if (primaryBodyPart == null) {
      // Show error if no valid body part found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select valid muscles',
            style: GoogleFonts.ubuntu(),
          ),
          backgroundColor: Colors.red,
          ),
        );
      return;
    }
    
    // Navigate to workout screen with body part filter
    context.push(
      '/workout-list?bodyPart=$primaryBodyPart',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is Unauthenticated) {
              // Navigate to login page when user logs out
              context.go(LoginPage.route);
            }
          },
        ),
      ],
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          // Automatically fetch weekly fitness data when HomeLoaded is first emitted
          // Today's fitness data is already fetched in parallel with home data
          if (state is HomeLoaded &&
              state.weeklyFitnessData.isEmpty &&
              !state.isFetchingWeeklyData) {
            // Fetch weekly data for charts (less critical, can load in background)
            context.read<HomeBloc>().add(const FetchWeeklyFitnessDataEvent());
          }

          // Update goal completion values when fitness data changes
          if (state is HomeLoaded && state.fitnessData != null) {
            final fitnessData = state.fitnessData!;
            _updateGoalCompletion(
              steps: fitnessData.steps!,
              calories: fitnessData.calories!,
              moveMin: fitnessData.moveMin,
            );
          }
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return RefreshIndicator(
              backgroundColor: AppColors.primary,
              color: Colors.black,
              onRefresh: () async {
                if (mounted) {
                  context.read<HomeBloc>().add(RefreshHomeDataEvent(_userId));
                  context.read<HomeBloc>().add(const FetchFitnessDataEvent());
                  context.read<HomeBloc>().add(
                    const FetchWeeklyFitnessDataEvent(),
                  );
                  // Refresh consumed macros and radar chart
                  await _loadConsumedMacros();
                }
              },
              child: Scaffold(
                backgroundColor: AppColors.background,
                drawer: state is HomeLoaded ? HomeDrawer(state: state) : null,
                bottomNavigationBar: state is HomeLoaded
                    ? CustomBottomNavBar(
                        currentIndex: _currentNavIndex,
                        onTap: _onNavItemTapped,
                        onCenterButtonTap: _onCenterButtonTapped,
                      )
                    : null,
                body: Stack(
                  children: [
                    if (state is HomeLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    else if (state is HomeError)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${state.message}',
                              style: GoogleFonts.ubuntu(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            ElevatedButton(
                              onPressed: () {
                                if (mounted) {
                                  context.read<HomeBloc>().add(
                                    FetchHomeDataEvent(_userId),
                                  );
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (state is HomeLoaded)
                      _buildHomeContent(context, state)
                    else
                      const SizedBox.shrink(),
                    // Confetti overlay
                    if (state is HomeLoaded)
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: 1.5708, // Down
                          maxBlastForce: 5,
                          minBlastForce: 2,
                          emissionFrequency: 0.05,
                          numberOfParticles: 50,
                          gravity: 0.1,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
    final fitnessData = state.fitnessData;
    final steps = fitnessData?.steps ?? 0;
    final calories = fitnessData?.calories ?? 0.0;
    final moveMin = fitnessData?.moveMin;

    // Load goals from service
    return FutureBuilder<Map<String, double>>(
      future: _loadGoals(state),
      builder: (context, snapshot) {
        final stepsGoal = snapshot.data?['steps'] ?? 10000.0;
        final caloriesGoal = snapshot.data?['calories'] ?? 2000.0;
        final moveMinGoal = snapshot.data?['moveMin'] ?? 30.0;

        final stepsPercentage = (steps / stepsGoal * 100).clamp(0.0, 100.0);
        final caloriesPercentage = (calories / caloriesGoal * 100).clamp(
          0.0,
          100.0,
        );
        final moveMinPercentage =
            (moveMin != null ? (moveMin / moveMinGoal * 100) : 0.0).clamp(
              0.0,
              100.0,
            );

        // Update previous values for trend calculation
        final previousSteps = _previousSteps;
        final previousCalories = _previousCalories;
        final previousMoveMin = _previousMoveMin;

        _previousSteps = steps;
        _previousCalories = calories;
        _previousMoveMin = moveMin;

        return Padding(
          padding: EdgeInsets.all(20.w),
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      const AnimatedTextWidget(),
                      SizedBox(height: 20.h),
                      // Body Part Selector - Interactive muscle selection
                      Container(
                        padding: EdgeInsets.all(16.w),
                        margin: EdgeInsets.only(bottom: 20.h),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Body Chart',
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // Selection header with count, clear button, and search workout button
                            AnimatedBuilder(
                              animation: _bodyMapController!,
                              builder: (context, _) {
                                if (_bodyMapController == null) return const SizedBox.shrink();
                                return _selectedBodyParts.isNotEmpty
                                    ? Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                            margin: EdgeInsets.only(bottom: 8.h),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8.r),
                                              border: Border.all(
                                                color: AppColors.primary.withOpacity(0.5),
                                                width: 1,
                              ),
                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                            Text(
                                                  'Selected: ${_selectedBodyParts.length} muscle${_selectedBodyParts.length == 1 ? '' : 's'}',
                              style: GoogleFonts.ubuntu(
                                                    color: AppColors.primary,
                                fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                GestureDetector(
                                  onTap: () {
                                                    _bodyMapController!.clearSelection();
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius: BorderRadius.circular(4.r),
                                                    ),
                                                    child: Text(
                                                      'Clear',
                                                      style: GoogleFonts.ubuntu(
                                                        color: Colors.black,
                                                        fontSize: 10.sp,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Search Workout button
                                          GestureDetector(
                                            onTap: _navigateToWorkoutScreen,
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(vertical: 12.h),
                                              margin: EdgeInsets.only(bottom: 12.h),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(8.r),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.search,
                                                    color: Colors.black,
                                                    size: 18.sp,
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    'Search Workouts',
                                                    style: GoogleFonts.ubuntu(
                                                      color: Colors.black,
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 72.w,
                              height: 450.h,
                              child: _bodyMapController == null
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : AnimatedBuilder(
                                      animation: _bodyMapController!,
                                      builder: (context, _) {
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Body view with flip option
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                children: [
                                                  // Header with view label and flip button
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        _bodyMapController!.isFront ? 'Front' : 'Back',
                                                        style: GoogleFonts.ubuntu(
                                                          color: Colors.white.withOpacity(0.7),
                                                          fontSize: 12.sp,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.flip,
                                                          color: Colors.white,
                                                          size: 20.sp,
                                                        ),
                                                        onPressed: () {
                                                          _bodyMapController!.toggleView();
                                                        },
                                                        tooltip: 'Flip view',
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  // Body SVG
                                                  Expanded(
                                                    child: InteractiveBodySvg(
                                                      isFront: _bodyMapController!.isFront,
                                                      selectedMuscles: _selectedBodyParts,
                                                      disabledMuscles: _bodyMapController!.disabledMuscles,
                                                      onMuscleTap: (muscle) {
                                                        _bodyMapController!.toggleMuscle(muscle);
                                                      },
                                                      onMuscleLongPress: (muscle) {
                                                        // Long press to disable/enable muscle
                                                        if (_bodyMapController!.isDisabled(muscle)) {
                                                          _bodyMapController!.enableMuscle(muscle);
                                      } else {
                                                          _bodyMapController!.disableMuscle(muscle);
                                      }
                                                      },
                                                      highlightColor: AppColors.primary,
                                                      disabledColor: Colors.grey.withOpacity(0.5),
                                                      selectedStrokeWidth: 2.5,
                                                      unselectedStrokeWidth: 1.0,
                                                      fit: BoxFit.contain,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      hitTestPadding: 5.0,
                                                      tooltipBuilder: (muscle) => muscle.displayName,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            // Vertical scrollable muscle selector
                                            Expanded(
                                              flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                                    color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.all(8.w),
                                    child: Text(
                                                        'Muscles',
                                      style: GoogleFonts.ubuntu(
                                                          color: Colors.white,
                                                          fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                                    Expanded(
                                                      child: _buildMusclePicker(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      // Macros Radar Chart - Show message if no active diet plan for today
                      _isLoadingActivePlan
                          ? Container(
                              padding: EdgeInsets.all(40.w),
                              margin: EdgeInsets.only(bottom: 20.h),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : _activeDietPlanId != null && _activeDietPlanId!.isNotEmpty
                              ? MacrosRadarChart(
                                  carbsPercentage: _getCarbsPercentage(),
                                  proteinPercentage: _getProteinPercentage(),
                                  fatPercentage: _getFatPercentage(),
                                  carbsGoal: _carbsGoal,
                                  proteinGoal: _proteinGoal,
                                  fatGoal: _fatGoal,
                                  onTap: () {
                                    _showDailyDietGoalBottomSheet(context);
                                  },
                                )
                              : Container(
                                  padding: EdgeInsets.all(40.w),
                                  margin: EdgeInsets.only(bottom: 20.h),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu_outlined,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 48.sp,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        'No Active Diet Plan',
                                        style: GoogleFonts.ubuntu(
                                          color: Colors.white,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Activate a diet plan to track your daily macros consumption',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.ubuntu(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await context.push<bool>('/diet-planning');
                                          // Always refresh when returning from diet planning screen
                                          // This ensures active plan updates are reflected immediately
                                          if (mounted) {
                                            _loadActiveDietPlan();
                                            _loadMacrosForBottomSheet();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.black,
                                        ),
                                        child: Text(
                                          'View Diet Plans',
                                          style: GoogleFonts.ubuntu(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      SizedBox(height: 20.h),
                      // Active Diet Plan Section - Only show if there's an active plan ID for today
                      if (_isLoadingActivePlan)
                        Container(
                          padding: EdgeInsets.all(20.w),
                          margin: EdgeInsets.only(bottom: 20.h),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (_activeDietPlanId != null && _activeDietPlanId!.isNotEmpty)
                        _buildActiveDietPlanCard()
                      else
                        const SizedBox.shrink(),
                      // Exercise activities tile - commented out
                      // ActivitiesTile(
                      //   activities: _getActivities(),
                      //   onMoreTap: () {
                      //     // TODO: Navigate to more activities screen
                      //   },
                      //   onActivityTap: (activity) {
                      //     context.push(
                      //       ActivityTrackingScreen.route,
                      //       extra: activity,
                      //     );
                      //   },
                      // ),
                      // Track progress charts
                      SizedBox(
                        height: 300.h,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 40.w,
                                child: HealthMetricsChart(
                                  title: 'Weight Track',
                                  subtitle: 'Weight (kg)',
                                  chartType: ChartType.weight,
                                  isWeekly: true,
                                  series: _getWeightChartData(state),
                                ),
                              ),
                              SizedBox(width: 20.w),
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 40.w,
                                child: HealthMetricsChart(
                                  title: 'Calories Burn Track',
                                  subtitle: 'Calories',
                                  chartType: ChartType.calories,
                                  isWeekly: true,
                                  series: _getCaloriesChartData(state),
                                ),
                              ),
                              // Heart Rate Track - commented out
                              // SizedBox(width: 20.w),
                              // SizedBox(
                              //   width: MediaQuery.of(context).size.width - 40.w,
                              //   child: HealthMetricsChart(
                              //     title: 'Heart Rate Track',
                              //     subtitle: 'Heart Rate (bpm)',
                              //     chartType: ChartType.heartRate,
                              //     isWeekly: true,
                              //     series: _getHeartRateChartData(state),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Discover Features",
                        style: GoogleFonts.ubuntu(
                          color: AppColors.textOnPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      DiscoverSection(
                        onCardTap: (cardName) async {
                          if (cardName == 'Bar Code Scanner') {
                            context.push(BarcodeScannerScreen.route);
                          } else if (cardName == 'Daily Diet Goal') {
                            await context.push<bool>('/diet-planning');
                            // Always refresh when returning from diet planning screen
                            // This ensures active plan updates are reflected immediately
                            if (mounted) {
                              _loadActiveDietPlan();
                              _loadMacrosForBottomSheet();
                            }
                          } else if (cardName == 'My Food Items') {
                            context.push('/my-food-items');
                          } else if (cardName == 'Workout Plan') {
                            context.push('/workout-list');
                          }
                          // Handle other card taps here
                        },
                      ),
                      SizedBox(height: 20.h),
                      // Text(
                      //   "See All",
                      //   style: GoogleFonts.ubuntu(
                      //     color: Colors.black,
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.w800,
                      //     decoration: TextDecoration.underline,
                      //   ),
                      // ),
                      // SingleChildScrollView(
                      //   controller: _scrollController,
                      //   scrollDirection: Axis.horizontal,
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.start,
                      //     children: [
                      //       HomeCardWidget(
                      //         mainImage: 'assets/home/images/workout1.jpg',
                      //         title: 'Quick Workout Tutorials',
                      //         desc:
                      //             'Need a quick workout? Try our Pre-mode workout plans.',
                      //         onClick: () => _showQuickWorkoutOptions(context),
                      //         buttonText: 'Start Workout',
                      //         modelImage: 'assets/home/images/girl.png',
                      //         height: 160.h,
                      //         width: 160.w,
                      //         left: 130.w,
                      //         bottom: 40.h,
                      //       ),
                      //       HomeCardWidget(
                      //         mainImage: 'assets/home/images/workout.jpg',
                      //         title: 'Generate Workout Plans',
                      //         desc:
                      //             'Create a personalized workout plan tailored to your goals and experience level.',
                      //         onClick: () {
                      //           // TODO: Navigate to generate workout
                      //         },
                      //         buttonText: 'Start to Generate',
                      //         modelImage: 'assets/home/images/workout2.png',
                      //         height: 210.h,
                      //         width: 90.w,
                      //         left: 200.w,
                      //         bottom: 20.h,
                      //       ),
                      //       HomeCardWidget(
                      //         mainImage: 'assets/home/images/workout.jpg',
                      //         title: 'Generate Diet Plans',
                      //         desc:
                      //             'Create a personalized nutrition plan tailored to your dietary needs and health goals.',
                      //         onClick: () {
                      //           // TODO: Navigate to generate diet plan
                      //         },
                      //         buttonText: 'Get Diet Plan',
                      //         modelImage: 'assets/home/images/model.png',
                      //         height: 140.h,
                      //         width: 140.w,
                      //         left: 150.w,
                      //         bottom: 70.h,
                      //       ),
                      //       HomeCardWidget(
                      //         mainImage: 'assets/home/images/workout1.jpg',
                      //         title: 'Health CalCulators',
                      //         desc:
                      //             'Develop a personalized set of health calculators to track your fitness metrics.',
                      //         onClick: () {
                      //           // TODO: Navigate to health calculators
                      //         },
                      //         buttonText: 'Calculate health',
                      //         modelImage: 'assets/home/images/workout3.png',
                      //         height: 150.h,
                      //         width: 150.w,
                      //         left: 150.w,
                      //         bottom: 50.h,
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
                // Motivation message overlay
                Positioned(
                  top: 80.h,
                  left: 0,
                  right: 0,
                  child: MotivationMessageWidget(
                    stepsPercentage: stepsPercentage,
                    caloriesPercentage: caloriesPercentage,
                    moveMinPercentage: moveMinPercentage,
                    steps: steps,
                    calories: calories,
                    moveMin: moveMin,
                    confettiController: _confettiController,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Load goals from service and calculate if needed
  Future<Map<String, double>> _loadGoals(HomeLoaded state) async {
    // Get existing goals - use EnhancedGoalService to get today's goals
    final goalService = EnhancedGoalService(
      firestore: FirebaseFirestore.instance,
    );
    final currentGoals = await goalService.getCurrentGoals();

    var stepsGoal = (currentGoals['steps'] as int).toDouble();
    var caloriesGoal = currentGoals['calories'] as double;
    var moveMinGoal = (currentGoals['moveMin'] as int).toDouble();

    // If calories goal is default (2000), try to calculate from user health data
    if (caloriesGoal == 2000.0) {
      try {
        // Get user profile with dateOfBirth and gender
        final profileRepo = getIt<UserProfileRepository>();
        final userProfile = await profileRepo.getUserProfile(_userId);

        if (userProfile != null &&
            userProfile.dateOfBirth != null &&
            userProfile.gender != null) {
          // Calculate age
          final now = DateTime.now();
          final dob = userProfile.dateOfBirth!;
          int age = now.year - dob.year;
          if (now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day)) {
            age--;
          }

          // First try to get weight and height from user profile (database)
          double? weight = userProfile.weight; // in kg
          double? height = userProfile.height; // in cm

          // If not in profile, try to get from Google Fit
          if (weight == null || height == null) {
            try {
              final googleFitRepo = getIt<GoogleFitRepository>();
              if (weight == null) {
                final weightResult = await googleFitRepo.getWeight();
                weightResult.fold(
                  (failure) => null,
                  (value) => weight = value, // weight is in kg
                );
              }

              if (height == null) {
                final heightResult = await googleFitRepo.getHeight();
                heightResult.fold(
                  (failure) => null,
                  (value) =>
                      height = value, // height is in meters, convert to cm
                );

                if (height != null) {
                  height = height! * 100; // Convert meters to cm
                }
              }
            } catch (e) {
              debugPrint('Error fetching weight/height from Google Fit: $e');
            }
          }

          // Only calculate if we have all required health data from database
          if (weight != null && height != null) {
            // Map workoutType to activity level (only if available)
            String? activityLevel;
            if (userProfile.workoutType != null) {
              final workoutType = userProfile.workoutType!.toLowerCase();
              if (workoutType.contains('cardio') ||
                  workoutType.contains('active')) {
                activityLevel = 'active';
              } else if (workoutType.contains('strength') ||
                  workoutType.contains('moderate')) {
                activityLevel = 'moderate';
              } else if (workoutType.contains('light') ||
                  workoutType.contains('yoga')) {
                activityLevel = 'light';
              } else if (workoutType.contains('sedentary') ||
                  workoutType.contains('none')) {
                activityLevel = 'sedentary';
              }
            }

            // Use moderate as default activity level only if workoutType is not available
            final finalActivityLevel = activityLevel ?? 'moderate';

            final calculatedCalories =
                GoalService.calculateCaloriesFromHealthData(
                  weight: weight!,
                  height: height!,
                  age: age,
                  gender: userProfile.gender!,
                  activityLevel: finalActivityLevel,
                );

            if (calculatedCalories > 0) {
              caloriesGoal = calculatedCalories;
              stepsGoal = GoalService.calculateStepsFromCalories(
                caloriesGoal,
              ).toDouble();

              // Save to SharedPreferences for quick access
              await GoalService.setCaloriesGoal(caloriesGoal);
              if (stepsGoal > 0) {
                await GoalService.setStepsGoal(stepsGoal.toInt());
              }

              // IMPORTANT: Also save to backend using EnhancedGoalService
              // This ensures goals are stored in Firestore for persistence
              try {
                await goalService.saveDailyGoals(
                  stepCountGoalValue: stepsGoal > 0 ? stepsGoal.toInt() : 10000,
                  caloriesBurnGoalValue: calculatedCalories,
                  moveMinGoalValue: moveMinGoal.toInt(),
                  isPaused: false,
                  isGoalCompleted: false,
                );

                // Calculate and save macros based on daily calories and purpose
                try {
                  final macroService = MacroCalculationService(
                    firestore: FirebaseFirestore.instance,
                  );
                  await macroService.calculateAndSaveMacros(
                    userId: _userId,
                    dailyCalories: calculatedCalories,
                    purpose: userProfile.purpose,
                  );
                } catch (e) {
                  debugPrint(
                    'Error calculating and saving macros in _loadGoals: $e',
                  );
                }

                debugPrint('_loadGoals: Calculated goals saved to backend');
              } catch (e) {
                debugPrint(
                  'Error saving calculated goals to backend in _loadGoals: $e',
                );
              }

              // Calculate and save macros based on daily calories and purpose
              try {
                final macroService = MacroCalculationService(
                  firestore: FirebaseFirestore.instance,
                );
                await macroService.calculateAndSaveMacros(
                  userId: _userId,
                  dailyCalories: calculatedCalories,
                  purpose: userProfile.purpose,
                );
              } catch (e) {
                debugPrint('Error calculating and saving macros: $e');
              }
            }
          } else {
            debugPrint(
              'Cannot calculate calories goal: Missing weight or height from database',
            );
          }
        }
      } catch (e) {
        // If calculation fails, use default
        debugPrint('Error calculating calories goal: $e');
      }
    }

    return {
      'steps': stepsGoal.toDouble(),
      'calories': caloriesGoal,
      'moveMin': moveMinGoal.toDouble(),
    };
  }

  /// Get list of available activities
  List<Activity> _getActivities() {
    return const [
      Activity(
        name: 'Walking',
        icon: Icons.directions_walk,
        color: Color(0xFF2196F3),
      ),
      Activity(
        name: 'Running',
        icon: Icons.directions_run,
        color: Color(0xFF4CAF50),
      ),
      Activity(
        name: 'Cycling',
        icon: Icons.directions_bike,
        color: Color(0xFFFF9800),
      ),
      Activity(name: 'Hiking', icon: Icons.terrain, color: Color(0xFF795548)),
      Activity(name: 'Swimming', icon: Icons.pool, color: Color(0xFF00BCD4)),
      Activity(
        name: 'Skating',
        icon: Icons.skateboarding,
        color: Color(0xFFE91E63),
      ),
    ];
  }

  /// Get Monday of current week
  DateTime _getMondayOfWeek(DateTime date) {
    // weekday: 1 = Monday, 7 = Sunday
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  /// Get weight chart data
  ChartSeries _getWeightChartData(HomeLoaded state) {
    final weeklyData = state.weeklyFitnessData;

    if (weeklyData.isEmpty) {
      return ChartSeries(
        name: 'Weight (kg)',
        dataPoints: [],
        color: const Color(0xFF00D4AA),
      );
    }

    return ChartSeries(
      name: 'Weight (kg)',
      dataPoints: weeklyData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final date =
            data.date ?? DateTime.now().subtract(Duration(days: 6 - index));
        return ChartDataPoint(
          value: data.weight ?? 0.0,
          label: _getDayLabel(date),
        );
      }).toList(),
      color: const Color(0xFF00D4AA),
    );
  }

  /// Get calories chart data
  ChartSeries _getCaloriesChartData(HomeLoaded state) {
    final weeklyData = state.weeklyFitnessData;

    if (weeklyData.isEmpty) {
      return ChartSeries(
        name: 'Calories',
        dataPoints: [],
        color: const Color(0xFFFF6B35),
      );
    }

    return ChartSeries(
      name: 'Calories',
      dataPoints: weeklyData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final date =
            data.date ?? DateTime.now().subtract(Duration(days: 6 - index));
        return ChartDataPoint(
          value: data.calories ?? 0.0,
          label: _getDayLabel(date),
        );
      }).toList(),
      color: const Color(0xFFFF6B35),
    );
  }

  /// Get heart rate chart data
  ChartSeries _getHeartRateChartData(HomeLoaded state) {
    final weeklyData = state.weeklyFitnessData;

    if (weeklyData.isEmpty) {
      return ChartSeries(
        name: 'Heart Rate (bpm)',
        dataPoints: [],
        color: const Color(0xFFFF006E),
      );
    }

    return ChartSeries(
      name: 'Heart Rate (bpm)',
      dataPoints: weeklyData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final date =
            data.date ?? DateTime.now().subtract(Duration(days: 6 - index));
        return ChartDataPoint(
          value: data.heartRate ?? 0.0,
          label: _getDayLabel(date),
        );
      }).toList(),
      color: const Color(0xFFFF006E),
    );
  }

  String _getDayLabel(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  /// Load macros data from Firestore
  Future<void> _loadMacrosData() async {
    try {
      if (_userId.isEmpty) {
        debugPrint('MacrosRadarChart: userId is empty, cannot load macros');
        return;
      }

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
        final proteinValue =
            macros['protein'] ?? data['profile.macros.protein'];
        final fatValue = macros['fat'] ?? data['profile.macros.fat'];

        debugPrint(
          'MacrosRadarChart: Loaded macros - Carbs: $carbsValue, Protein: $proteinValue, Fat: $fatValue',
        );

        if (mounted) {
          setState(() {
            _carbsGoal = carbsValue != null
                ? (carbsValue as num).toDouble()
                : null;
            _proteinGoal = proteinValue != null
                ? (proteinValue as num).toDouble()
                : null;
            _fatGoal = fatValue != null ? (fatValue as num).toDouble() : null;
          });
        }
      } else {
        debugPrint('MacrosRadarChart: User document does not exist');
      }
    } catch (e) {
      debugPrint('Error loading macros data: $e');
    }
  }

  /// Load consumed macros from active diet plans and daily food entries
  Future<void> _loadConsumedMacros() async {
    try {
      if (_userId.isEmpty) {
        // Reset to 0 if user not logged in
        if (mounted) {
          setState(() {
            _caloriesConsumed = 0.0;
            _carbsConsumed = 0.0;
            _proteinConsumed = 0.0;
            _fatConsumed = 0.0;
          });
        }
        return;
      }

      final dateString = _getTodayDateString();
      double totalCalories = 0.0;
      double totalCarbs = 0.0;
      double totalProtein = 0.0;
      double totalFat = 0.0;

      // Check dailyGoal for today's active diet plan ID
      final dailyGoalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .get();

      String? activePlanId;
      if (dailyGoalDoc.exists) {
        final data = dailyGoalDoc.data();
        activePlanId = data?['dietPlanId'] as String?;
      }

      // Load consumed meals from today's active diet plan ONLY
      if (activePlanId != null && activePlanId.isNotEmpty) {
        final planDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .doc(activePlanId)
            .get();

        if (planDoc.exists) {
          final planData = planDoc.data()!;
          final meals = planData['meals'] as List<dynamic>? ?? [];

          // Check each meal in the plan
          for (var meal in meals) {
            final mealMap = meal as Map<String, dynamic>;
            final product = mealMap['product'] as Map<String, dynamic>? ?? {};

            // Check if this meal is marked as consumed
            // Explicitly check for true value, default to false if not present
            final isConsumedValue = product['isConsumed'];
            final isConsumed = isConsumedValue == true;

            if (isConsumed == true) {
              // Get nutrition from meal's nutrition field (calculated nutrition)
              final nutrition =
                  mealMap['nutrition'] as Map<String, dynamic>? ?? {};

              // If nutrition is not available, calculate from product nutrition
              if (nutrition.isEmpty) {
                final productNutrition =
                    product['nutrition'] as Map<String, dynamic>? ?? {};
                final quantity =
                    (mealMap['quantity'] as num?)?.toDouble() ?? 1.0;
                final servingSize =
                    (productNutrition['servingSize'] as num?)?.toDouble() ??
                    1.0;

                final baseCalories =
                    (productNutrition['calories'] as num?)?.toDouble() ?? 0.0;
                final baseCarbs =
                    (productNutrition['carbs'] as num?)?.toDouble() ?? 0.0;
                final baseProtein =
                    (productNutrition['protein'] as num?)?.toDouble() ?? 0.0;
                final baseFat =
                    (productNutrition['fat'] as num?)?.toDouble() ?? 0.0;

                totalCalories += (baseCalories * quantity / servingSize);
                totalCarbs += (baseCarbs * quantity / servingSize);
                totalProtein += (baseProtein * quantity / servingSize);
                totalFat += (baseFat * quantity / servingSize);
              } else {
                // Use calculated nutrition from meal
                totalCalories +=
                    (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
                totalCarbs += (nutrition['carbs'] as num?)?.toDouble() ?? 0.0;
                totalProtein +=
                    (nutrition['protein'] as num?)?.toDouble() ?? 0.0;
                totalFat += (nutrition['fat'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }
        }
      }

      // Only count consumed items from today's active diet plan
      // Regular daily food entries are not included in consumed macros
      // They should be tracked separately if needed

      if (mounted) {
        setState(() {
          _caloriesConsumed = totalCalories;
          _carbsConsumed = totalCarbs;
          _proteinConsumed = totalProtein;
          _fatConsumed = totalFat;
        });
        debugPrint(
          'Loaded consumed macros - Calories: $totalCalories, Carbs: $totalCarbs, Protein: $totalProtein, Fat: $totalFat',
        );
        debugPrint('Active plan ID from dailyGoal: $activePlanId');
      }
    } catch (e) {
      debugPrint('Error loading consumed macros: $e');
      // Reset to 0 on error
      if (mounted) {
        setState(() {
          _caloriesConsumed = 0.0;
          _carbsConsumed = 0.0;
          _proteinConsumed = 0.0;
          _fatConsumed = 0.0;
        });
      }
    }
  }

  /// Calculate consumed percentages based on actual consumed values
  double _getCarbsPercentage() {
    if (_carbsGoal == null || _carbsGoal == 0) {
      return 0.0;
    }
    return (_carbsConsumed / _carbsGoal! * 100).clamp(0.0, 100.0);
  }

  double _getProteinPercentage() {
    if (_proteinGoal == null || _proteinGoal == 0) {
      return 0.0;
    }
    return (_proteinConsumed / _proteinGoal! * 100).clamp(0.0, 100.0);
  }

  double _getFatPercentage() {
    if (_fatGoal == null || _fatGoal == 0) {
      return 0.0;
    }
    return (_fatConsumed / _fatGoal! * 100).clamp(0.0, 100.0);
  }

  /// Update goal completion values in Firestore
  Future<void> _updateGoalCompletion({
    required int steps,
    required double calories,
    required int? moveMin,
  }) async {
    try {
      final goalService = EnhancedGoalService(
        firestore: FirebaseFirestore.instance,
      );
      await goalService.updateGoalCompletion(
        steps: steps,
        calories: calories,
        moveMin: moveMin,
      );
    } catch (e) {
      debugPrint('Error updating goal completion: $e');
    }
  }

  /// Load active diet plan from Firestore (check dailyGoal for today's active plan)
  Future<void> _loadActiveDietPlan() async {
    try {
      if (_userId.isEmpty) return;

      setState(() {
        _isLoadingActivePlan = true;
      });

      // Get today's date string
      final now = DateTime.now();
      final dateString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Check dailyGoal for today's active diet plan ID
      final dailyGoalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .get();

      String? activePlanId;
      if (dailyGoalDoc.exists) {
        final data = dailyGoalDoc.data();
        activePlanId = data?['dietPlanId'] as String?;
      }

      if (activePlanId != null && activePlanId.isNotEmpty) {
        // Load the active diet plan by ID
        final planDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .doc(activePlanId)
            .get();

        if (mounted) {
          setState(() {
            if (planDoc.exists) {
              final data = planDoc.data();
              final planStatus = data?['status'] as String? ?? 'inactive';
              
              // Verify the plan status matches (should be active)
              // Also verify it's still the active plan in dailyGoal
              debugPrint('_loadActiveDietPlan: Plan found, status: $planStatus, activePlanId: $activePlanId');
              if (planStatus == 'active') {
                _activeDietPlan = {'id': planDoc.id, ...data!};
                _activeDietPlanId = activePlanId; // Store the active plan ID
                debugPrint('_loadActiveDietPlan: Active plan loaded successfully: ${data?['name']}');
              } else {
                // Plan exists but status is not active - clear it
                _activeDietPlan = null;
                _activeDietPlanId = null;
                // Also clear from dailyGoal
                _clearActivePlanFromDailyGoal(dateString);
              }
            } else {
              // Plan doesn't exist - clear everything
              _activeDietPlan = null;
              _activeDietPlanId = null;
              // Also clear from dailyGoal
              _clearActivePlanFromDailyGoal(dateString);
            }
            _isLoadingActivePlan = false;
          });
        }
      } else {
        // No active plan for today - clear everything
        if (mounted) {
          setState(() {
            _activeDietPlan = null;
            _activeDietPlanId = null; // Clear the active plan ID
            _isLoadingActivePlan = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading active diet plan: $e');
      if (mounted) {
        setState(() {
          _isLoadingActivePlan = false;
        });
      }
    }
  }

  /// Calculate total calories from meals
  double _calculateTotalCaloriesFromMeals(List<dynamic> meals) {
    double total = 0.0;
    for (var meal in meals) {
      final nutrition = meal['nutrition'] as Map<String, dynamic>?;
      if (nutrition != null) {
        total += (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  /// Calculate consumed meals count
  int _calculateConsumedMealsCount(List<dynamic> meals) {
    int count = 0;
    for (var meal in meals) {
      final product = meal['product'] as Map<String, dynamic>? ?? {};
      final isConsumed = product['isConsumed'] == true;
      if (isConsumed) count++;
    }
    return count;
  }

  /// Clear active plan from dailyGoal if it doesn't exist or is inactive
  Future<void> _clearActivePlanFromDailyGoal(String dateString) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .set({
        'dietPlanId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error clearing active plan from dailyGoal: $e');
    }
  }

  /// Build active diet plan card widget
  Widget _buildActiveDietPlanCard() {
    // Only show if there's an active plan ID for today
    if (_activeDietPlanId == null || _activeDietPlanId!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_activeDietPlan == null || _activeDietPlan!.isEmpty) {
      return const SizedBox.shrink();
    }

    final planId = _activeDietPlan!['id'] as String?;
    if (planId == null || planId.isEmpty) {
      return const SizedBox.shrink();
    }

    final planName = _activeDietPlan!['name'] as String? ?? 'Untitled Plan';
    final meals = _activeDietPlan!['meals'] as List<dynamic>? ?? [];
    final totalCalories = _calculateTotalCaloriesFromMeals(meals);
    final totalMeals = meals.length;
    final consumedMeals = _calculateConsumedMealsCount(meals);
    final progressPercentage = totalMeals > 0
        ? (consumedMeals / totalMeals * 100)
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () async {
            if (planId == null) return;
            final result = await context.push<bool>(
              DietPlanDetailScreen.route,
              extra: {'planId': planId, 'planData': _activeDietPlan!},
            );
            // Refresh active plan when returning
            if (result == true && mounted) {
              _loadActiveDietPlan();
              _loadMacrosForBottomSheet(); // Refresh consumed macros
            }
          },
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Diet Plan',
                                  style: GoogleFonts.ubuntu(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  planName,
                                  style: GoogleFonts.ubuntu(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Active',
                        style: GoogleFonts.ubuntu(
                          color: const Color(0xFF4CAF50),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$consumedMeals / $totalMeals',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Meals Completed',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            totalCalories.toStringAsFixed(0),
                            style: GoogleFonts.ubuntu(
                              color: AppColors.primary,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Total Calories',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 8.h,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${progressPercentage.toStringAsFixed(0)}% Complete',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build Google Fit connection banner with modern aesthetic design
}
