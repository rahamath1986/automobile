import '../entities/lead.dart';

abstract class LeadsRepository {
  Future<Enquiry> createEnquiry(EnquiryDraft draft);
  Future<TestRide> createTestRide(TestRideDraft draft);
  Future<List<Enquiry>> getMyEnquiries();
  Future<List<TestRide>> getMyTestRides();
}
