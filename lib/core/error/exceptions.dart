/// Base class for exceptions
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  const ServerException(super.message, [super.code]);
}

/// Cache exception
class CacheException extends AppException {
  const CacheException(super.message, [super.code]);
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}
