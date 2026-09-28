/// Thrown by ApiClient for any non-2xx response or network failure.
/// `statusCode` is null for network-level failures (no connection, timeout).
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;
}
