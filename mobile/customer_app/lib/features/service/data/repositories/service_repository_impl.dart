import '../datasources/service_api.dart';
import '../../domain/entities/service_entities.dart';
import '../../domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl(this._api);

  final ServiceApi _api;

  @override
  Future<List<CustomerVehicle>> getMyVehicles() => _api.getMyVehicles();

  @override
  Future<List<ServiceBooking>> getMyBookings() => _api.getMyBookings();

  @override
  Future<ServiceBooking> createBooking(ServiceBookingDraft draft) => _api.createBooking(draft);

  @override
  Future<ServiceTracking> getTracking(String bookingId) => _api.getTracking(bookingId);

  @override
  Future<ServiceTracking> approveEstimate(String jobCardId) => _api.approveEstimate(jobCardId);
}
