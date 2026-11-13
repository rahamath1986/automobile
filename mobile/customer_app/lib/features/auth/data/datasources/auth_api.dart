import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_session.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<void> requestOtp(String phone) async {
    await _client.post(
      '/auth/customer/request-otp',
      body: {
        'phone': phone,
        'dealerCode': AppConfig.dealerCode,
      },
    );
  }

  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
    String? firstName,
    String? lastName,
  }) async {
    final payload = await _client.post(
      '/auth/customer/verify-otp',
      body: {
        'phone': phone,
        'otp': otp,
        'dealerCode': AppConfig.dealerCode,
        'firstName': firstName,
        'lastName': lastName,
      },
    );

    if (payload is Map<String, dynamic>) {
      return AuthSession.fromApiResponse(payload);
    }

    throw StateError('Unexpected authentication response.');
  }
}
