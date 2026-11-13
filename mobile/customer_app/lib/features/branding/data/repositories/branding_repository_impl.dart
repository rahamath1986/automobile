import '../datasources/branding_api.dart';
import '../../domain/entities/branding.dart';
import '../../domain/repositories/branding_repository.dart';

class BrandingRepositoryImpl implements BrandingRepository {
  BrandingRepositoryImpl(this._api);

  final BrandingApi _api;

  @override
  Future<Branding> fetchBranding() => _api.fetchCurrent();
}
