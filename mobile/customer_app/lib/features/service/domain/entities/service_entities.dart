import '../../../../core/utils/json_helpers.dart';

class CustomerVehicle {
  const CustomerVehicle({
    required this.id,
    required this.variantId,
    required this.modelName,
    required this.variantName,
    required this.registrationNumber,
    required this.chassisNumberMasked,
    this.engineNumberMasked,
    this.deliveryDate,
    this.heroImageUrl,
    this.lastServiceDate,
    this.lastServiceStatus,
  });

  final String id;
  final String variantId;
  final String modelName;
  final String variantName;
  final String registrationNumber;
  final String chassisNumberMasked;
  final String? engineNumberMasked;
  final DateTime? deliveryDate;
  final String? heroImageUrl;
  final DateTime? lastServiceDate;
  final String? lastServiceStatus;

  factory CustomerVehicle.fromJson(Map<String, dynamic> json) {
    return CustomerVehicle(
      id: asString(json['id']),
      variantId: asString(json['variantId']),
      modelName: asString(json['modelName']),
      variantName: asString(json['variantName']),
      registrationNumber: asString(json['registrationNumber']),
      chassisNumberMasked: asString(json['chassisNumberMasked']),
      engineNumberMasked: asNullableString(json['engineNumberMasked']),
      deliveryDate: asDateTime(json['deliveryDate']),
      heroImageUrl: asNullableString(json['heroImageUrl']),
      lastServiceDate: asDateTime(json['lastServiceDate']),
      lastServiceStatus: asNullableString(json['lastServiceStatus']),
    );
  }
}

class ServiceBooking {
  const ServiceBooking({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.customerVehicleId,
    required this.registrationNumber,
    required this.modelName,
    required this.variantName,
    required this.serviceType,
    required this.scheduledDate,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
    this.jobCardId,
    this.jobCardStatus,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String customerVehicleId;
  final String registrationNumber;
  final String modelName;
  final String variantName;
  final String serviceType;
  final DateTime scheduledDate;
  final String timeSlot;
  final String status;
  final String? jobCardId;
  final String? jobCardStatus;
  final DateTime createdAt;

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      id: asString(json['id']),
      branchId: asString(json['branchId']),
      branchName: asString(json['branchName']),
      customerVehicleId: asString(json['customerVehicleId']),
      registrationNumber: asString(json['registrationNumber']),
      modelName: asString(json['modelName']),
      variantName: asString(json['variantName']),
      serviceType: asString(json['serviceType']),
      scheduledDate: asDateTime(json['scheduledDate']) ?? DateTime.now(),
      timeSlot: asString(json['timeSlot']),
      status: asString(json['status'], 'BOOKED'),
      jobCardId: asNullableString(json['jobCardId']),
      jobCardStatus: asNullableString(json['jobCardStatus']),
      createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class ServiceProgressItem {
  const ServiceProgressItem({
    required this.id,
    required this.itemType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.isApproved,
  });

  final String id;
  final String itemType;
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isApproved;

  factory ServiceProgressItem.fromJson(Map<String, dynamic> json) {
    return ServiceProgressItem(
      id: asString(json['id']),
      itemType: asString(json['itemType'], 'LABOUR'),
      description: asString(json['description']),
      quantity: asDouble(json['quantity'], 1),
      unitPrice: asDouble(json['unitPrice']),
      totalPrice: asDouble(json['totalPrice']),
      isApproved: asBool(json['isApproved'], true),
    );
  }
}

class JobCardProgress {
  const JobCardProgress({
    required this.id,
    required this.jobCardNumber,
    required this.status,
    required this.odometerReading,
    required this.fuelLevelPercent,
    required this.estimatedCost,
    required this.customerApproved,
    required this.createdAt,
    required this.items,
    this.technicianName,
    this.updatedAt,
  });

  final String id;
  final String jobCardNumber;
  final String status;
  final int odometerReading;
  final int fuelLevelPercent;
  final double estimatedCost;
  final bool customerApproved;
  final String? technicianName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ServiceProgressItem> items;

  factory JobCardProgress.fromJson(Map<String, dynamic> json) {
    return JobCardProgress(
      id: asString(json['id']),
      jobCardNumber: asString(json['jobCardNumber']),
      status: asString(json['status'], 'OPEN'),
      odometerReading: asInt(json['odometerReading']),
      fuelLevelPercent: asInt(json['fuelLevelPercent']),
      estimatedCost: asDouble(json['estimatedCost']),
      customerApproved: asBool(json['customerApproved']),
      technicianName: asNullableString(json['technicianName']),
      createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: asDateTime(json['updatedAt']),
      items: asMapList(json['items']).map(ServiceProgressItem.fromJson).toList(),
    );
  }
}

class ServiceTimelineStep {
  const ServiceTimelineStep({required this.label, required this.completed, required this.current});

  final String label;
  final bool completed;
  final bool current;

  factory ServiceTimelineStep.fromJson(Map<String, dynamic> json) => ServiceTimelineStep(
        label: asString(json['label']),
        completed: asBool(json['completed']),
        current: asBool(json['current']),
      );
}

class ServiceTracking {
  const ServiceTracking({
    required this.booking,
    required this.currentStage,
    required this.progressPercent,
    required this.awaitingCustomerApproval,
    required this.timeline,
    this.jobCard,
  });

  final ServiceBooking booking;
  final JobCardProgress? jobCard;
  final String currentStage;
  final int progressPercent;
  final bool awaitingCustomerApproval;
  final List<ServiceTimelineStep> timeline;

  factory ServiceTracking.fromJson(Map<String, dynamic> json) {
    return ServiceTracking(
      booking: ServiceBooking.fromJson(
        json['booking'] is Map ? Map<String, dynamic>.from(json['booking'] as Map) : const {},
      ),
      jobCard: json['jobCard'] is Map
          ? JobCardProgress.fromJson(Map<String, dynamic>.from(json['jobCard'] as Map))
          : null,
      currentStage: asString(json['currentStage']),
      progressPercent: asInt(json['progressPercent']),
      awaitingCustomerApproval: asBool(json['awaitingCustomerApproval']),
      timeline: asMapList(json['timeline']).map(ServiceTimelineStep.fromJson).toList(),
    );
  }
}

class ServiceBookingDraft {
  const ServiceBookingDraft({
    required this.customerVehicleId,
    required this.branchId,
    required this.serviceType,
    required this.scheduledDate,
    required this.timeSlot,
    this.customerComplaints,
  });

  final String customerVehicleId;
  final String branchId;
  final String serviceType;
  final DateTime scheduledDate;
  final String timeSlot;
  final String? customerComplaints;

  Map<String, dynamic> toJson() => {
        'customerVehicleId': customerVehicleId,
        'branchId': branchId,
        'serviceType': serviceType,
        'scheduledDate': scheduledDate.toUtc().toIso8601String(),
        'timeSlot': timeSlot,
        'customerComplaints': customerComplaints,
      };
}
