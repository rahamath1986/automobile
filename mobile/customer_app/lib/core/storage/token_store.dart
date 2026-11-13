import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure, key-partitioned token vault for the customer domain.
/// The staff experience (Phase 12) will use a separate partition in this app.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'customer.access_token';
  static const _refreshTokenKey = 'customer.refresh_token';
  static const _sessionKey = 'customer.session';

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _session;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get session => _session;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> load() async {
    try {
      _accessToken = await _storage.read(key: _accessTokenKey);
      _refreshToken = await _storage.read(key: _refreshTokenKey);
      final rawSession = await _storage.read(key: _sessionKey);
      if (rawSession != null && rawSession.isNotEmpty) {
        final decoded = jsonDecode(rawSession);
        if (decoded is Map<String, dynamic>) {
          _session = decoded;
        }
      }
    } catch (_) {
      // Secure storage can be unavailable in unit tests or on unsupported hosts.
      _accessToken = null;
      _refreshToken = null;
      _session = null;
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> session,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _session = session;

    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(key: _sessionKey, value: jsonEncode(session));
    } catch (_) {
      // Keep the in-memory session even if persistence is unavailable.
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _session = null;

    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _sessionKey);
    } catch (_) {
      // Ignore storage failures during logout.
    }
  }
}
