import 'package:dio/dio.dart';
import 'package:befit_fitness_app/core/network/dio_client.dart';
import 'package:befit_fitness_app/core/utils/logger.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_api_config.dart';
import 'package:befit_fitness_app/src/workout/data/datasources/exercise_remote_data_source.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise_response.dart';

/// Data source for ExerciseDB API (SRP: fetch only; config injected. OCP: single _fetch for all exercise queries)
class ExerciseDbDataSource implements ExerciseRemoteDataSource {
  final DioClient _dioClient;
  final ExerciseApiConfig _apiConfig;
  static const String _baseUrl = 'https://exercisedb-api1.p.rapidapi.com/api/v1';

  ExerciseDbDataSource({
    required DioClient dioClient,
    required ExerciseApiConfig apiConfig,
  })  : _dioClient = dioClient,
        _apiConfig = apiConfig;

  Map<String, String> get _headers {
    final apiKey = _apiConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'RapidAPI key is not configured. Please set EXERCISE_DB_API_KEY in your .env file.',
      );
    }
    return {
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': 'exercisedb-api1.p.rapidapi.com',
    };
  }

  /// Single point for exercise list API (OCP: extend via params, not by adding methods)
  Future<ExerciseResponse> _fetchExerciseResponse(Map<String, dynamic> queryParams) async {
    final response = await _dioClient.get(
      '$_baseUrl/exercises',
      queryParameters: queryParams,
      options: Options(headers: _headers),
    );

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data as Map<String, dynamic>;
      return ExerciseResponse.fromJson(responseData);
    }
    return ExerciseResponse(
      exercises: [],
      meta: ExerciseMeta(total: 0, hasNextPage: false, hasPreviousPage: false),
    );
  }

  @override
  Future<ExerciseResponse> getExercises({
    int? limit,
    String? cursor,
    String? bodyPart,
    String? target,
    String? equipment,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (cursor != null && cursor.isNotEmpty) queryParams['cursor'] = cursor;
      if (bodyPart != null && bodyPart.isNotEmpty) queryParams['bodyParts'] = bodyPart;
      if (target != null && target.isNotEmpty) queryParams['target'] = target;
      if (equipment != null && equipment.isNotEmpty) queryParams['equipment'] = equipment;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;

      final result = await _fetchExerciseResponse(queryParams);
      if (result.exercises.isNotEmpty) {
        AppLogger.d(
          'ExerciseDB: Meta - total: ${result.meta.total}, hasNextPage: ${result.meta.hasNextPage}, nextCursor: ${result.meta.nextCursor}',
        );
      }
      return result;
    } catch (e) {
      AppLogger.e('ExerciseDB: Error fetching exercises', e);
      rethrow;
    }
  }

  @override
  Future<List<Exercise>> getAllExercisesAllPages({int limitPerPage = 50}) async {
    final allExercises = <Exercise>[];
    String? cursor;
    int pageCount = 0;
    const maxPages = 100;

    while (pageCount < maxPages) {
      pageCount++;
      AppLogger.d('ExerciseDB: Fetching page $pageCount with cursor: $cursor');

      final response = await getExercises(limit: limitPerPage, cursor: cursor);
      allExercises.addAll(response.exercises);

      if (!response.meta.hasNextPage) {
        AppLogger.d('ExerciseDB: All pages loaded. Total exercises: ${allExercises.length}');
        break;
      }
      cursor = response.meta.nextCursor;
    }

    return allExercises;
  }

  static const List<String> _fallbackBodyParts = [
    'waist', 'chest', 'back', 'shoulders', 'arms', 'legs', 'cardio',
  ];
  static const List<String> _fallbackTargets = [
    'abs', 'biceps', 'triceps', 'chest', 'back', 'shoulders', 'legs', 'glutes',
  ];
  static const List<String> _fallbackEquipment = [
    'body weight', 'dumbbell', 'barbell', 'cable', 'machine', 'kettlebell', 'resistance band',
  ];

  @override
  Future<List<String>> getBodyPartList() async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/exercises/bodyPartList',
        options: Options(headers: _headers),
      );
      return _parseStringListResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.d('ExerciseDB: bodyPartList endpoint not found (404), using fallback list');
        return List.from(_fallbackBodyParts);
      }
      AppLogger.e('ExerciseDB: Error fetching body parts', e);
      return List.from(_fallbackBodyParts);
    } catch (e) {
      AppLogger.e('ExerciseDB: Error fetching body parts', e);
      return List.from(_fallbackBodyParts);
    }
  }

  @override
  Future<List<String>> getTargetList() async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/exercises/targetList',
        options: Options(headers: _headers),
      );
      return _parseStringListResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.d('ExerciseDB: targetList endpoint not found (404), using fallback list');
        return List.from(_fallbackTargets);
      }
      AppLogger.e('ExerciseDB: Error fetching targets', e);
      return List.from(_fallbackTargets);
    } catch (e) {
      AppLogger.e('ExerciseDB: Error fetching targets', e);
      return List.from(_fallbackTargets);
    }
  }

  @override
  Future<List<String>> getEquipmentList() async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/exercises/equipmentList',
        options: Options(headers: _headers),
      );
      return _parseStringListResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.d('ExerciseDB: equipmentList endpoint not found (404), using fallback list');
        return List.from(_fallbackEquipment);
      }
      AppLogger.e('ExerciseDB: Error fetching equipment', e);
      return List.from(_fallbackEquipment);
    } catch (e) {
      AppLogger.e('ExerciseDB: Error fetching equipment', e);
      return List.from(_fallbackEquipment);
    }
  }

  List<String> _parseStringListResponse(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  Future<Exercise?> getExerciseById(String id) async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/exercises/exercise/$id',
        options: Options(headers: _headers),
      );

      if (response.statusCode == 200 && response.data != null && response.data is Map) {
        return Exercise.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      AppLogger.e('ExerciseDB: Error fetching exercise by ID', e);
      return null;
    }
  }
}
