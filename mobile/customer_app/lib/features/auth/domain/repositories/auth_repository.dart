import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phone);
  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
    String? firstName,
    String? lastName,
  });
  Future<AuthSession?> restoreSession();
  Future<void> logout();
}
