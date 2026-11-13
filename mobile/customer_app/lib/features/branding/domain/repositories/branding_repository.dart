import '../entities/branding.dart';

abstract class BrandingRepository {
  Future<Branding> fetchBranding();
}
