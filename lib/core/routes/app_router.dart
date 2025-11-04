import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/onboarding/domain/models/onboarding_content.dart';
import 'package:befit_fitness_app/src/onboarding/presentation/screens/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using GoRouter
class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: OnboardingPage.onboarding1,
    routes: [
      // Dynamic onboarding page route (handles pages 1-3)
      GoRoute(
        path: OnboardingPage.onboarding,
        name: 'onboarding',
        builder: (context, state) {
          final pageNumber = int.tryParse(state.pathParameters['page'] ?? '1') ?? 1;
          
          // Page 4 goes to the login screen
          if (pageNumber >= 4) {
            return const LoginPage();
          }
          
          // Convert 1-based to 0-based index (pages 1-3 become indices 0-2)
          final pageIndex = pageNumber - 1;
          
          // Validate page index is within bounds
          if (pageIndex < 0 || pageIndex >= OnboardingContentRepository.totalPages) {
            // Redirect to first page if invalid
            return const OnboardingPage(pageIndex: 0);
          }
          
          return OnboardingPage(pageIndex: pageIndex);
        },
      ),
      // Explicit routes for direct navigation
      GoRoute(
        path: OnboardingPage.onboarding1,
        name: 'onboarding1',
        builder: (context, state) => const OnboardingPage(pageIndex: 0),
      ),
      GoRoute(
        path: OnboardingPage.onboarding2,
        name: 'onboarding2',
        builder: (context, state) => const OnboardingPage(pageIndex: 1),
      ),
      GoRoute(
        path: OnboardingPage.onboarding3,
        name: 'onboarding3',
        builder: (context, state) => const OnboardingPage(pageIndex: 2),
      ),
      GoRoute(
        path: LoginPage.route,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // TODO: Add auth routes when implemented
      // GoRoute(
      //   path: LoginScreen.route,
      //   name: 'login',
      //   builder: (context, state) => const LoginScreen(),
      // ),
      // TODO: Add home route when implemented
      // GoRoute(
      //   path: HomeScreen.route,
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

