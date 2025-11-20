import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
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

  // Note: pop() and canPop() are provided by go_router's extension
  // Use context.pop() or context.canPop() directly from go_router

  // Auth navigation helpers
  void navigateToLogin() => navigateTo(LoginPage.route);

  // void navigateToRegister() => navigateTo(RegisterScreen.route);

  // Home navigation helper (to be implemented)
  // void navigateToHome() => navigateTo(HomeScreen.route);
}

