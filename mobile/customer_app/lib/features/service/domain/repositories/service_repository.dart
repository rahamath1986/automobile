import '../entities/service_entities.dart';

abstract class ServiceRepository {
  Future<List<CustomerVehicle>> getMyVehicles();
  Future<List<ServiceBooking>> getMyBookings();
  Future<ServiceBooking> createBooking(ServiceBookingDraft draft);
  Future<ServiceTracking> getTracking(String bookingId);
  Future<ServiceTracking> approveEstimate(String jobCardId);
}
