import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:befit_fitness_app/core/config/app_config.dart';
import 'package:befit_fitness_app/core/network/retry_interceptor.dart';

/// Centralized Dio client configuration with timeouts, retries, and interceptors
class DioClient {
  final Dio _dio;
  final Logger _logger;

  DioClient({
    Dio? dio,
    Logger? logger,
  })  : _dio = dio ?? _createDio(),
        _logger = logger ?? Logger();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: AppConfig.networkTimeout,
        receiveTimeout: AppConfig.networkTimeout,
        sendTimeout: AppConfig.networkTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor (only in debug mode)
    if (AppConfig.isDevelopment) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (object) {
            final logger = Logger();
            logger.d(object);
          },
        ),
      );
    }

    // Add retry interceptor with exponential backoff
    dio.interceptors.add(
      RetryInterceptor(
        retries: AppConfig.maxRetryAttempts,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
        dio: dio,
      ),
    );

    return dio;
  }

  /// Get the configured Dio instance
  Dio get dio => _dio;

  /// Make a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('GET request failed: $path', error: e);
      rethrow;
    }
  }

  /// Make a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('POST request failed: $path', error: e);
      rethrow;
    }
  }

  /// Make a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('PUT request failed: $path', error: e);
      rethrow;
    }
  }

  /// Make a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      _logger.e('DELETE request failed: $path', error: e);
      rethrow;
    }
  }
}
