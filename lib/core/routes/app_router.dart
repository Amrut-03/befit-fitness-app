import 'package:befit_fitness_app/src/auth/presentation/screens/email_password_auth_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_in_page.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_up_page.dart';
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
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
