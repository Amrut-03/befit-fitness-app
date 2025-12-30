import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'Befit';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Environment
  static const bool isProduction = kReleaseMode;
  static const bool isDevelopment = kDebugMode;
  
  // API Configuration - Load from .env file
  static String get geminiApiKey => 
      dotenv.env['GEMINI_API_KEY']!; // Fallback for development
  
  static String get googleMapsApiKey => 
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 
      ''; // Will be set in AndroidManifest.xml
  
  // Firebase Configuration
  static const String firebaseProjectId = 'befit-app';
  
  // App URLs
  static const String privacyPolicyUrl = 'https://befit-app.com/privacy';
  static const String termsOfServiceUrl = 'https://befit-app.com/terms';
  static const String supportEmail = 'support@befit-app.com';
  
  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
  
  // UI Configuration
  static const double designWidth = 360.0;
  static const double designHeight = 690.0;
  
  // Animation Configuration
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Network Configuration
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Storage Configuration
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  
  // Health Configuration
  static const double maxBmi = 25.0;
  static const double maxBmr = 100.0;
  static const double maxHrc = 180.0;
  
  // Workout Configuration
  static const int defaultWorkoutDuration = 30; // minutes
  static const int maxWorkoutDuration = 120; // minutes
  static const int minWorkoutDuration = 5; // minutes
  
  // Diet Configuration
  static const int defaultCalorieGoal = 2000;
  static const int minCalorieGoal = 1200;
  static const int maxCalorieGoal = 4000;
}
