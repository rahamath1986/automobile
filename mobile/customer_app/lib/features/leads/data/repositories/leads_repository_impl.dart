import '../datasources/leads_api.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/leads_repository.dart';

class LeadsRepositoryImpl implements LeadsRepository {
  LeadsRepositoryImpl(this._api);

  final LeadsApi _api;

  @override
  Future<Enquiry> createEnquiry(EnquiryDraft draft) => _api.createEnquiry(draft);

  @override
  Future<TestRide> createTestRide(TestRideDraft draft) => _api.createTestRide(draft);

  @override
  Future<List<Enquiry>> getMyEnquiries() => _api.getMyEnquiries();

  @override
  Future<List<TestRide>> getMyTestRides() => _api.getMyTestRides();
}
