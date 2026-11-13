import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/auth/domain/entities/auth_session.dart';

void main() {
  group('AuthSession', () {
    test('parses the customer login envelope', () {
      final session = AuthSession.fromApiResponse({
        'accessToken': 'access-123',
        'refreshToken': 'refresh-123',
        'user': {
          'id': 'user-1',
          'fullName': 'Asha Rao',
          'phone': '9876543210',
          'email': 'asha@example.com',
          'userType': 'CUSTOMER',
          'tenantId': 'tenant-1',
          'tenantCode': 'ALAGENDRA',
          'tenantName': 'Alagendra Automobiles',
          'roles': ['CUSTOMER'],
        },
      });

      expect(session.accessToken, 'access-123');
      expect(session.fullName, 'Asha Rao');
      expect(session.firstName, 'Asha');
      expect(session.isCustomer, isTrue);
      expect(session.roles, ['CUSTOMER']);
    });

    test('round-trips through storage safely', () {
      final session = AuthSession.fromStorage({
        'accessToken': 'access-123',
        'refreshToken': 'refresh-123',
        'userId': 'user-1',
        'fullName': 'Ravi Kumar',
        'phone': '9000000000',
        'userType': 'CUSTOMER',
      });

      expect(session.userId, 'user-1');
      expect(session.firstName, 'Ravi');
      expect(session.isCustomer, isTrue);
      expect(session.email, isNull);
    });
  });
}
