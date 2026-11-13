import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/leads/domain/entities/lead.dart';

void main() {
  group('Lead requests', () {
    test('EnquiryDraft serialises guest contact and colour preference', () {
      final draft = EnquiryDraft(
        branchId: 'branch-1',
        variantId: 'variant-1',
        colorId: 'colour-1',
        notes: 'Interested in exchange',
        expectedPurchaseDate: DateTime(2026, 12, 1),
        firstName: 'Asha',
        lastName: 'Rao',
        phone: '9876543210',
        email: 'asha@example.com',
      );

      final json = draft.toJson();
      expect(json['branchId'], 'branch-1');
      expect(json['colorId'], 'colour-1');
      expect(json['firstName'], 'Asha');
      expect(json['phone'], '9876543210');
      expect(json['expectedPurchaseDate'], isNotNull);
    });

    test('TestRideDraft serialises scheduled time as UTC ISO-8601', () {
      final draft = TestRideDraft(
        branchId: 'branch-1',
        variantId: 'variant-1',
        scheduledAt: DateTime(2026, 12, 1, 10, 30),
        drivingLicenseNumber: 'KA0120200000000',
        firstName: 'Ravi',
        phone: '9000000000',
      );

      final json = draft.toJson();
      expect(json['scheduledAt'], endsWith('Z'));
      expect(json['drivingLicenseNumber'], 'KA0120200000000');
    });

    test('Enquiry parses status, source and optional executive', () {
      final enquiry = Enquiry.fromJson({
        'id': 'enquiry-1',
        'branchId': 'branch-1',
        'branchName': 'Indiranagar',
        'variantId': 'variant-1',
        'variantName': 'R15 V4',
        'modelName': 'R15',
        'colorName': 'Racing Blue',
        'status': 'CONTACTED',
        'source': 'MOBILEAPP',
        'createdAt': '2026-11-01T09:00:00Z',
        'assignedSalesExecutiveName': 'Kiran',
      });

      expect(enquiry.status, 'CONTACTED');
      expect(enquiry.colorName, 'Racing Blue');
      expect(enquiry.assignedSalesExecutiveName, 'Kiran');
      expect(enquiry.createdAt.year, 2026);
    });
  });
}
