import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/splash/presentation/screens/splash_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen2.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen3.dart';
import 'package:befit_fitness_app/src/fitness_tracker/presentation/screens/permissions_screen.dart';
import 'package:befit_fitness_app/src/activity_tracking/presentation/screens/activity_tracking_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activity_item.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/food_product_details_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/profile_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/notifications_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/goal_editing_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/daily_macros_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/diet_planning_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/plan_your_diet_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/diet_plan_detail_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/manual_food_entry_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/my_food_items_screen.dart';
import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_event.dart';
import 'package:befit_fitness_app/src/workout/presentation/screens/workout_list_screen.dart';
import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using GoRouter
class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: false,
    initialLocation: SplashScreen.route,
      redirect: (context, state) async {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;
      if (location == SplashScreen.route) return null;
      final uri = state.uri;
      final fullPath = uri.toString();
      final uriPath = uri.path;
      final uriQuery = uri.query;
      final isLoginRoute = location == LoginPage.route;
      final isOnboardingRoute = location.startsWith('/profile-onboarding');
      final isHomeRoute = location == HomePage.route || 
          uriPath == HomePage.route ||
          fullPath.startsWith(HomePage.route);
      final isPermissionsRoute = location == PermissionsScreen.route;

      if (firebaseUser != null) {
        if (isLoginRoute) {
          try {
            final profileRepository = getIt<UserProfileRepository>();
            final userId = firebaseUser.uid;
            bool isComplete = false;
            Exception? lastError;
            bool hasReadSuccess = false;

            for (int i = 0; i < 5; i++) {
              try {
                isComplete = await profileRepository.isProfileComplete(userId);
                hasReadSuccess = true;
                if (isComplete) break;
                if (i < 4) {
                  await Future.delayed(Duration(milliseconds: 300 + (i * 100)));
                }
              } catch (e) {
                lastError = e is Exception ? e : Exception(e.toString());
                if (i < 4) {
                  await Future.delayed(Duration(milliseconds: 300 + (i * 100)));
                }
              }
            }

            if (isComplete) return HomePage.route;
            if (hasReadSuccess && lastError == null) {
              return ProfileOnboardingScreen1.route;
            }
            return HomePage.route;
          } catch (_) {
            return HomePage.route;
          }
        }
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
        path: SplashScreen.route,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
      // Profile route (edit onboarding info)
      GoRoute(
        path: ProfilePage.route,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      // Notifications route (empty placeholder)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      // Goal editing route
      GoRoute(
        path: GoalEditingPage.route,
        name: 'goal-editing',
        builder: (context, state) => const GoalEditingPage(),
      ),
      // Daily macros route
      GoRoute(
        path: DailyMacrosScreen.route,
        name: 'daily-macros',
        builder: (context, state) => const DailyMacrosScreen(),
      ),
      // Diet planning route
      GoRoute(
        path: DietPlanningScreen.route,
        name: 'diet-planning',
        builder: (context, state) => const DietPlanningScreen(),
      ),
      // Plan your diet route
      GoRoute(
        path: PlanYourDietScreen.route,
        name: 'plan-your-diet',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PlanYourDietScreen(
              planId: extra['planId'] as String?,
              planData: extra['planData'] as Map<String, dynamic>?,
            );
          }
          return const PlanYourDietScreen();
        },
      ),
      // Diet plan detail route
      GoRoute(
        path: DietPlanDetailScreen.route,
        name: 'diet-plan-detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return DietPlanDetailScreen(
              planId: extra['planId'] as String,
              planData: extra['planData'] as Map<String, dynamic>,
            );
          }
          return const Scaffold(
            body: Center(child: Text('Diet plan data not provided')),
          );
        },
      ),
      // Manual food entry route
      GoRoute(
        path: ManualFoodEntryScreen.route,
        name: 'manual-food-entry',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return ManualFoodEntryScreen(
              product: extra['product'] as FoodProduct?,
              docId: extra['docId'] as String?,
              type: extra['type'] as String?,
            );
          }
          return const ManualFoodEntryScreen();
        },
      ),
      GoRoute(
        path: MyFoodItemsScreen.route,
        name: 'my-food-items',
        builder: (context, state) => const MyFoodItemsScreen(),
      ),
      // Workout list route (DIP: Bloc provided here, screen depends on abstraction)
      GoRoute(
        path: WorkoutListScreen.route,
        name: 'workout-list',
        builder: (context, state) {
          final bodyPart = state.uri.queryParameters['bodyPart'];
          return BlocProvider(
            create: (context) => getIt<WorkoutBloc>()
              ..add(const LoadExerciseFiltersEvent())
              ..add(LoadExercisesEvent(reset: true, bodyPart: bodyPart)),
            child: WorkoutListScreen(initialBodyPart: bodyPart),
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
