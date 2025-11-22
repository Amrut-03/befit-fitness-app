import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/src/auth/data/datasources/auth_remote_data_source.dart';
import 'package:befit_fitness_app/src/auth/data/repositories/auth_repository_impl.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/google_sign_in_usecase.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/datasources/user_profile_remote_data_source.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';

/// GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initDependencyInjection() async {
  // Firebase Auth
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Google Sign-In - Version 6.1.5 (stable version with traditional API)
  // For Android, serverClientId (Web Client ID) is required to get idToken
  // Get this from Firebase Console > Project Settings > Your apps > Web app
  getIt.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(
      scopes: ['email', 'profile'],
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

  // Auth BLoC (factory - new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      googleSignInUseCase: getIt<GoogleSignInUseCase>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );

  // Firestore
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

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

  // Wait for all async registrations to complete
  await getIt.allReady();
}