import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen2.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen3.dart';
import 'package:befit_fitness_app/src/permissions/presentation/screens/permissions_screen.dart';
import 'package:befit_fitness_app/src/activity_tracking/presentation/screens/activity_tracking_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activity_item.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/food_product_details_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
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
      final uri = state.uri;
      final fullPath = uri.toString();
      final uriPath = uri.path;
      final uriQuery = uri.query;
      final isLoginRoute = location == LoginPage.route;
      final isOnboardingRoute = location.startsWith('/profile-onboarding');
      // Check if home route (with or without query parameters)
      final isHomeRoute = location == HomePage.route || 
          uriPath == HomePage.route ||
          fullPath.startsWith(HomePage.route);
      final isPermissionsRoute = location == PermissionsScreen.route;

      // If user is authenticated
      if (firebaseUser != null) {
        // If trying to access login/auth pages, check profile and redirect accordingly
        if (isLoginRoute) {
          try {
            final profileRepository = getIt<UserProfileRepository>();
            final userId = firebaseUser.uid;
            
            print('[AppRouter] Checking profile completion for userId: $userId');
            
            // Retry checking profile completion up to 5 times to handle Firestore eventual consistency
            // This is especially important on app restart when Firestore might not be immediately ready
            bool isComplete = false;
            Exception? lastError;
            bool hasReadSuccess = false;
            
            for (int i = 0; i < 5; i++) {
              try {
                print('[AppRouter] Attempt ${i + 1}/5: Checking profile completion...');
                isComplete = await profileRepository.isProfileComplete(userId);
                hasReadSuccess = true; // We successfully read from Firestore
                print('[AppRouter] Attempt ${i + 1}/5: Profile complete = $isComplete');
                if (isComplete) {
                  print('[AppRouter] Profile is complete! Breaking retry loop.');
                  break;
                }
                if (i < 4) {
                  final delay = Duration(milliseconds: 300 + (i * 100));
                  print('[AppRouter] Profile not complete, waiting ${delay.inMilliseconds}ms before retry...');
                  await Future.delayed(delay);
                }
              } catch (e) {
                lastError = e is Exception ? e : Exception(e.toString());
                print('[AppRouter] Attempt ${i + 1}/5: Error checking profile: $e');
                // On error, try again or allow access on last retry
                if (i < 4) {
                  final delay = Duration(milliseconds: 300 + (i * 100));
                  print('[AppRouter] Error occurred, waiting ${delay.inMilliseconds}ms before retry...');
                  await Future.delayed(delay);
                }
              }
            }
            
            print('[AppRouter] Final check results:');
            print('[AppRouter]   - isComplete: $isComplete');
            print('[AppRouter]   - hasReadSuccess: $hasReadSuccess');
            print('[AppRouter]   - lastError: $lastError');
            
            // If profile is complete, go to home
            if (isComplete) {
              print('[AppRouter] Redirecting to HOME (profile is complete)');
              return HomePage.route;
            }
            
            // If we successfully read from Firestore and profile is not complete, go to onboarding
            // But if we couldn't read (errors), go to home to prevent redirect loops
            // This handles cases where Firestore is slow or unavailable on app restart
            if (hasReadSuccess && lastError == null) {
              // We successfully read and profile is not complete
              print('[AppRouter] Redirecting to ONBOARDING (profile is not complete)');
              return ProfileOnboardingScreen1.route;
            } else {
              // Couldn't reliably determine status (read errors), go to home
              // The home route will handle the profile check with its own retry logic
              print('[AppRouter] Redirecting to HOME (could not reliably determine profile status - read errors occurred)');
              return HomePage.route;
            }
          } catch (e) {
            // On any error, go to home (not onboarding) to prevent redirect loops
            // The home route will handle the profile check with its own retry logic
            print('[AppRouter] Exception in login route redirect: $e');
            print('[AppRouter] Redirecting to HOME (exception occurred)');
            return HomePage.route;
          }
        }
        // If on home route, check if profile is complete
        if (isHomeRoute) {
          try {
            // Check if we're coming from permissions screen using query parameter
            // Check multiple ways to ensure we catch it
            final queryParams = uri.queryParameters;
            final fromPermissions = queryParams['fromPermissions'] == 'true' ||
                queryParams.containsKey('fromPermissions') ||
                fullPath.contains('fromPermissions=true') ||
                fullPath.contains('?fromPermissions=true') ||
                uri.toString().contains('fromPermissions=true') ||
                uriQuery.contains('fromPermissions=true') ||
                uri.query.contains('fromPermissions=true');
            
            if (fromPermissions) {
              // Coming from permissions screen, allow access (profile should already be complete)
              // No need to check profile completion
              return null;
            }
            
            // Not from permissions, check profile completion with retry logic
            final profileRepository = getIt<UserProfileRepository>();
            final userId = firebaseUser.uid;
            
            // Retry checking profile completion up to 5 times to handle Firestore eventual consistency
            bool isComplete = false;
            Exception? lastError;
            for (int i = 0; i < 5; i++) {
              try {
                isComplete = await profileRepository.isProfileComplete(userId);
                if (isComplete) break;
                if (i < 4) await Future.delayed(Duration(milliseconds: 300 + (i * 100)));
              } catch (e) {
                lastError = e is Exception ? e : Exception(e.toString());
                // On error, try again or allow access on last retry
                if (i < 4) {
                  await Future.delayed(Duration(milliseconds: 300 + (i * 100)));
                }
              }
            }
            
            // If still not complete after retries, redirect to onboarding
            // But only if we're certain it's not complete (not just a read error)
            if (!isComplete && lastError == null) {
              return ProfileOnboardingScreen1.route;
            }
            
            // Profile is complete or there was a read error, allow access to home
            // Permissions check is handled by permissions screen
          } catch (e) {
            // On any error, allow access (might be a temporary Firestore read issue)
            // This prevents redirect loops when navigating from onboarding/permissions
            return null;
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
            final userId = firebaseUser.uid;
            final isComplete = await profileRepository.isProfileComplete(userId);
            
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
      // Activity tracking route
      GoRoute(
        path: ActivityTrackingScreen.route,
        name: 'activity-tracking',
        builder: (context, state) {
          final activity = state.extra;
          if (activity is Activity) {
            return ActivityTrackingScreen(activity: activity);
          }
          // Fallback - should not happen
          return const Scaffold(
            body: Center(child: Text('Activity not provided')),
          );
        },
      ),
      // Barcode scanner route
      GoRoute(
        path: BarcodeScannerScreen.route,
        name: 'barcode-scanner',
        builder: (context, state) => const BarcodeScannerScreen(),
      ),
      // Food product details route
      GoRoute(
        path: FoodProductDetailsScreen.route,
        name: 'food-product-details',
        builder: (context, state) {
          final product = state.extra;
          if (product is FoodProduct) {
            return FoodProductDetailsScreen(product: product);
          }
          // Fallback - should not happen
          return const Scaffold(
            body: Center(child: Text('Product not provided')),
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
