import 'package:befit_fitness_app/core/routes/app_routes.dart';
import 'package:befit_fitness_app/src/onboarding/presentation/pages/onboarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using GoRouter
class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.onboarding1,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding1,
        name: 'onboarding1',
        builder: (context, state) => const OnboardingScreen1(),
      ),
      GoRoute(
        path: AppRoutes.onboarding2,
        name: 'onboarding2',
        builder: (context, state) => const OnboardingScreen2(),
      ),
      GoRoute(
        path: AppRoutes.onboarding3,
        name: 'onboarding3',
        builder: (context, state) => const OnboardingScreen3(),
      ),
      GoRoute(
        path: AppRoutes.onboarding4,
        name: 'onboarding4',
        builder: (context, state) => const OnboardingScreen4(),
      ),
      // TODO: Add auth routes when implemented
      // GoRoute(
      //   path: AppRoutes.login,
      //   name: 'login',
      //   builder: (context, state) => const LoginScreen(),
      // ),
      // TODO: Add home route when implemented
      // GoRoute(
      //   path: AppRoutes.home,
      //   name: 'home',
      //   builder: (context, state) => const HomeScreen(),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

