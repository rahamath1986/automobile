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
  CustomerProfile _buildSampleProfile() {
    final session = ref.read(authControllerProvider).value;
    final phone = session?.phone ?? '8015581405';
    final isSpecialUser = phone.contains('8015581405');

    return CustomerProfile(
      id: session?.userId ?? 'usr-sample-01',
      firstName: isSpecialUser ? 'Rahamath' : (session?.firstName ?? 'Customer'),
      lastName: isSpecialUser ? 'Ali Khan' : 'User',
      fullName: isSpecialUser ? 'Rahamath Ali Khan' : (session?.fullName ?? 'Customer User'),
      phone: phone,
      email: session?.email ?? 'rahamath.customer@motosaas.in',
      addressLine1: 'Theni Main Road, Kotchadai',
      city: 'Madurai',
      state: 'Tamil Nadu',
      postalCode: '625016',
      memberSince: DateTime.now().subtract(const Duration(days: 240)),
      tenantId: session?.tenantId ?? 'tenant-alagendra',
      tenantName: session?.tenantName ?? 'Alagendra Motors',
      vehicleCount: 2,
      enquiryCount: 2,
      activeServiceBookingCount: 1,
    );
  }

  @override
  Future<CustomerProfile?> build() async {
    final session = ref.watch(authControllerProvider).value;
    if (session == null) return null;
    try {
      final profile = await ref.watch(profileRepositoryProvider).getProfile();
      if (profile.fullName.isNotEmpty && profile.fullName != 'Rider') {
        return profile;
      }
      return _buildSampleProfile();
    } catch (_) {
      return _buildSampleProfile();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(authControllerProvider).value;
      if (session == null) return null;
      try {
        final profile = await ref.read(profileRepositoryProvider).getProfile();
        if (profile.fullName.isNotEmpty && profile.fullName != 'Rider') {
          return profile;
        }
        return _buildSampleProfile();
      } catch (_) {
        return _buildSampleProfile();
      }
    });
  }

  Future<CustomerProfile> save(ProfileUpdateDraft draft) async {
    final updated = await ref.read(profileRepositoryProvider).updateProfile(draft);
    state = AsyncData(updated);
    return updated;
  }
}
