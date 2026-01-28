import 'package:befit_fitness_app/core/config/app_config.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_api_config.dart';

/// ExerciseDB API config implementation (SRP: config responsibility only)
class ExerciseApiConfigImpl implements ExerciseApiConfig {
  @override
  String? get apiKey {
    try {
      final key = AppConfig.rapidApiKey;
      return key.isEmpty ? null : key;
    } catch (_) {
      return null;
    }
  }
}
