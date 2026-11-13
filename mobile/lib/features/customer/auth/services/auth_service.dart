import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/otp_request.dart';
import '../models/otp_response.dart';
import '../models/verify_otp_request.dart';
import '../models/verify_otp_response.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.read(dioProvider);
  return AuthService(dio);
});

class AuthService {
  final Dio _dio;
  AuthService(this._dio);

  /// POST /api/v1/auth/customer/request-otp
  Future<OtpResponse> requestOtp(OtpRequest request) async {
    final resp = await _dio.post(
      '/api/v1/auth/customer/request-otp',
      data: request.toJson(),
    );
    final body = resp.data as Map<String, dynamic>;
    // Backend wraps in { data: { ... } }
    final data = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return OtpResponse.fromJson(data);
  }

  /// POST /api/v1/auth/customer/verify-otp
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    final resp = await _dio.post(
      '/api/v1/auth/customer/verify-otp',
      data: request.toJson(),
    );
    final body = resp.data as Map<String, dynamic>;
    final data = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return VerifyOtpResponse.fromJson(data);
  }

  /// POST /api/v1/auth/refresh-token
  Future<VerifyOtpResponse> refreshToken(String refreshToken) async {
    final resp = await _dio.post(
      '/api/v1/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );
    final body = resp.data as Map<String, dynamic>;
    final data = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return VerifyOtpResponse.fromJson(data);
  }
}

