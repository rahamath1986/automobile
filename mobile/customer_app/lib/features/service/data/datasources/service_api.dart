import '../../../../core/network/api_client.dart';
import '../../domain/entities/service_entities.dart';

class ServiceApi {
  ServiceApi(this._client);

  final ApiClient _client;

  Future<List<CustomerVehicle>> getMyVehicles() async {
    final payload = await _client.get('/service/my-vehicles');
    return _mapList(payload, CustomerVehicle.fromJson);
  }

  Future<List<ServiceBooking>> getMyBookings() async {
    final payload = await _client.get('/service/bookings/mine');
    return _mapList(payload, ServiceBooking.fromJson);
  }

  Future<ServiceBooking> createBooking(ServiceBookingDraft draft) async {
    final payload = await _client.post('/service/bookings', body: draft.toJson());
    if (payload is Map<String, dynamic>) {
      return ServiceBooking.fromJson(payload);
    }
    throw StateError('Service booking response was not returned.');
  }

  Future<ServiceTracking> getTracking(String bookingId) async {
    final payload = await _client.get('/service/bookings/$bookingId/tracking');
    if (payload is Map<String, dynamic>) {
      return ServiceTracking.fromJson(payload);
    }
    throw StateError('Service tracking response was not returned.');
  }

  Future<ServiceTracking> approveEstimate(String jobCardId) async {
    final payload = await _client.put('/service/job-cards/$jobCardId/approve');
    if (payload is Map<String, dynamic>) {
      return ServiceTracking.fromJson(payload);
    }
    throw StateError('Estimate approval response was not returned.');
  }

  List<T> _mapList<T>(dynamic payload, T Function(Map<String, dynamic>) mapper) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => mapper(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }
}
