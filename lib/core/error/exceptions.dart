/// Exceptions ném ra từ tầng data (datasource / api client).
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No network connection']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local read/write error']);
}

class ParsingException implements Exception {
  final String message;
  const ParsingException([this.message = 'Invalid response data']);
}
