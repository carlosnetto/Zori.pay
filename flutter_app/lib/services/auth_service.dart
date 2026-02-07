import 'package:web/web.dart' as web;
import 'package:flutter_app/services/api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _api = ApiClient();
  String? _intermediateToken;

  String get _redirectUri => '${web.window.location.origin}/auth/callback';

  Future<void> initiateGoogleLogin() async {
    final data = await _api.post('/auth/google', body: {
      'redirect_uri': _redirectUri,
    });
    final url = data['authorization_url'] as String;
    web.window.location.href = url;
  }

  Future<Map<String, dynamic>> handleGoogleCallback(String code) async {
    final data = await _api.post('/auth/google/callback', body: {
      'code': code,
      'redirect_uri': _redirectUri,
    });
    _intermediateToken = data['intermediate_token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    _api.setUser(user);
    return user;
  }

  Future<void> bypassPasskey() async {
    if (_intermediateToken == null) {
      throw ApiException('No intermediate token available', 0);
    }
    final data = await _api.post(
      '/auth/dev/bypass-passkey',
      bearerToken: _intermediateToken,
    );
    _api.setTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    _intermediateToken = null;
  }

  Future<void> logout() async {
    final token = _api.getAccessToken();
    if (token != null) {
      try {
        await _api.post('/auth/logout');
      } catch (_) {}
    }
    _api.clearTokens();
  }

  Map<String, dynamic>? getUser() => _api.getUser();

  bool isAuthenticated() => _api.getAccessToken() != null;
}
