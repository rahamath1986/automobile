import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/providers.dart';
import '../data/datasources/profile_api.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/entities/customer_profile.dart';
import '../domain/repositories/profile_repository.dart';

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(apiClientProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileApiProvider));
});

final profileControllerProvider = AsyncNotifierProvider<ProfileController, CustomerProfile?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<CustomerProfile?> {
  @override
  Future<CustomerProfile?> build() async {
    final session = ref.watch(authControllerProvider).value;
    if (session == null) return null;
    return ref.watch(profileRepositoryProvider).getProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(authControllerProvider).value;
      if (session == null) return null;
      return ref.read(profileRepositoryProvider).getProfile();
    });
  }

  Future<CustomerProfile> save(ProfileUpdateDraft draft) async {
    final updated = await ref.read(profileRepositoryProvider).updateProfile(draft);
    state = AsyncData(updated);
    return updated;
  }
}
