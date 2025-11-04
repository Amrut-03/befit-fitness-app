import 'package:befit_fitness_app/src/onboarding/presentation/pages/onboarding_last_screen.dart';
import 'package:befit_fitness_app/src/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation service extension for easy navigation using GoRouter
extension NavigationService on BuildContext {
  /// Navigate to a route by path
  void navigateTo(String path, {Object? extra}) {
    GoRouter.of(this).go(path);
  }

  /// Push a new route on top of current route
  void pushRoute(String path, {Object? extra}) {
    GoRouter.of(this).push(path, extra: extra);
  }

  /// Push and remove all previous routes
  void pushReplacement(String path, {Object? extra}) {
    GoRouter.of(this).go(path);
  }

  /// Navigate back
  void pop() {
    if (canPop()) {
      GoRouter.of(this).pop();
    }
  }

  /// Check if can pop
  bool canPop() {
    return GoRouter.of(this).canPop();
  }

  // Onboarding navigation helpers
  void navigateToOnboarding4() => navigateTo(OnboardingScreen4.route);
  
  /// Navigate to a specific onboarding page (0-based index)
  void navigateToOnboardingPage(int pageIndex) {
    // Convert 0-based index to 1-based page number for URL
    final pageNumber = pageIndex + 1;
    if (pageNumber == 1) {
      pushRoute(OnboardingPage.onboarding1);
    } else if (pageNumber == 2) {
      pushRoute(OnboardingPage.onboarding2);
    } else if (pageNumber == 3) {
      pushRoute(OnboardingPage.onboarding3);
    } else {
      // Fallback to dynamic route
      pushRoute('/onboarding/$pageNumber');
    }
  }

  // Auth navigation helpers (to be implemented)
  // void navigateToLogin() => navigateTo(LoginScreen.route);
  // void navigateToRegister() => navigateTo(RegisterScreen.route);

  // Home navigation helper (to be implemented)
  // void navigateToHome() => navigateTo(HomeScreen.route);
}

