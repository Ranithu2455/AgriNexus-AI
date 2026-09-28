import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin wrapper around package:http that adds:
///  - JSON encode/decode
///  - Authorization header injection
///  - automatic one-time refresh-token retry on 401
///  - multipart file upload support
///  - consistent ApiException on failure
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _tokenStorage = TokenStorage.instance;
  final _http = http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedQuery = query?.map((k, v) => MapEntry(k, v?.toString()))
      ?..removeWhere((k, v) => v == null);
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: normalizedQuery?.isNotEmpty == true
          ? normalizedQuery!.map((k, v) => MapEntry(k, v!))
          : null,
    );
  }

  Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _tokenStorage.getAccessToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send(() async {
      final headers = await _authHeaders();
      return _http.get(_uri(path, query), headers: headers);
    });
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    return _send(() async {
      final headers = auth ? await _authHeaders() : {'Content-Type': 'application/json'};
      return _http.post(_uri(path), headers: headers, body: jsonEncode(body ?? {}));
    });
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    return _send(() async {
      final headers = await _authHeaders();
      return _http.put(_uri(path), headers: headers, body: jsonEncode(body ?? {}));
    });
  }

  Future<dynamic> delete(String path) async {
    return _send(() async {
      final headers = await _authHeaders();
      return _http.delete(_uri(path), headers: headers);
    });
  }

  /// Multipart upload (e.g. profile image, disease/pest detection images).
  /// [extraFields] are added as plain form fields alongside the file.
  Future<dynamic> uploadFile(
    String path, {
    required File file,
    required String fieldName,
    Map<String, String>? extraFields,
  }) async {
    return _send(() async {
      final token = await _tokenStorage.getAccessToken();
      final request = http.MultipartRequest('POST', _uri(path));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (extraFields != null) request.fields.addAll(extraFields);
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      final streamed = await _http.send(request);
      return http.Response.fromStream(streamed);
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() doRequest) async {
    http.Response response;
    try {
      response = await doRequest().timeout(const Duration(seconds: 20));
    } on SocketException {
      throw ApiException('Could not connect. Check your internet connection.');
    } catch (e) {
      throw ApiException('Could not connect. Check your internet connection.');
    }

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        try {
          response = await doRequest().timeout(const Duration(seconds: 20));
        } catch (e) {
          throw ApiException('Could not connect. Check your internet connection.');
        }
      }
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (isSuccess) return decoded;

    String message = 'Something went wrong. Please try again.';
    if (decoded is Map && decoded['detail'] != null) {
      message = decoded['detail'].toString();
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _http.post(
        _uri('/users/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode != 200) {
        await _tokenStorage.clear();
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    }
  }
}
