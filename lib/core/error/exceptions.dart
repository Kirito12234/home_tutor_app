class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network request failed']) : super(message);
}

class CacheException extends AppException {
  CacheException([String message = 'Cache operation failed']) : super(message);
}
