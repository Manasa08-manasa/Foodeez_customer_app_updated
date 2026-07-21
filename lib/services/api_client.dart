import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'token_store.dart';

/// Thrown for any non-2xx response or network failure.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic body;
  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Minimal typed HTTP client — the Dart equivalent of the two axios
/// instances in api.ts (`api` and `customerApi`). Two singletons are exposed
/// at the bottom of this file with the same split the web frontend uses.
class ApiClient {
  final String baseUrl;

  /// Whether requests carry the customer JWT (mirrors the customerApi
  /// request interceptor that injects `Authorization: Bearer <token>`).
  final bool authenticated;

  const ApiClient({required this.baseUrl, this.authenticated = false});

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated && TokenStore.isLoggedIn) {
      headers['Authorization'] = 'Bearer ${TokenStore.token}';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    final qp = <String, String>{};
    query?.forEach((k, v) {
      if (v != null) qp[k] = v.toString();
    });
    return Uri.parse('$base$p').replace(queryParameters: qp.isEmpty ? null : qp);
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = res.body;
      }
    }
    if (!ok) {
      final msg = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'Request failed (${res.statusCode})';
      throw ApiException(msg, statusCode: res.statusCode, body: body);
    }
    return body;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .get(_uri(path, query), headers: _headers())
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Request timed out', statusCode: null);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .post(_uri(path, query),
              headers: _headers(), body: data == null ? null : jsonEncode(data))
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Request timed out', statusCode: null);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    try {
      final res = await http
          .patch(_uri(path),
              headers: _headers(), body: data == null ? null : jsonEncode(data))
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Request timed out', statusCode: null);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  Future<dynamic> delete(String path, {Object? data}) async {
    try {
      final res = await http
          .delete(_uri(path),
              headers: _headers(), body: data == null ? null : jsonEncode(data))
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw ApiException('Request timed out', statusCode: null);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }
}

/// Default backend — public customer auth (send-otp / signup / login / …).
ApiClient get defaultApi => ApiClient(baseUrl: ApiConfig.defaultBaseUrl);

/// Customer backend — carries the customer JWT on guarded endpoints.
ApiClient get customerApi =>
    ApiClient(baseUrl: ApiConfig.customerBaseUrl, authenticated: true);

/// Public customer discovery — no JWT (guest + avoids 401→mock when token expired).
ApiClient get publicCustomerApi =>
    ApiClient(baseUrl: ApiConfig.customerBaseUrl, authenticated: false);

