import '../../domain/entities/customer_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  @override
  Future<CustomerProfile> getProfile() => _api.getProfile();

  @override
  Future<CustomerProfile> updateProfile(ProfileUpdateDraft draft) => _api.updateProfile(draft);
}
