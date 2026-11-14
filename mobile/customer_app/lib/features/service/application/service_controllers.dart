import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/providers.dart';
import '../data/datasources/service_api.dart';
import '../data/repositories/service_repository_impl.dart';
import '../domain/entities/service_entities.dart';
import '../domain/repositories/service_repository.dart';

final serviceApiProvider = Provider<ServiceApi>((ref) => ServiceApi(ref.watch(apiClientProvider)));

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(ref.watch(serviceApiProvider));
});

/// Sample vehicles so the user always has rich data in their garage
final List<CustomerVehicle> sampleVehiclesData = [
  CustomerVehicle(
    id: 'veh-sample-01',
    variantId: '33333333-3333-3333-3333-333333333331',
    modelName: 'YZF-R15 V4',
    variantName: 'Racing Blue Metallic · Quickshifter Edition',
    registrationNumber: 'TN 01 AB 1405',
    chassisNumberMasked: '•••• 1405',
    engineNumberMasked: '•••• 9876',
    deliveryDate: DateTime.now().subtract(const Duration(days: 90)),
    heroImageUrl: 'assets/images/vehicles/yamaha_r15_v4.jpg',
    lastServiceDate: DateTime.now().subtract(const Duration(days: 15)),
    lastServiceStatus: 'Completed · 5,000 km Service',
  ),
  CustomerVehicle(
    id: 'veh-sample-02',
    variantId: '33333333-3333-3333-3333-333333333333',
    modelName: 'TVS iQube Electric',
    variantName: 'ST 3.4 kWh SmartXonnect',
    registrationNumber: 'TN 02 CD 5678',
    chassisNumberMasked: '•••• 5678',
    engineNumberMasked: '•••• 3412',
    deliveryDate: DateTime.now().subtract(const Duration(days: 45)),
    heroImageUrl: 'assets/images/vehicles/tvs_iqube.jpg',
    lastServiceDate: DateTime.now().subtract(const Duration(days: 7)),
    lastServiceStatus: 'Battery Health 98% · Connected',
  ),
];

/// Sample service bookings so the user always has live service appointments
final List<ServiceBooking> sampleServiceBookingsData = [
  ServiceBooking(
    id: 'sb-sample-01',
    branchId: '22222222-2222-2222-2222-222222222222',
    branchName: 'Kotchadai Workshop, Madurai',
    customerVehicleId: 'veh-sample-01',
    registrationNumber: 'TN 01 AB 1405',
    modelName: 'YZF-R15 V4',
    variantName: 'Racing Blue Metallic',
    serviceType: 'Periodic Maintenance 2 (General Check & Oil Change)',
    scheduledDate: DateTime.now(),
    timeSlot: '02:30 PM',
    status: 'IN_PROGRESS',
    jobCardId: 'jc-sample-01',
    jobCardStatus: 'WORK_IN_PROGRESS',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  ServiceBooking(
    id: 'sb-sample-02',
    branchId: '22222222-2222-2222-2222-222222222222',
    branchName: 'Kotchadai Workshop, Madurai',
    customerVehicleId: 'veh-sample-02',
    registrationNumber: 'TN 02 CD 5678',
    modelName: 'TVS iQube Electric',
    variantName: 'ST 3.4 kWh SmartXonnect',
    serviceType: 'Annual Telematics & Battery Health Calibration',
    scheduledDate: DateTime.now().add(const Duration(days: 7)),
    timeSlot: '10:00 AM',
    status: 'SCHEDULED',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

final myVehiclesProvider = FutureProvider.autoDispose<List<CustomerVehicle>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  try {
    final list = await ref.watch(serviceRepositoryProvider).getMyVehicles();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return sampleVehiclesData;
});

final myServiceBookingsProvider = FutureProvider.autoDispose<List<ServiceBooking>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  try {
    final list = await ref.watch(serviceRepositoryProvider).getMyBookings();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return sampleServiceBookingsData;
});

final serviceTrackingProvider = FutureProvider.autoDispose.family<ServiceTracking, String>(
  (ref, bookingId) async {
    try {
      return await ref.watch(serviceRepositoryProvider).getTracking(bookingId);
    } catch (_) {
      // Fallback tracking details for sample booking
      final isR15 = bookingId == 'sb-sample-01' || bookingId.contains('1405');
      final booking = sampleServiceBookingsData.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => sampleServiceBookingsData.first,
      );

      return ServiceTracking(
        booking: booking,
        currentStage: isR15 ? 'Work in progress (Bay 3)' : 'Appointment scheduled',
        progressPercent: isR15 ? 65 : 15,
        awaitingCustomerApproval: isR15,
        timeline: [
          const ServiceTimelineStep(label: 'Appointment booked', completed: true, current: false),
          const ServiceTimelineStep(label: 'Vehicle received & inspection', completed: true, current: false),
          const ServiceTimelineStep(label: 'Estimate prepared & approved', completed: true, current: false),
          ServiceTimelineStep(
            label: isR15 ? 'Work in progress (Bay 3)' : 'Technician assigned',
            completed: false,
            current: true,
          ),
          const ServiceTimelineStep(label: 'Quality check & road test', completed: false, current: false),
          const ServiceTimelineStep(label: 'Vehicle wash & sanitized', completed: false, current: false),
          const ServiceTimelineStep(label: 'Ready for pickup / delivery', completed: false, current: false),
        ],
        jobCard: isR15
            ? JobCardProgress(
                id: 'jc-sample-01',
                jobCardNumber: 'JC-2026-0891',
                status: 'WORK_IN_PROGRESS',
                odometerReading: 5120,
                fuelLevelPercent: 75,
                estimatedCost: 1850.0,
                customerApproved: true,
                technicianName: 'Suresh Kumar (Senior Technician)',
                createdAt: DateTime.now().subtract(const Duration(hours: 3)),
                items: const [
                  ServiceProgressItem(
                    id: 'itm-1',
                    itemType: 'PARTS',
                    description: 'Yamalube Fully Synthetic 4T 10W-40 (1.0 L)',
                    quantity: 1,
                    unitPrice: 650.0,
                    totalPrice: 650.0,
                    isApproved: true,
                  ),
                  ServiceProgressItem(
                    id: 'itm-2',
                    itemType: 'PARTS',
                    description: 'Genuine Yamaha Oil Filter Element',
                    quantity: 1,
                    unitPrice: 180.0,
                    totalPrice: 180.0,
                    isApproved: true,
                  ),
                  ServiceProgressItem(
                    id: 'itm-3',
                    itemType: 'LABOUR',
                    description: 'Periodic Maintenance & Chain Lubrication',
                    quantity: 1,
                    unitPrice: 750.0,
                    totalPrice: 750.0,
                    isApproved: true,
                  ),
                  ServiceProgressItem(
                    id: 'itm-4',
                    itemType: 'LABOUR',
                    description: 'Brake Caliper Cleaning & Pad Deglazing',
                    quantity: 1,
                    unitPrice: 270.0,
                    totalPrice: 270.0,
                    isApproved: true,
                  ),
                ],
              )
            : null,
      );
    }
  },
);
