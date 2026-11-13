import '../../../../core/network/api_client.dart';
import '../../domain/entities/customer_profile.dart';

class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<CustomerProfile> getProfile() async {
    final payload = await _client.get('/customers/me');
    if (payload is Map<String, dynamic>) {
      return CustomerProfile.fromJson(payload);
    }
    throw StateError('Customer profile was not returned.');
  }

  Future<CustomerProfile> updateProfile(ProfileUpdateDraft draft) async {
    final payload = await _client.put('/customers/me', body: draft.toJson());
    if (payload is Map<String, dynamic>) {
      return CustomerProfile.fromJson(payload);
    }
    throw StateError('Updated customer profile was not returned.');
  }
}
