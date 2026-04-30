class ServerException implements Exception {
  const ServerException(this.message);
  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  const CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}
