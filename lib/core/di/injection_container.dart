import 'package:get_it/get_it.dart';

/// GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initDependencyInjection() async {
  // Register services, repositories, use cases, etc. here
  // Example:
  // getIt.registerLazySingleton(() => AuthRepository());
  // getIt.registerFactory(() => AuthUseCase(getIt()));
  
  // Wait for all async registrations to complete
  await getIt.allReady();
}

