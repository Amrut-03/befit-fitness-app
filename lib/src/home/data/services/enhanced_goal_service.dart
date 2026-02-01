import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:befit_fitness_app/src/home/data/services/goal_service.dart';
import 'package:befit_fitness_app/src/home/data/services/macro_calculation_service.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';

/// Enhanced goal service with backend storage and advanced features
class EnhancedGoalService {
  static const String _stepsGoalKey = 'daily_steps_goal';
  static const String _caloriesGoalKey = 'daily_calories_goal';
  static const String _moveMinGoalKey = 'daily_move_min_goal';
  static const String _goalEditedTodayKey = 'goal_edited_today';
  static const String _goalEditDateKey = 'goal_edit_date';
  static const String _firstTimeUserKey = 'first_time_user';
  
  final FirebaseFirestore firestore;
  
  EnhancedGoalService({required this.firestore});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Check if it's before 12 PM
  bool _isBeforeNoon() {
    return DateTime.now().hour < 12;
  }

  /// Get today's date string (YYYY-MM-DD)
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if user has already edited goal today
  Future<bool> hasEditedGoalToday() async {
    final prefs = await SharedPreferences.getInstance();
    final editDate = prefs.getString(_goalEditDateKey);
    return editDate == _getTodayDateString();
  }

  /// Mark goal as edited today
  Future<void> _markGoalEditedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalEditDateKey, _getTodayDateString());
    await prefs.setBool(_goalEditedTodayKey, true);
  }

  /// Check if user is first time
  Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeUserKey) ?? true;
  }

  /// Mark user as not first time
  Future<void> markUserAsNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeUserKey, false);
  }

  /// Get current goals (from SharedPreferences for quick access)
  /// Always returns today's goals, not tomorrow's
  Future<Map<String, dynamic>> getCurrentGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final todayDateString = _getTodayDateString();
    
    // First, try to get today's goals from Firestore
    try {
      final todayDoc = await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(todayDateString)
          .get();
      
      if (todayDoc.exists) {
        final data = todayDoc.data()!;
        final rawSteps = (data['stepCountGoalValue'] as num?)?.toInt() ??
            (data['steps'] as num?)?.toInt() ??
            prefs.getInt(_stepsGoalKey) ?? 10000;
        return {
          'steps': rawSteps.clamp(1000, GoalService.maxStepsGoal),
          'calories': (data['caloriesBurnGoalValue'] as num?)?.toDouble() ?? 
                      (data['calories'] as num?)?.toDouble() ?? // Backward compatibility
                      prefs.getDouble(_caloriesGoalKey) ?? 2000.0,
          'moveMin': (data['moveMinGoalValue'] as num?)?.toInt() ?? 
                     (data['moveMin'] as num?)?.toInt() ?? // Backward compatibility
                     prefs.getInt(_moveMinGoalKey) ?? 30,
        };
      }
    } catch (e) {
      // If Firestore fails, fall back to SharedPreferences
      if (kDebugMode) debugPrint('Error fetching today\'s goals from Firestore: $e');
    }
    
    // Fallback to SharedPreferences
    final fallbackSteps = prefs.getInt(_stepsGoalKey) ?? 10000;
    return {
      'steps': fallbackSteps.clamp(1000, GoalService.maxStepsGoal),
      'calories': prefs.getDouble(_caloriesGoalKey) ?? 2000.0,
      'moveMin': prefs.getInt(_moveMinGoalKey) ?? 30,
    };
  }

  /// Validate goal values
  String? validateStepsGoal(int steps) {
    if (steps < 1000) return 'Steps goal should be at least 1,000 steps';
    if (steps > GoalService.maxStepsGoal) return 'Steps goal should not exceed ${GoalService.maxStepsGoal} steps (realistic daily limit)';
    return null;
  }

  String? validateCaloriesGoal(double calories) {
    if (calories < 500) return 'Calories goal should be at least 500 kcal';
    if (calories > 10000) return 'Calories goal should not exceed 10,000 kcal';
    return null;
  }

  String? validateMoveMinGoal(int moveMin) {
    if (moveMin < 5) return 'Move minutes goal should be at least 5 minutes';
    if (moveMin > 300) return 'Move minutes goal should not exceed 300 minutes';
    return null;
  }

  /// Save all daily goals in a single document
  /// This is the new preferred method - saves all goals together
  Future<void> saveDailyGoals({
    required int stepCountGoalValue,
    required double caloriesBurnGoalValue,
    required int moveMinGoalValue,
    String? pauseReason, // 'sick', 'rest_day', 'other'
    bool isPaused = false,
    bool isGoalCompleted = false,
  }) async {
    try {
      final now = DateTime.now();
      final isBeforeNoon = _isBeforeNoon();
      final targetDate = isBeforeNoon ? now : now.add(const Duration(days: 1));
      final dateString = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      final stepsToSave = stepCountGoalValue.clamp(1000, GoalService.maxStepsGoal);

      // Only update SharedPreferences if goal is for today (before noon)
      // If goal is for tomorrow (after noon), don't update SharedPreferences yet
      if (isBeforeNoon) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_stepsGoalKey, stepsToSave);
        await prefs.setDouble(_caloriesGoalKey, caloriesBurnGoalValue);
        await prefs.setInt(_moveMinGoalKey, moveMinGoalValue);
      }

      // Mark as edited
      await _markGoalEditedToday();

      // Check if document already exists to preserve createdAt
      final existingDoc = await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .get();
      
      final bool isNewDocument = !existingDoc.exists;
      
      // Prepare update data
      final updateData = <String, dynamic>{
        'stepCountGoalValue': stepsToSave,
        'caloriesBurnGoalValue': caloriesBurnGoalValue,
        'moveMinGoalValue': moveMinGoalValue,
        'targetDate': dateString,
        'isPaused': isPaused,
        'pauseReason': pauseReason,
        'isGoalCompleted': isGoalCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Only set createdAt if it's a new document
      if (isNewDocument) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      // Always ensure completion tracking fields exist (initialize to 0 if not present)
      // Check if completion fields already exist in the document
      if (existingDoc.exists) {
        final existingData = existingDoc.data()!;
        // Only initialize if they don't exist
        if (!existingData.containsKey('stepCountCompleted')) {
          updateData['stepCountCompleted'] = 0;
        }
        if (!existingData.containsKey('caloriesBurnt')) {
          updateData['caloriesBurnt'] = 0.0;
        }
        if (!existingData.containsKey('moveMinCompleted')) {
          updateData['moveMinCompleted'] = 0;
        }
      } else {
        // New document - initialize all completion fields to 0
        updateData['stepCountCompleted'] = 0;
        updateData['caloriesBurnt'] = 0.0;
        updateData['moveMinCompleted'] = 0;
      }
      
      // Save to Firestore in dailyGoals collection with date as document ID
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .set(updateData, SetOptions(merge: true));
      
      // Also update profile.calorie when calories goal is saved
      // This ensures profile.calorie stays in sync with the editable goal
      await firestore
          .collection('users')
          .doc(_userId)
          .set({
        'profile.calorie': caloriesBurnGoalValue,
      }, SetOptions(merge: true));
      
      // Recalculate macros based on the updated profile.calorie
      await _recalculateMacros(caloriesBurnGoalValue);
    } catch (e) {
      throw Exception('Failed to save daily goals: $e');
    }
  }

  /// Save goal to backend with history (DEPRECATED - use saveDailyGoals instead)
  /// Kept for backward compatibility
  @Deprecated('Use saveDailyGoals instead')
  Future<void> saveGoal({
    required String goalType, // 'steps', 'calories', 'moveMin'
    required dynamic goalValue,
    String? pauseReason, // 'sick', 'rest', 'other'
    bool isPaused = false,
  }) async {
    try {
      final now = DateTime.now();
      final isBeforeNoon = _isBeforeNoon();
      final targetDate = isBeforeNoon ? now : now.add(const Duration(days: 1));
      final dateString = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      // Only update SharedPreferences if goal is for today (before noon)
      if (isBeforeNoon) {
        final prefs = await SharedPreferences.getInstance();
        switch (goalType) {
          case 'steps':
            await prefs.setInt(_stepsGoalKey, goalValue as int);
            break;
          case 'calories':
            await prefs.setDouble(_caloriesGoalKey, goalValue as double);
            break;
          case 'moveMin':
            await prefs.setInt(_moveMinGoalKey, goalValue as int);
            break;
        }
      }

      // Mark as edited
      await _markGoalEditedToday();

      // Get existing goals to merge
      final existingGoals = await getCurrentGoals();
      
      // Update the specific goal type
      final updatedGoals = {
        'stepCountGoalValue': goalType == 'steps' ? goalValue : existingGoals['steps'],
        'caloriesBurnGoalValue': goalType == 'calories' ? goalValue : existingGoals['calories'],
        'moveMinGoalValue': goalType == 'moveMin' ? goalValue : existingGoals['moveMin'],
        'targetDate': dateString,
        'isPaused': isPaused,
        'pauseReason': pauseReason,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update dailyGoals document
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .set(updatedGoals, SetOptions(merge: true));
      
      // If calories goal was updated, also update profile.calorie
      if (goalType == 'calories') {
        await firestore
            .collection('users')
            .doc(_userId)
            .set({
          'profile.calorie': goalValue as double,
        }, SetOptions(merge: true));
        
        // Recalculate macros based on the updated profile.calorie
        await _recalculateMacros(goalValue as double);
      }
    } catch (e) {
      throw Exception('Failed to save goal: $e');
    }
  }

  /// Recalculate macros when calories are updated
  Future<void> _recalculateMacros(double calories) async {
    try {
      final profileRepo = getIt<UserProfileRepository>();
      final userProfile = await profileRepo.getUserProfile(_userId);
      
      if (userProfile != null) {
        final macroService = MacroCalculationService(firestore: firestore);
        await macroService.calculateAndSaveMacros(
          userId: _userId,
          dailyCalories: calories,
          purpose: userProfile.purpose,
          shouldSaveCaloriesToProfile: false, // Already saved above
        );
        if (kDebugMode) debugPrint('EnhancedGoalService: Macros recalculated after calories update');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('EnhancedGoalService: Error recalculating macros: $e');
      // Don't throw - macro recalculation failure shouldn't break goal saving
    }
  }

  /// Get goal history from dailyGoals collection
  Future<List<Map<String, dynamic>>> getGoalHistory({int limit = 30}) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'targetDate': data['targetDate'] ?? doc.id,
          'stepCountGoalValue': data['stepCountGoalValue'] ?? data['steps'] ?? 10000,
          'caloriesBurnGoalValue': data['caloriesBurnGoalValue'] ?? data['calories'] ?? 2000.0,
          'moveMinGoalValue': data['moveMinGoalValue'] ?? data['moveMin'] ?? 30,
          'isPaused': data['isPaused'] ?? false,
          'pauseReason': data['pauseReason'],
          'isGoalCompleted': data['isGoalCompleted'] ?? false,
          'updatedAt': data['updatedAt'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching goal history: $e');
      return [];
    }
  }

  /// Check if goal is completed today
  Future<bool> isGoalCompletedToday({
    required int currentSteps,
    required double currentCalories,
    required int? currentMoveMin,
  }) async {
    final goals = await getCurrentGoals();
    final stepsCompleted = currentSteps >= (goals['steps'] as int);
    final caloriesCompleted = currentCalories >= (goals['calories'] as double);
    final moveMinCompleted = currentMoveMin != null && 
        currentMoveMin >= (goals['moveMin'] as int);
    
    return stepsCompleted && caloriesCompleted && moveMinCompleted;
  }

  /// Save goal completion status
  Future<void> saveGoalCompletionStatus({
    required bool isCompleted,
    required int steps,
    required double calories,
    required int? moveMin,
  }) async {
    try {
      final dateString = _getTodayDateString();
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .set({
        'isGoalCompleted': isCompleted,
        'actualSteps': steps,
        'actualCalories': calories,
        'actualMoveMin': moveMin,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - not critical
      if (kDebugMode) debugPrint('Error saving goal completion status: $e');
    }
  }

  /// Update daily goal completion values (stepCountCompleted, caloriesBurnt, moveMinCompleted)
  /// These values track progress throughout the day and reset at midnight
  Future<void> updateGoalCompletion({
    required int steps,
    required double calories,
    required int? moveMin,
  }) async {
    try {
      final dateString = _getTodayDateString();
      final updateData = <String, dynamic>{
        'stepCountCompleted': steps,
        'caloriesBurnt': calories,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Only include moveMin if it's not null
      if (moveMin != null) {
        updateData['moveMinCompleted'] = moveMin;
      }
      
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating goal completion: $e');
    }
  }

  /// Get current goal completion values
  Future<Map<String, dynamic>> getGoalCompletion() async {
    try {
      final dateString = _getTodayDateString();
      final doc = await firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'stepCountCompleted': (data['stepCountCompleted'] as num?)?.toInt() ?? 0,
          'caloriesBurnt': (data['caloriesBurnt'] as num?)?.toDouble() ?? 0.0,
          'moveMinCompleted': (data['moveMinCompleted'] as num?)?.toInt() ?? 0,
        };
      }
      
      return {
        'stepCountCompleted': 0,
        'caloriesBurnt': 0.0,
        'moveMinCompleted': 0,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting goal completion: $e');
      return {
        'stepCountCompleted': 0,
        'caloriesBurnt': 0.0,
        'moveMinCompleted': 0,
      };
    }
  }

  /// Get smart goal suggestions based on user health
  Future<Map<String, dynamic>> getSmartGoalSuggestions({
    required int currentSteps,
    required double currentCalories,
    required int? currentMoveMin,
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? activityLevel,
    String? purpose,
    String? workoutType,
  }) async {
    // Get average from last 7 days if available
    final history = await getGoalHistory(limit: 7);
    
    // Calculate smart suggestions
    int suggestedSteps = 10000;
    double suggestedCalories = 2000.0;
    int suggestedMoveMin = 30;

    if (history.isNotEmpty) {
      // Use average of recent goals from dailyGoals structure
      final recentSteps = history
          .map((g) => (g['stepCountGoalValue'] ?? g['steps'] ?? 10000) as int)
          .toList();
      if (recentSteps.isNotEmpty) {
        suggestedSteps = (recentSteps.reduce((a, b) => a + b) / recentSteps.length).round();
      }

      final recentCalories = history
          .map((g) => (g['caloriesBurnGoalValue'] ?? g['calories'] ?? 2000.0) as double)
          .toList();
      if (recentCalories.isNotEmpty) {
        suggestedCalories = recentCalories.reduce((a, b) => a + b) / recentCalories.length;
      }

      final recentMoveMin = history
          .map((g) => (g['moveMinGoalValue'] ?? g['moveMin'] ?? 30) as int)
          .toList();
      if (recentMoveMin.isNotEmpty) {
        suggestedMoveMin = (recentMoveMin.reduce((a, b) => a + b) / recentMoveMin.length).round();
      }
    }

    // Adjust based on current performance
    if (currentSteps > 0) {
      final completionRate = (currentSteps / suggestedSteps).clamp(0.5, 1.5);
      suggestedSteps = (suggestedSteps * completionRate).round();
    }

    // Use BMR calculation only if all health data is available from database
    if (weight != null && height != null && age != null && gender != null) {
      final bmr = _calculateBMR(weight, height, age, gender);
      
      // Use activity level multiplier if provided, otherwise use moderate
      double activityMultiplier = 1.55; // Moderate activity default if not specified
      if (activityLevel != null) {
        switch (activityLevel.toLowerCase()) {
          case 'sedentary':
            activityMultiplier = 1.2;
            break;
          case 'light':
            activityMultiplier = 1.375;
            break;
          case 'moderate':
            activityMultiplier = 1.55;
            break;
          case 'active':
            activityMultiplier = 1.725;
            break;
          case 'very_active':
            activityMultiplier = 1.9;
            break;
          default:
            activityMultiplier = 1.55; // Default to moderate if unknown activity level
        }
      }
      
      suggestedCalories = bmr * activityMultiplier;
      
      // Steps: use 10k for muscle gain/strength (realistic), else from calories
      if (suggestedCalories > 0) {
        try {
          suggestedSteps = GoalService.getStepsGoalFromProfile(
            calculatedCalories: suggestedCalories,
            purpose: purpose,
            workoutType: workoutType,
          );
        } catch (e) {
          if (kDebugMode) debugPrint('Error calculating steps from calories: $e');
          suggestedSteps = 10000;
        }
      }
    } else {
      // If health data is missing, don't use BMR calculation
      // Will rely on previous goal history only
      if (kDebugMode) debugPrint('Smart goal: Missing health data (weight, height, age, or gender), using history only');
    }

    return {
      'steps': suggestedSteps.clamp(1000, GoalService.maxStepsGoal),
      'calories': suggestedCalories.clamp(500, 10000), // Match validation limits
      'moveMin': suggestedMoveMin.clamp(5, 300), // Match validation limits
    };
  }

  double _calculateBMR(double weight, double height, int age, String gender) {
    if (gender.toLowerCase() == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }
}

