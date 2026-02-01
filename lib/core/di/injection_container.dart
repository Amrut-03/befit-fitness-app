import 'package:befit_fitness_app/src/fitness_tracker/data/datasources/google_fit_data_source.dart';
import 'package:befit_fitness_app/src/fitness_tracker/data/datasources/google_fit_data_source_impl.dart';
import 'package:befit_fitness_app/src/fitness_tracker/data/repositories/google_fit_repository_impl.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/repositories/google_fit_repository.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/usecase/get_aggregated_data_usecase.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/usecase/get_fitness_data_usecase.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/usecase/get_today_steps_usecase.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/usecase/request_permissions_usecase.dart';
import 'package:befit_fitness_app/src/fitness_tracker/domain/usecase/write_steps_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/core/config/app_config.dart';
import 'package:befit_fitness_app/core/network/dio_client.dart';
import 'package:befit_fitness_app/core/network/network_info.dart';
import 'package:befit_fitness_app/core/network/network_info_impl.dart';
import 'package:befit_fitness_app/src/auth/data/datasources/auth_remote_data_source.dart';
import 'package:befit_fitness_app/src/auth/data/repositories/auth_repository_impl.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/google_sign_in_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/handle_authenticated_user_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/sign_out_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/get_current_user_usecase.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/datasources/user_profile_remote_data_source.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/usecase/save_user_profile_usecase.dart';
import 'package:befit_fitness_app/src/home/data/datasources/home_remote_data_source.dart';
import 'package:befit_fitness_app/src/home/data/repositories/home_repository_impl.dart';
import 'package:befit_fitness_app/src/home/domain/repositories/home_repository.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_health_metrics_usecase.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_user_profile_usecase.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_fitness_data_with_permissions_usecase.dart';
import 'package:befit_fitness_app/src/fitness_tracker/presentation/services/permission_service.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_api_config.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_api_config_impl.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_db_data_source.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_remote_data_source.dart';
import 'package:befit_fitness_app/src/workout/data/repositories/exercise_repository_impl.dart';
import 'package:befit_fitness_app/src/workout/domain/repositories/exercise_repository.dart';
import 'package:befit_fitness_app/src/workout/domain/usecases/get_exercises_usecase.dart';
import 'package:befit_fitness_app/src/workout/domain/usecases/get_exercise_filters_usecase.dart';
import 'package:befit_fitness_app/src/workout/domain/usecases/get_exercise_by_id_usecase.dart';
import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_bloc.dart';
import 'package:befit_fitness_app/src/my_food_items/data/datasources/food_items_remote_data_source.dart';
import 'package:befit_fitness_app/src/my_food_items/data/repositories/food_items_repository_impl.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/repositories/food_items_repository.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/usecases/get_food_items_usecase.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/usecases/delete_food_item_usecase.dart';
import 'package:befit_fitness_app/src/my_food_items/presentation/bloc/my_food_items_bloc.dart';
import 'package:befit_fitness_app/src/home/data/services/meal_alarm_service.dart';
import 'package:befit_fitness_app/src/home/data/services/delete_account_service.dart';

/// GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initDependencyInjection() async {
  // Core Network Services
  getIt.registerLazySingleton<DioClient>(() => DioClient());
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // Firebase
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // Google Sign-In - Version 6.1.5 (stable version with traditional API)
  // For Android, serverClientId (Web Client ID) is required to get idToken
  // Get this from Firebase Console > Project Settings > Your apps > Web app
  // Added Google Fit scopes for health data access
  // Now using AppConfig to load from environment variables
  getIt.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(
      scopes: [
        'email',
        'profile',
        'https://www.googleapis.com/auth/fitness.activity.read',
        'https://www.googleapis.com/auth/fitness.activity.write',
        'https://www.googleapis.com/auth/fitness.heart_rate.read',
        'https://www.googleapis.com/auth/fitness.body.read',
        'https://www.googleapis.com/auth/fitness.location.read',
      ],
      // Web Client ID from environment variable or fallback
      serverClientId: AppConfig.googleSignInServerClientId,
    ),
  );

  // Auth Remote Data Source
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      googleSignIn: getIt<GoogleSignIn>(),
    ),
  );

  // Auth Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );

  // User Profile Remote Data Source (needed before HandleAuthenticatedUserUseCase)
  getIt.registerLazySingleton<UserProfileRemoteDataSource>(
    () => UserProfileRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // User Profile Repository (needed before HandleAuthenticatedUserUseCase)
  getIt.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      remoteDataSource: getIt<UserProfileRemoteDataSource>(),
    ),
  );

  // Auth Use Cases
  getIt.registerLazySingleton<GoogleSignInUseCase>(
    () => GoogleSignInUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<HandleAuthenticatedUserUseCase>(
    () => HandleAuthenticatedUserUseCase(getIt<UserProfileRepository>()),
  );

  getIt.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  // Auth BLoC (factory - new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      googleSignInUseCase: getIt<GoogleSignInUseCase>(),
      signOutUseCase: getIt<SignOutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      handleAuthenticatedUserUseCase: getIt<HandleAuthenticatedUserUseCase>(),
    ),
  );

  // Profile Onboarding Use Cases
  getIt.registerLazySingleton<SaveUserProfileUseCase>(
    () => SaveUserProfileUseCase(getIt<UserProfileRepository>()),
  );

  // Home Remote Data Source
  getIt.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // Home Repository
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      getIt<HomeRemoteDataSource>(),
    ),
  );

  // Home Use Cases
  getIt.registerLazySingleton<GetHealthMetricsUseCase>(
    () => GetHealthMetricsUseCase(getIt<HomeRepository>()),
  );

  getIt.registerLazySingleton<GetUserProfileUseCase>(
    () => GetUserProfileUseCase(getIt<HomeRepository>()),
  );


  // Google Fit Data Source - Uses REST API directly
  getIt.registerLazySingleton<GoogleFitDataSource>(
    () => GoogleFitDataSourceImpl(
      googleSignIn: getIt<GoogleSignIn>(),
    ),
  );

  // Google Fit Repository
  getIt.registerLazySingleton<GoogleFitRepository>(
    () => GoogleFitRepositoryImpl(
      dataSource: getIt<GoogleFitDataSource>(),
    ),
  );

  // Google Fit Use Cases
  getIt.registerLazySingleton<GetTodayStepsUseCase>(
    () => GetTodayStepsUseCase(getIt<GoogleFitRepository>()),
  );

  getIt.registerLazySingleton<GetFitnessDataUseCase>(
    () => GetFitnessDataUseCase(getIt<GoogleFitRepository>()),
  );

  getIt.registerLazySingleton<RequestPermissionsUseCase>(
    () => RequestPermissionsUseCase(getIt<GoogleFitRepository>()),
  );

  getIt.registerLazySingleton<GetAggregatedDataUseCase>(
    () => GetAggregatedDataUseCase(getIt<GoogleFitRepository>()),
  );

  getIt.registerLazySingleton<WriteStepsUseCase>(
    () => WriteStepsUseCase(getIt<GoogleFitRepository>()),
  );

  // Home Fitness Data Use Case
  getIt.registerLazySingleton<GetFitnessDataWithPermissionsUseCase>(
    () => GetFitnessDataWithPermissionsUseCase(
      repository: getIt<GoogleFitRepository>(),
      getFitnessDataUseCase: getIt<GetFitnessDataUseCase>(),
      requestPermissionsUseCase: getIt<RequestPermissionsUseCase>(),
    ),
  );

  // Permission Service
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionService(),
  );

  // Workout / Exercise (SOLID: abstractions first, then implementations)
  getIt.registerLazySingleton<ExerciseApiConfig>(
    () => ExerciseApiConfigImpl(),
  );

  getIt.registerLazySingleton<ExerciseRemoteDataSource>(
    () => ExerciseDbDataSource(
      dioClient: getIt<DioClient>(),
      apiConfig: getIt<ExerciseApiConfig>(),
    ),
  );

  getIt.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(getIt<ExerciseRemoteDataSource>()),
  );

  getIt.registerLazySingleton<GetExercisesUseCase>(
    () => GetExercisesUseCase(getIt<ExerciseRepository>()),
  );

  getIt.registerLazySingleton<GetExerciseFiltersUseCase>(
    () => GetExerciseFiltersUseCase(getIt<ExerciseRepository>()),
  );

  getIt.registerLazySingleton<GetExerciseByIdUseCase>(
    () => GetExerciseByIdUseCase(getIt<ExerciseRepository>()),
  );

  getIt.registerFactory<WorkoutBloc>(
    () => WorkoutBloc(
      getExercisesUseCase: getIt<GetExercisesUseCase>(),
      getExerciseFiltersUseCase: getIt<GetExerciseFiltersUseCase>(),
    ),
  );

  // Food Items Remote Data Source
  getIt.registerLazySingleton<FoodItemsRemoteDataSource>(
    () => FoodItemsRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
    ),
  );

  // Food Items Repository
  getIt.registerLazySingleton<FoodItemsRepository>(
    () => FoodItemsRepositoryImpl(getIt<FoodItemsRemoteDataSource>()),
  );

  // Food Items Use Cases
  getIt.registerLazySingleton<GetFoodItemsUseCase>(
    () => GetFoodItemsUseCase(getIt<FoodItemsRepository>()),
  );

  getIt.registerLazySingleton<DeleteFoodItemUseCase>(
    () => DeleteFoodItemUseCase(getIt<FoodItemsRepository>()),
  );

  // Food Items BLoC (factory - new instance each time)
  getIt.registerFactory<MyFoodItemsBloc>(
    () => MyFoodItemsBloc(
      getFoodItemsUseCase: getIt<GetFoodItemsUseCase>(),
      deleteFoodItemUseCase: getIt<DeleteFoodItemUseCase>(),
    ),
  );

  // Update Home BLoC registration with new dependencies
  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      getHealthMetricsUseCase: getIt<GetHealthMetricsUseCase>(),
      getUserProfileUseCase: getIt<GetUserProfileUseCase>(),
      getFitnessDataWithPermissionsUseCase: getIt<GetFitnessDataWithPermissionsUseCase>(),
      permissionService: getIt<PermissionService>(),
    ),
  );

  // Meal alarm service for meal reminder notifications
  getIt.registerLazySingleton<MealAlarmService>(() => MealAlarmService());

  // Delete account service – deletes all user data from Firestore
  getIt.registerLazySingleton<DeleteAccountService>(
    () => DeleteAccountService(firestore: getIt<FirebaseFirestore>()),
  );

  // Wait for all async registrations to complete
  await getIt.allReady();
}