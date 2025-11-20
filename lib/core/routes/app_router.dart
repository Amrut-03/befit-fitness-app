import 'package:befit_fitness_app/src/auth/presentation/screens/email_password_auth_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_in_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_up_page.dart';
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
        redirect: (context, state) {
          final pageNumber = int.tryParse(state.pathParameters['page'] ?? '1') ?? 1;
          
          // Page 4 or higher goes to the login screen
          if (pageNumber >= 4) {
            return LoginPage.route;
          }
          
          // Convert 1-based to 0-based index (pages 1-3 become indices 0-2)
          final pageIndex = pageNumber - 1;
          
          // Redirect to first page if invalid
          if (pageIndex < 0 || pageIndex >= OnboardingContentRepository.totalPages) {
            return OnboardingPage.onboarding1;
          }
          
          // No redirect needed, continue to builder
          return null;
        },
        builder: (context, state) {
          final pageNumber = int.tryParse(state.pathParameters['page'] ?? '1') ?? 1;
          
          // Convert 1-based to 0-based index (pages 1-3 become indices 0-2)
          final pageIndex = pageNumber - 1;
          
          // Double-check validation in builder (safety net)
          // If somehow we get here with an invalid index, redirect to login
          if (pageIndex < 0 || pageIndex >= OnboardingContentRepository.totalPages || pageNumber >= 4) {
            // Redirect to login immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(LoginPage.route);
            });
            // Return a temporary loading widget while redirecting
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
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
      GoRoute(
        path: EmailPasswordAuthPage.route,
        name: 'email-password-auth',
        builder: (context, state) => const EmailPasswordAuthPage(),
      ),
      GoRoute(
        path: SignInPage.route,
        name: 'sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: SignUpPage.route,
        name: 'sign-up',
        builder: (context, state) => const SignUpPage(),
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

