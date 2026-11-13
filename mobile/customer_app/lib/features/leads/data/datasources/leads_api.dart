import '../../../../core/network/api_client.dart';
import '../../domain/entities/lead.dart';

class LeadsApi {
  LeadsApi(this._client);

  final ApiClient _client;

  Future<Enquiry> createEnquiry(EnquiryDraft draft) async {
    final payload = await _client.post('/sales/enquiries', body: draft.toJson());
    if (payload is Map<String, dynamic>) {
      return Enquiry.fromJson(payload);
    }
    throw StateError('Enquiry response was not returned.');
  }

  Future<TestRide> createTestRide(TestRideDraft draft) async {
    final payload = await _client.post('/sales/test-rides', body: draft.toJson());
    if (payload is Map<String, dynamic>) {
      return TestRide.fromJson(payload);
    }
    throw StateError('Test ride response was not returned.');
  }

  Future<List<Enquiry>> getMyEnquiries() async {
    final payload = await _client.get('/sales/enquiries/mine');
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Enquiry.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }

  Future<List<TestRide>> getMyTestRides() async {
    final payload = await _client.get('/sales/test-rides/mine');
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => TestRide.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }
}
