import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/profile/domain/entities/customer_profile.dart';

void main() {
  group('CustomerProfile', () {
    test('parses profile summary and ownership counts', () {
      final profile = CustomerProfile.fromJson({
        'id': 'customer-1',
        'firstName': 'Asha',
        'lastName': 'Rao',
        'fullName': 'Asha Rao',
        'phone': '9876543210',
        'email': 'asha@example.com',
        'addressLine1': '12 MG Road',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'postalCode': '560001',
        'memberSince': '2024-02-01T10:00:00Z',
        'tenantName': 'Alagendra Automobiles',
        'vehicleCount': 1,
        'enquiryCount': 3,
        'activeServiceBookingCount': 1,
      });

      expect(profile.displayName, 'Asha Rao');
      expect(profile.initials, 'AR');
      expect(profile.formattedAddress, '12 MG Road, Bengaluru, Karnataka, 560001');
      expect(profile.vehicleCount, 1);
      expect(profile.activeServiceBookingCount, 1);
    });

    test('handles missing optional contact details', () {
      final profile = CustomerProfile.fromJson({
        'id': 'customer-2',
        'firstName': 'Ravi',
        'fullName': 'Ravi',
        'phone': '9000000000',
        'vehicleCount': 0,
        'enquiryCount': 0,
        'activeServiceBookingCount': 0,
      });

      expect(profile.initials, 'R');
      expect(profile.email, isNull);
      expect(profile.hasAddress, isFalse);
      expect(profile.formattedAddress, isNull);
    });

    test('profile update draft includes only editable fields', () {
      const draft = ProfileUpdateDraft(
        firstName: 'Asha',
        lastName: 'Rao',
        email: 'asha@example.com',
        city: 'Bengaluru',
      );

      final json = draft.toJson();
      expect(json['firstName'], 'Asha');
      expect(json.containsKey('phone'), isFalse);
    });
  });
}
