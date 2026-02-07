import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import 'package:flutter_app/main.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  String get _baseUrl => '${web.window.location.origin}/v1';

  String? getAccessToken() {
    final token = web.window.localStorage.getItem('access_token');
    return (token != null && token.isNotEmpty) ? token : null;
  }

  void setTokens({required String accessToken, required String refreshToken}) {
    web.window.localStorage.setItem('access_token', accessToken);
    web.window.localStorage.setItem('refresh_token', refreshToken);
  }

  void clearTokens() {
    web.window.localStorage.removeItem('access_token');
    web.window.localStorage.removeItem('refresh_token');
    web.window.localStorage.removeItem('user');
  }

  void setUser(Map<String, dynamic> user) {
    web.window.localStorage.setItem('user', jsonEncode(user));
  }

  Map<String, dynamic>? getUser() {
    final userStr = web.window.localStorage.getItem('user');
    if (userStr == null || userStr.isEmpty) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _headers({String? bearerToken}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = bearerToken ?? getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _handleUnauthorized() {
    clearTokens();
    isLoggedIn.value = false;
    viewNotifier.value = AppView.landing;
  }

  Future<Map<String, dynamic>> get(String path, {String? bearerToken}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(bearerToken: bearerToken),
    );
    if (response.statusCode == 401) {
      _handleUnauthorized();
      throw ApiException('Session expired', 401);
    }
    if (response.statusCode >= 400) {
      throw ApiException(_parseError(response.body), response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(bearerToken: bearerToken),
      body: body != null ? jsonEncode(body) : '{}',
    );
    if (response.statusCode == 401) {
      _handleUnauthorized();
      throw ApiException('Session expired', 401);
    }
    if (response.statusCode >= 400) {
      throw ApiException(_parseError(response.body), response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
    String? bearerToken,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    final token = bearerToken ?? getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    request.files.addAll(files.values);
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 401) {
      _handleUnauthorized();
      throw ApiException('Session expired', 401);
    }
    if (streamed.statusCode >= 400) {
      throw ApiException(_parseError(body), streamed.statusCode);
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        return json['error']?.toString() ??
            json['message']?.toString() ??
            'Request failed';
      }
    } catch (_) {}
    return 'Request failed';
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
