import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// REST API client for Google Fit API
class GoogleFitRestClient {
  final Dio _dio;
  final GoogleSignIn _googleSignIn;
  static const String _baseUrl = 'https://www.googleapis.com/fitness/v1';

  GoogleFitRestClient({
    required GoogleSignIn googleSignIn,
    Dio? dio,
  })  : _googleSignIn = googleSignIn,
        _dio = dio ?? Dio();

  /// Get access token from Google Sign-In
  Future<String?> _getAccessToken() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        debugPrint('GoogleFitRestClient: No signed in account');
        return null;
      }

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('GoogleFitRestClient: Error getting access token: $e');
      return null;
    }
  }

  /// Make authenticated request to Google Fit API
  Future<Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available. Please sign in with Google.');
    }

    final url = '$_baseUrl$endpoint';
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await _dio.get(
            url,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
        case 'POST':
          return await _dio.post(
            url,
            data: data,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
        case 'PATCH':
          return await _dio.patch(
            url,
            data: data,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please sign in again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Permission denied. Please grant Google Fit permissions.');
      }
      throw Exception('Google Fit API error: ${e.message}');
    }
  }

  /// Get aggregated data for a data type
  Future<Map<String, dynamic>> getAggregatedData({
    required String dataTypeName,
    required DateTime startTime,
    required DateTime endTime,
    int? bucketDurationMillis,
  }) async {
    final startTimeMillis = startTime.millisecondsSinceEpoch;
    final endTimeMillis = endTime.millisecondsSinceEpoch;

    final requestBody = {
      'aggregateBy': [
        {
          'dataTypeName': dataTypeName,
        }
      ],
      'bucketByTime': {
        'durationMillis': bucketDurationMillis ?? 86400000, // 1 day default
      },
      'startTimeMillis': startTimeMillis.toString(),
      'endTimeMillis': endTimeMillis.toString(),
    };

    final response = await _makeRequest(
      'POST',
      '/users/me/dataset:aggregate',
      data: requestBody,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Get data sources
  Future<List<Map<String, dynamic>>> getDataSources({
    String? dataTypeName,
  }) async {
    try {
      final queryParams = dataTypeName != null
          ? {'dataTypeName': dataTypeName}
          : null;

      final response = await _makeRequest(
        'GET',
        '/users/me/dataSources',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['dataSource'] as List<dynamic>? ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('GoogleFitRestClient: Error getting data sources: $e');
      return [];
    }
  }

  /// Get dataset for a data source
  Future<Map<String, dynamic>> getDataset({
    required String dataSourceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final startTimeNanos = startTime.millisecondsSinceEpoch * 1000000;
    final endTimeNanos = endTime.millisecondsSinceEpoch * 1000000;

    final response = await _makeRequest(
      'GET',
      '/users/me/dataSources/$dataSourceId/datasets/$startTimeNanos-$endTimeNanos',
    );

    return response.data as Map<String, dynamic>;
  }

  /// Write data point to a data source
  Future<void> writeDataPoint({
    required String dataSourceId,
    required String dataTypeName,
    required int value,
    required DateTime startTime,
    required DateTime endTime,
    String? unit,
  }) async {
    final startTimeMillis = startTime.millisecondsSinceEpoch;
    final endTimeMillis = endTime.millisecondsSinceEpoch;

    final requestBody = {
      'dataSourceId': dataSourceId,
      'maxEndTimeNs': (endTimeMillis * 1000000).toString(),
      'minStartTimeNs': (startTimeMillis * 1000000).toString(),
      'point': [
        {
          'startTimeNanos': (startTimeMillis * 1000000).toString(),
          'endTimeNanos': (endTimeMillis * 1000000).toString(),
          'value': [
            {
              'intVal': value,
            }
          ],
        }
      ],
    };

    await _makeRequest(
      'PATCH',
      '/users/me/dataSources/$dataSourceId/datasets/${startTimeMillis * 1000000}-${endTimeMillis * 1000000}',
      data: requestBody,
    );
  }

  /// Write floating point data point
  Future<void> writeFloatDataPoint({
    required String dataSourceId,
    required String dataTypeName,
    required double value,
    required DateTime startTime,
    required DateTime endTime,
    String? unit,
  }) async {
    final startTimeMillis = startTime.millisecondsSinceEpoch;
    final endTimeMillis = endTime.millisecondsSinceEpoch;

    final requestBody = {
      'dataSourceId': dataSourceId,
      'maxEndTimeNs': (endTimeMillis * 1000000).toString(),
      'minStartTimeNs': (startTimeMillis * 1000000).toString(),
      'point': [
        {
          'startTimeNanos': (startTimeMillis * 1000000).toString(),
          'endTimeNanos': (endTimeMillis * 1000000).toString(),
          'value': [
            {
              'fpVal': value,
            }
          ],
        }
      ],
    };

    await _makeRequest(
      'PATCH',
      '/users/me/dataSources/$dataSourceId/datasets/${startTimeMillis * 1000000}-${endTimeMillis * 1000000}',
      data: requestBody,
    );
  }

  /// Create or get data source
  Future<String> createOrGetDataSource({
    required String dataTypeName,
    required String dataStreamName,
    String? deviceUid,
    String? deviceManufacturer,
    String? deviceModel,
    String? deviceType,
  }) async {
    // First, try to get existing data source
    try {
      final dataSources = await getDataSources(dataTypeName: dataTypeName);
      Map<String, dynamic>? existing;
      try {
        existing = dataSources.firstWhere(
          (ds) => (ds['dataStreamName'] ?? ds['dataSourceName']) == dataStreamName,
        );
      } catch (e) {
        existing = null;
      }

      if (existing != null) {
        final streamId = existing['dataStreamId'] ?? existing['dataSourceId'];
        if (streamId != null) {
          return streamId as String;
        }
      }
    } catch (e) {
      debugPrint('GoogleFitRestClient: Error getting data sources: $e');
    }

    // Create new data source if not found
    // Use a unique data source ID format: derived:dataTypeName:appName:dataStreamName
    final dataSourceId = 'derived:$dataTypeName:com.befit_fitness.app:$dataStreamName';
    
    final requestBody = {
      'dataStreamId': dataSourceId,
      'dataStreamName': dataStreamName,
      'type': 'raw',
      'dataType': {
        'name': dataTypeName,
        'field': [
          {
            'name': 'value',
            'format': dataTypeName.contains('weight') || dataTypeName.contains('height') || dataTypeName.contains('heart_rate') ? 'floatPoint' : 'integer',
          }
        ],
      },
      if (deviceUid != null || deviceManufacturer != null || deviceModel != null)
        'device': {
          if (deviceUid != null) 'uid': deviceUid,
          if (deviceManufacturer != null) 'manufacturer': deviceManufacturer,
          if (deviceModel != null) 'model': deviceModel,
          if (deviceType != null) 'type': deviceType,
        },
    };

    try {
      final response = await _makeRequest(
        'POST',
        '/users/me/dataSources',
        data: requestBody,
      );

      final data = response.data as Map<String, dynamic>;
      return (data['dataStreamId'] ?? data['dataSourceId'] ?? dataSourceId) as String;
    } catch (e) {
      // If creation fails, return the ID we tried to use
      debugPrint('GoogleFitRestClient: Error creating data source, using ID: $dataSourceId');
      return dataSourceId;
    }
  }
}

