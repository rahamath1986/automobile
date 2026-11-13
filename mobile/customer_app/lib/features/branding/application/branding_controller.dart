import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../data/datasources/branding_api.dart';
import '../data/repositories/branding_repository_impl.dart';
import '../domain/entities/branding.dart';
import '../domain/repositories/branding_repository.dart';

final brandingApiProvider = Provider<BrandingApi>((ref) {
  return BrandingApi(ref.watch(apiClientProvider));
});

final brandingRepositoryProvider = Provider<BrandingRepository>((ref) {
  return BrandingRepositoryImpl(ref.watch(brandingApiProvider));
});

final brandingControllerProvider = AsyncNotifierProvider<BrandingController, Branding>(
  BrandingController.new,
);

class BrandingController extends AsyncNotifier<Branding> {
  @override
  Future<Branding> build() async {
    try {
      return await ref.watch(brandingRepositoryProvider).fetchBranding();
    } catch (_) {
      // The customer app must still render a branded shell when the API is offline.
      return Branding.fallback(AppConfig.dealerCode);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        return await ref.read(brandingRepositoryProvider).fetchBranding();
      } catch (_) {
        return Branding.fallback(AppConfig.dealerCode);
      }
    });
  }
}
