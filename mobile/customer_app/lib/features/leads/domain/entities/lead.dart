import '../../../../core/utils/json_helpers.dart';

class Enquiry {
  const Enquiry({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.variantId,
    required this.variantName,
    required this.modelName,
    required this.status,
    required this.source,
    required this.createdAt,
    this.colorId,
    this.colorName,
    this.notes,
    this.expectedPurchaseDate,
    this.assignedSalesExecutiveName,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String variantId;
  final String variantName;
  final String modelName;
  final String? colorId;
  final String? colorName;
  final String status;
  final String source;
  final String? notes;
  final DateTime? expectedPurchaseDate;
  final String? assignedSalesExecutiveName;
  final DateTime createdAt;

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      id: asString(json['id']),
      branchId: asString(json['branchId']),
      branchName: asString(json['branchName']),
      variantId: asString(json['variantId']),
      variantName: asString(json['variantName']),
      modelName: asString(json['modelName']),
      colorId: asNullableString(json['colorId']),
      colorName: asNullableString(json['colorName']),
      status: asString(json['status'], 'NEW'),
      source: asString(json['source'], 'MOBILEAPP'),
      notes: asNullableString(json['notes']),
      expectedPurchaseDate: asDateTime(json['expectedPurchaseDate']),
      assignedSalesExecutiveName: asNullableString(json['assignedSalesExecutiveName']),
      createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class TestRide {
  const TestRide({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.variantId,
    required this.variantName,
    required this.modelName,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    this.enquiryId,
    this.drivingLicenseNumber,
    this.feedbackNotes,
  });

  final String id;
  final String? enquiryId;
  final String branchId;
  final String branchName;
  final String variantId;
  final String variantName;
  final String modelName;
  final DateTime scheduledAt;
  final String status;
  final String? drivingLicenseNumber;
  final String? feedbackNotes;
  final DateTime createdAt;

  factory TestRide.fromJson(Map<String, dynamic> json) {
    return TestRide(
      id: asString(json['id']),
      enquiryId: asNullableString(json['enquiryId']),
      branchId: asString(json['branchId']),
      branchName: asString(json['branchName']),
      variantId: asString(json['variantId']),
      variantName: asString(json['variantName']),
      modelName: asString(json['modelName']),
      scheduledAt: asDateTime(json['scheduledAt']) ?? DateTime.now(),
      status: asString(json['status'], 'SCHEDULED'),
      drivingLicenseNumber: asNullableString(json['drivingLicenseNumber']),
      feedbackNotes: asNullableString(json['feedbackNotes']),
      createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class EnquiryDraft {
  const EnquiryDraft({
    required this.branchId,
    required this.variantId,
    this.colorId,
    this.notes,
    this.expectedPurchaseDate,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
  });

  final String branchId;
  final String variantId;
  final String? colorId;
  final String? notes;
  final DateTime? expectedPurchaseDate;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;

  Map<String, dynamic> toJson() => {
        'branchId': branchId,
        'variantId': variantId,
        'colorId': colorId,
        'notes': notes,
        'expectedPurchaseDate': expectedPurchaseDate?.toUtc().toIso8601String(),
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
      };
}

class TestRideDraft {
  const TestRideDraft({
    required this.branchId,
    required this.variantId,
    required this.scheduledAt,
    this.enquiryId,
    this.drivingLicenseNumber,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
  });

  final String branchId;
  final String variantId;
  final String? enquiryId;
  final DateTime scheduledAt;
  final String? drivingLicenseNumber;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;

  Map<String, dynamic> toJson() => {
        'branchId': branchId,
        'variantId': variantId,
        'enquiryId': enquiryId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'drivingLicenseNumber': drivingLicenseNumber,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
      };
}
