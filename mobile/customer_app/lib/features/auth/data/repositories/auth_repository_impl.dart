import '../../../../core/storage/token_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokenStore);

  final AuthApi _api;
  final TokenStore _tokenStore;

  @override
  Future<void> requestOtp(String phone) => _api.requestOtp(phone);

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
    String? firstName,
    String? lastName,
  }) async {
    final session = await _api.verifyOtp(
      phone: phone,
      otp: otp,
      firstName: firstName,
      lastName: lastName,
    );

    await _tokenStore.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      session: session.toStorage(),
    );

    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    await _tokenStore.load();
    final stored = _tokenStore.session;
    if (stored == null || _tokenStore.accessToken == null) {
      return null;
    }

    final session = AuthSession.fromStorage(stored);
    return session.accessToken.isEmpty ? null : session;
  }

  @override
  Future<void> logout() => _tokenStore.clear();
}
