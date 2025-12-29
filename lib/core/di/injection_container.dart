import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:befit_fitness_app/src/auth/data/datasources/auth_remote_data_source.dart';
import 'package:befit_fitness_app/src/auth/data/repositories/auth_repository_impl.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/google_sign_in_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/handle_authenticated_user_usecase.dart';
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
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_data_source.dart';
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_data_source_impl.dart';
import 'package:befit_fitness_app/src/google_fit/data/repositories/google_fit_repository_impl.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/get_today_steps_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/get_fitness_data_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/request_permissions_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/get_aggregated_data_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/write_steps_usecase.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_fitness_data_with_permissions_usecase.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';

/// GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initDependencyInjection() async {
  // Firebase
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // Google Sign-In - Version 6.1.5 (stable version with traditional API)
  // For Android, serverClientId (Web Client ID) is required to get idToken
  // Get this from Firebase Console > Project Settings > Your apps > Web app
  // Added Google Fit scopes for health data access
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
      // Web Client ID from Firebase Console (required for idToken on Android)
      // This is the client_id with client_type: 3 in google-services.json
      serverClientId: '475383477382-qon5oc39997dtltulhm5jqjsnli7g89d.apps.googleusercontent.com',
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

  // Auth Use Cases
  getIt.registerLazySingleton<GoogleSignInUseCase>(
    () => GoogleSignInUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<HandleAuthenticatedUserUseCase>(
    () => HandleAuthenticatedUserUseCase(getIt<UserProfileRepository>()),
  );

  // Auth BLoC (factory - new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      googleSignInUseCase: getIt<GoogleSignInUseCase>(),
      authRepository: getIt<AuthRepository>(),
      handleAuthenticatedUserUseCase: getIt<HandleAuthenticatedUserUseCase>(),
    ),
  );

  // User Profile Remote Data Source
  getIt.registerLazySingleton<UserProfileRemoteDataSource>(
    () => UserProfileRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // User Profile Repository
  getIt.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      remoteDataSource: getIt<UserProfileRemoteDataSource>(),
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


  // Google Fit - Health instance
  // The health package automatically uses Health Connect on Android if available
  getIt.registerLazySingleton<Health>(
    () => Health(),
  );
  
  // Configure Health instance - required before use
  // This must be called before any health operations
  final health = getIt<Health>();
  await health.configure();

  // Google Fit Data Source
  getIt.registerLazySingleton<GoogleFitDataSource>(
    () => GoogleFitDataSourceImpl(
      health: getIt<Health>(),
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

  // Update Home BLoC registration with new dependencies
  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      getHealthMetricsUseCase: getIt<GetHealthMetricsUseCase>(),
      getUserProfileUseCase: getIt<GetUserProfileUseCase>(),
      getFitnessDataWithPermissionsUseCase: getIt<GetFitnessDataWithPermissionsUseCase>(),
      permissionService: getIt<PermissionService>(),
    ),
  );

  // Wait for all async registrations to complete
  await getIt.allReady();
}