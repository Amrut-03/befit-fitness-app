import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/email_password_auth_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_in_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_up_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen2.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen3.dart';
import 'package:befit_fitness_app/src/permissions/presentation/screens/permissions_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using GoRouter
class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: LoginPage.route,
    redirect: (context, state) async {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;
      final isLoginRoute = location == LoginPage.route ||
          location == EmailPasswordAuthPage.route ||
          location == SignInPage.route ||
          location == SignUpPage.route;
      final isOnboardingRoute = location.startsWith('/profile-onboarding');
      final isHomeRoute = location == HomePage.route;
      final isPermissionsRoute = location == PermissionsScreen.route;

      // If user is authenticated
      if (firebaseUser != null) {
        // If trying to access login/auth pages, check profile and redirect accordingly
        if (isLoginRoute) {
          try {
            final profileRepository = getIt<UserProfileRepository>();
            final documentId = (firebaseUser.email ?? firebaseUser.uid).toLowerCase();
            final isComplete = await profileRepository.isProfileComplete(documentId);
            
            if (isComplete) {
              return HomePage.route;
            } else {
              return ProfileOnboardingScreen1.route;
            }
          } catch (e) {
            // On error, go to onboarding
            return ProfileOnboardingScreen1.route;
          }
        }
        // If on home route, check if profile is complete and permissions granted
        if (isHomeRoute) {
          try {
            final profileRepository = getIt<UserProfileRepository>();
            final documentId = (firebaseUser.email ?? firebaseUser.uid).toLowerCase();
            final isComplete = await profileRepository.isProfileComplete(documentId);
            
            if (!isComplete) {
              return ProfileOnboardingScreen1.route;
            }
            
            // Check if permissions are granted (only check once, not every time)
            // This will be handled by the permissions screen
          } catch (e) {
            // On error, allow access
          }
        }
        
        // Allow access to permissions screen
        if (isPermissionsRoute) {
          return null;
        }
        // If on onboarding route, check if profile is complete
        if (isOnboardingRoute) {
          try {
            final profileRepository = getIt<UserProfileRepository>();
            final documentId = (firebaseUser.email ?? firebaseUser.uid).toLowerCase();
            final isComplete = await profileRepository.isProfileComplete(documentId);
            
            if (isComplete) {
              return HomePage.route;
            }
          } catch (e) {
            // On error, allow access
          }
        }
        // Allow access to other routes
        return null;
      } else {
        // User is not authenticated
        // If trying to access protected routes, redirect to login
        if (!isLoginRoute && !isOnboardingRoute && !isHomeRoute) {
          return LoginPage.route;
        }
        // Allow access to login/auth pages
        return null;
      }
    },
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
      // Permissions route
      GoRoute(
        path: PermissionsScreen.route,
        name: 'permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      // Home route
      GoRoute(
        path: HomePage.route,
        name: 'home',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => getIt<HomeBloc>(),
            ),
            BlocProvider(
              create: (context) => getIt<AuthBloc>(),
            ),
          ],
          child: const HomePage(),
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
