import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/service/domain/entities/service_entities.dart';

void main() {
  group('Service entities', () {
    test('CustomerVehicle parses ownership details', () {
      final vehicle = CustomerVehicle.fromJson({
        'id': 'vehicle-1',
        'variantId': 'variant-1',
        'modelName': 'R15',
        'variantName': 'R15 V4',
        'registrationNumber': 'KA01AB1234',
        'chassisNumberMasked': 'ME1RG******1234',
        'engineNumberMasked': 'G3E4E******88',
        'deliveryDate': '2026-01-15T00:00:00Z',
        'lastServiceStatus': 'COMPLETED',
      });

      expect(vehicle.registrationNumber, 'KA01AB1234');
      expect(vehicle.chassisNumberMasked, contains('1234'));
      expect(vehicle.lastServiceStatus, 'COMPLETED');
    });

    test('ServiceBookingDraft serialises booking appointment', () {
      final draft = ServiceBookingDraft(
        customerVehicleId: 'vehicle-1',
        branchId: 'branch-1',
        serviceType: 'PERIODIC',
        scheduledDate: DateTime(2026, 12, 2),
        timeSlot: '10:00 - 11:00',
        customerComplaints: 'Chain noise',
      );

      final json = draft.toJson();
      expect(json['serviceType'], 'PERIODIC');
      expect(json['timeSlot'], '10:00 - 11:00');
      expect(json['customerComplaints'], 'Chain noise');
    });

    test('ServiceTracking parses timeline, progress and job card items', () {
      final tracking = ServiceTracking.fromJson({
        'booking': {
          'id': 'booking-1',
          'branchId': 'branch-1',
          'branchName': 'Indiranagar',
          'customerVehicleId': 'vehicle-1',
          'registrationNumber': 'KA01AB1234',
          'modelName': 'R15',
          'variantName': 'R15 V4',
          'serviceType': 'PERIODIC',
          'scheduledDate': '2026-12-02T00:00:00Z',
          'timeSlot': '10:00 - 11:00',
          'status': 'BOOKED',
          'jobCardId': 'job-1',
          'jobCardStatus': 'WORK_IN_PROGRESS',
          'createdAt': '2026-11-20T10:00:00Z',
        },
        'currentStage': 'Work in progress',
        'progressPercent': 55,
        'awaitingCustomerApproval': true,
        'timeline': [
          {'label': 'Checked in', 'completed': true, 'current': false},
          {'label': 'Work in progress', 'completed': false, 'current': true},
        ],
        'jobCard': {
          'id': 'job-1',
          'jobCardNumber': 'JC-2026-001',
          'status': 'WORK_IN_PROGRESS',
          'odometerReading': 4200,
          'fuelLevelPercent': 60,
          'estimatedCost': 2400,
          'customerApproved': false,
          'technicianName': 'Suresh',
          'createdAt': '2026-12-02T05:00:00Z',
          'items': [
            {
              'id': 'item-1',
              'itemType': 'LABOUR',
              'description': 'Periodic service labour',
              'quantity': 1,
              'unitPrice': 900,
              'totalPrice': 900,
              'isApproved': false,
            },
          ],
        },
      });

      expect(tracking.progressPercent, 55);
      expect(tracking.awaitingCustomerApproval, isTrue);
      expect(tracking.timeline, hasLength(2));
      expect(tracking.timeline.last.current, isTrue);
      expect(tracking.jobCard?.items.single.totalPrice, 900);
      expect(tracking.jobCard?.technicianName, 'Suresh');
    });
  });
}
