/// Abstraction for ExerciseDB API configuration (SRP: config is separate from data fetching)
abstract class ExerciseApiConfig {
  String? get apiKey;
}
