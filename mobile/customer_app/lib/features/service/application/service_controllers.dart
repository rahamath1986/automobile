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

final myVehiclesProvider = FutureProvider.autoDispose<List<CustomerVehicle>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  return ref.watch(serviceRepositoryProvider).getMyVehicles();
});

final myServiceBookingsProvider = FutureProvider.autoDispose<List<ServiceBooking>>((ref) async {
  final session = ref.watch(authControllerProvider).value;
  if (session == null) return const [];
  return ref.watch(serviceRepositoryProvider).getMyBookings();
});

final serviceTrackingProvider = FutureProvider.autoDispose.family<ServiceTracking, String>(
  (ref, bookingId) => ref.watch(serviceRepositoryProvider).getTracking(bookingId),
);
