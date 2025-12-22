import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/config/app_config.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/onboarding/presentation/screens/onboarding_page.dart';

/// Service to handle app initialization and determine initial route
class AppInitializationService {
  static const String _onboardingCompletedKey = AppConfig.onboardingKey;

  /// Check if onboarding has been completed
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Check if user is authenticated
  static bool isUserAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  /// Get the initial route based on onboarding and auth status
  static Future<String> getInitialRoute() async {
    // Check if user is authenticated first
    if (isUserAuthenticated()) {
      // User is logged in, go directly to home
      return HomePage.route;
    }

    // Check if onboarding is completed
    final onboardingCompleted = await isOnboardingCompleted();
    if (onboardingCompleted) {
      // Onboarding done but not logged in, go to login
      return LoginPage.route;
    }

    // First time user, show onboarding
    return OnboardingPage.onboarding1;
  }
}

