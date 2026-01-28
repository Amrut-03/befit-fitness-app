import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage daily fitness goals
class GoalService {
  static const String _stepsGoalKey = 'daily_steps_goal';
  static const String _caloriesGoalKey = 'daily_calories_goal';
  static const String _moveMinGoalKey = 'daily_move_min_goal';

  /// Get daily steps goal (default: 10000)
  static Future<int> getStepsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepsGoalKey) ?? 10000;
  }

  /// Set daily steps goal
  static Future<void> setStepsGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepsGoalKey, goal);
  }

  /// Get daily calories goal (default: 2000)
  static Future<double> getCaloriesGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_caloriesGoalKey) ?? 2000.0;
  }

  /// Set daily calories goal
  static Future<void> setCaloriesGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_caloriesGoalKey, goal);
  }

  /// Get daily move minutes goal (default: 30)
  static Future<int> getMoveMinGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_moveMinGoalKey) ?? 30;
  }

  /// Set daily move minutes goal
  static Future<void> setMoveMinGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_moveMinGoalKey, goal);
  }

  /// Calculate calories from user health data using BMR formula
  /// Uses Mifflin-St Jeor Equation
  static double calculateCaloriesFromHealthData({
    required double weight, // in kg
    required double height, // in cm
    required int age,
    required String gender, // 'male' or 'female'
    required String activityLevel, // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  }) {
    // Calculate BMR (Basal Metabolic Rate)
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // Activity multipliers
    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };

    final multiplier = activityMultipliers[activityLevel.toLowerCase()] ?? 1.2;
    
    // Total Daily Energy Expenditure (TDEE)
    return bmr * multiplier;
  }

  /// Calculate steps needed from calories goal
  /// Average: 1 step ≈ 0.04-0.05 calories (varies by person)
  /// Using 0.045 as average
  static int calculateStepsFromCalories(double caloriesGoal) {
    // Average calories per step
    const caloriesPerStep = 0.045;
    return (caloriesGoal / caloriesPerStep).round();
  }
}

