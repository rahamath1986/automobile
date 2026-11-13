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

final myEnquiriesProvider = FutureProvider.autoDispose<List<Enquiry>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  return ref.watch(leadsRepositoryProvider).getMyEnquiries();
});

final myTestRidesProvider = FutureProvider.autoDispose<List<TestRide>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  return ref.watch(leadsRepositoryProvider).getMyTestRides();
});
