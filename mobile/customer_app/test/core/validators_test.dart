import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('phone accepts Indian mobile formats', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('+91 98765 43210'), isNull);
    });

    test('phone rejects short numbers and blanks', () {
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone(''), isNotNull);
    });

    test('otp requires exactly six digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('abcdef'), isNotNull);
    });

    test('email is optional but validated when provided', () {
      expect(Validators.email(''), isNull);
      expect(Validators.email('rider@example.com'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('postal code enforces digits', () {
      expect(Validators.postalCode('560001'), isNull);
      expect(Validators.postalCode('AB12'), isNotNull);
    });
  });
}
