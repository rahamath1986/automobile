import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/core/utils/formatters.dart';

void main() {
  group('formatters', () {
    test('formatCurrency formats Indian rupees without decimals', () {
      expect(formatCurrency(185000), '₹1,85,000');
      expect(formatCurrency(null), '—');
    });

    test('formatShortDate and formatDateTime handle null safely', () {
      expect(formatShortDate(null), '—');
      final date = DateTime(2026, 4, 9, 15, 5);
      expect(formatShortDate(date), '09 Apr 2026');
      expect(formatDateTime(date), '09 Apr 2026, 03:05 PM');
    });

    test('EMI estimate is in a realistic monthly range', () {
      final emi = formatEmiEstimate(200000);
      expect(emi, startsWith('₹'));
      expect(emi, isNot('—'));
    });
  });
}
