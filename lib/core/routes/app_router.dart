import 'package:befit_fitness_app/src/auth/presentation/screens/email_password_auth_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_in_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_up_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_screen.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen2.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen3.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using GoRouter
class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: LoginPage.route,
    routes: [
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
      // Profile onboarding routes
      GoRoute(
        path: ProfileOnboardingScreen1.route,
        name: 'profile-onboarding-1',
        builder: (context, state) {
          final profile = state.extra;
          return ProfileOnboardingScreen1(
            initialProfile: profile is UserProfile ? profile : null,
          );
        },
      ),
      GoRoute(
        path: ProfileOnboardingScreen2.route,
        name: 'profile-onboarding-2',
        builder: (context, state) => const ProfileOnboardingScreen2(),
      ),
      GoRoute(
        path: ProfileOnboardingScreen3.route,
        name: 'profile-onboarding-3',
        builder: (context, state) => const ProfileOnboardingScreen3(),
      ),
      // Home route
      GoRoute(
        path: HomeScreen.route,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
