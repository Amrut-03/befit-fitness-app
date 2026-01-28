import 'package:dio/dio.dart';

/// Interceptor that retries failed requests with exponential backoff
class RetryInterceptor extends Interceptor {
  final int retries;
  final List<Duration> retryDelays;
  final Dio _dio;

  RetryInterceptor({
    required this.retries,
    required this.retryDelays,
    required Dio dio,
  }) : _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
      
      if (retryCount < retries) {
        final delay = retryCount < retryDelays.length
            ? retryDelays[retryCount]
            : retryDelays.last;
        
        await Future.delayed(delay);
        
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        
        try {
          // Retry the request using the same Dio instance
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // If retry also fails, continue with error
          if (e is DioException) {
            super.onError(e, handler);
            return;
          }
        }
      }
    }
    
    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors or 5xx server errors
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500 &&
            err.response!.statusCode! < 600);
  }
}
