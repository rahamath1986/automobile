import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/providers.dart';
import '../data/datasources/leads_api.dart';
import '../data/repositories/leads_repository_impl.dart';
import '../domain/entities/lead.dart';
import '../domain/repositories/leads_repository.dart';

final leadsApiProvider = Provider<LeadsApi>((ref) => LeadsApi(ref.watch(apiClientProvider)));

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepositoryImpl(ref.watch(leadsApiProvider));
});

final List<Enquiry> sampleEnquiriesData = [
  Enquiry(
    id: 'enq-sample-01',
    branchId: '22222222-2222-2222-2222-222222222222',
    branchName: 'Kotchadai Branch, Madurai',
    variantId: '33333333-3333-3333-3333-333333333332',
    variantName: 'Monster Energy MotoGP Edition',
    modelName: 'Aerox 155',
    colorName: 'Monster Energy Black',
    status: 'QUOTATION_SHARED',
    source: 'MOBILEAPP',
    notes: 'Requested on-road pricing with genuine sports exhaust and knuckle guards. Ready for booking.',
    assignedSalesExecutiveName: 'Karthik S. (Senior Product Advisor)',
    expectedPurchaseDate: DateTime.now().add(const Duration(days: 12)),
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
  ),
  Enquiry(
    id: 'enq-sample-02',
    branchId: '22222222-2222-2222-2222-222222222222',
    branchName: 'Kotchadai Branch, Madurai',
    variantId: '33333333-3333-3333-3333-333333333333',
    variantName: 'ST 3.4 kWh SmartXonnect',
    modelName: 'TVS iQube Electric',
    colorName: 'Titanium Grey Matte',
    status: 'IN_DISCUSSION',
    source: 'MOBILEAPP',
    notes: 'Inquired regarding Tamil Nadu EV subsidy status and 15A home charger installation timeline.',
    assignedSalesExecutiveName: 'Priya Raman (EV Specialist)',
    expectedPurchaseDate: DateTime.now().add(const Duration(days: 20)),
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
];

final List<TestRide> sampleTestRidesData = [
  TestRide(
    id: 'tr-sample-01',
    branchId: '22222222-2222-2222-2222-222222222222',
    branchName: 'Kotchadai Branch, Madurai',
    variantId: '33333333-3333-3333-3333-333333333331',
    variantName: 'Racing Blue Metallic · Quickshifter',
    modelName: 'YZF-R15 V4',
    scheduledAt: DateTime.now().add(const Duration(hours: 4)),
    status: 'CONFIRMED',
    drivingLicenseNumber: 'TN-01-2022-••••1405',
    feedbackNotes: 'Pre-ride inspection completed by showroom team. Track mode brief requested.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TestRide(
    id: 'tr-sample-02',
    branchId: '22222222-2222-2222-2222-222222222222',
    branchName: 'Kotchadai Branch, Madurai',
    variantId: '33333333-3333-3333-3333-333333333332',
    variantName: 'Standard Metallic Black',
    modelName: 'Aerox 155',
    scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
    status: 'COMPLETED',
    drivingLicenseNumber: 'TN-01-2022-••••1405',
    feedbackNotes: 'Rated 5/5 ★ Exceptional acceleration and comfortable upright ergonomics.',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
];

final myEnquiriesProvider = FutureProvider.autoDispose<List<Enquiry>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  try {
    final list = await ref.watch(leadsRepositoryProvider).getMyEnquiries();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return sampleEnquiriesData;
});

final myTestRidesProvider = FutureProvider.autoDispose<List<TestRide>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  try {
    final list = await ref.watch(leadsRepositoryProvider).getMyTestRides();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return sampleTestRidesData;
});
