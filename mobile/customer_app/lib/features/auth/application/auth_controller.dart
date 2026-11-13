import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/datasources/auth_api.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/auth_repository.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authApiProvider),
    ref.watch(tokenStoreProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthSession?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  Future<void> requestOtp(String phone) async {
    await ref.read(authRepositoryProvider).requestOtp(phone);
  }

  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
    String? firstName,
    String? lastName,
  }) async {
    final session = await ref.read(authRepositoryProvider).verifyOtp(
          phone: phone,
          otp: otp,
          firstName: firstName,
          lastName: lastName,
        );

    state = AsyncData(session);
    return session;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final isSignedInProvider = Provider<bool>((ref) {
  final session = ref.watch(authControllerProvider).value;
  return session != null;
});
