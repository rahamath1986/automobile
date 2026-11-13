import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/otp_request.dart';
import '../models/otp_response.dart';
import '../models/verify_otp_request.dart';
import '../models/verify_otp_response.dart';
import '../services/auth_service.dart';

// ─── Auth Stage Enum ───────────────────────────────────────────────────────────
enum AuthStage { idle, requestingOtp, awaitingOtpEntry, verifyingOtp, authenticated, error }

// ─── State ────────────────────────────────────────────────────────────────────
class AuthState {
  final AuthStage stage;
  final OtpResponse? otpResponse;
  final VerifyOtpResponse? verifyResponse;
  final String? errorMessage;

  const AuthState({
    required this.stage,
    this.otpResponse,
    this.verifyResponse,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStage? stage,
    OtpResponse? otpResponse,
    VerifyOtpResponse? verifyResponse,
    String? errorMessage,
  }) =>
      AuthState(
        stage: stage ?? this.stage,
        otpResponse: otpResponse ?? this.otpResponse,
        verifyResponse: verifyResponse ?? this.verifyResponse,
        errorMessage: errorMessage,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthNotifier(service);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;
  final _secure = const FlutterSecureStorage();

  AuthNotifier(this._service) : super(const AuthState(stage: AuthStage.idle));

  Future<void> requestOtp(String phoneNumber) async {
    state = state.copyWith(stage: AuthStage.requestingOtp);
    try {
      final resp = await _service.requestOtp(OtpRequest(phoneNumber));
      state = state.copyWith(stage: AuthStage.awaitingOtpEntry, otpResponse: resp);
    } catch (e) {
      state = state.copyWith(stage: AuthStage.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String otp) async {
    final requestId = state.otpResponse?.requestId;
    if (requestId == null) {
      state = state.copyWith(stage: AuthStage.error, errorMessage: 'No OTP request in progress.');
      return;
    }
    state = state.copyWith(stage: AuthStage.verifyingOtp);
    try {
      final resp = await _service.verifyOtp(VerifyOtpRequest(requestId: requestId, otp: otp));
      await _secure.write(key: 'customer_access_token', value: resp.accessToken);
      await _secure.write(key: 'customer_refresh_token', value: resp.refreshToken);
      await _secure.write(key: 'customer_expires_at', value: resp.expiresAt.toIso8601String());
      state = state.copyWith(stage: AuthStage.authenticated, verifyResponse: resp);
    } catch (e) {
      state = state.copyWith(stage: AuthStage.error, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _secure.delete(key: 'customer_access_token');
    await _secure.delete(key: 'customer_refresh_token');
    await _secure.delete(key: 'customer_expires_at');
    state = const AuthState(stage: AuthStage.idle);
  }

  Future<bool> isLoggedIn() async {
    final token = await _secure.read(key: 'customer_access_token');
    final expiresAt = await _secure.read(key: 'customer_expires_at');
    if (token == null || expiresAt == null) return false;
    return DateTime.parse(expiresAt).isAfter(DateTime.now());
  }
}

