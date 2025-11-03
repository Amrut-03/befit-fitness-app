import 'package:befit_fitness_app/core/routes/app_routes.dart';
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
  void navigateToOnboarding1() => navigateTo(AppRoutes.onboarding1);
  void navigateToOnboarding2() => pushRoute(AppRoutes.onboarding2);
  void navigateToOnboarding3() => pushRoute(AppRoutes.onboarding3);
  void navigateToOnboarding4() => navigateTo(AppRoutes.onboarding4);

  // Auth navigation helpers (to be implemented)
  // void navigateToLogin() => navigateTo(AppRoutes.login);
  // void navigateToRegister() => navigateTo(AppRoutes.register);

  // Home navigation helper (to be implemented)
  // void navigateToHome() => navigateTo(AppRoutes.home);
}

