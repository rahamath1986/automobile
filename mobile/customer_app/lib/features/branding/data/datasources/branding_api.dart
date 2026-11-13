import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/branding.dart';

class BrandingApi {
  BrandingApi(this._client);

  final ApiClient _client;

  Future<Branding> fetchCurrent() async {
    final payload = await _client.get('/branding/current');
    if (payload is Map<String, dynamic>) {
      return Branding.fromJson(payload);
    }
    return Branding.fallback(AppConfig.dealerCode);
  }
}
