import '../entities/customer_profile.dart';

abstract class ProfileRepository {
  Future<CustomerProfile> getProfile();
  Future<CustomerProfile> updateProfile(ProfileUpdateDraft draft);
}
