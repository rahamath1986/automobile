import '../../../../core/utils/json_helpers.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.memberSince,
    required this.vehicleCount,
    required this.enquiryCount,
    required this.activeServiceBookingCount,
    this.email,
    this.addressLine1,
    this.city,
    this.state,
    this.postalCode,
    this.tenantId,
    this.tenantName,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String fullName;
  final String phone;
  final String? email;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? postalCode;
  final DateTime? memberSince;
  final String? tenantId;
  final String? tenantName;
  final int vehicleCount;
  final int enquiryCount;
  final int activeServiceBookingCount;

  String get displayName => fullName.trim().isEmpty ? 'Rider' : fullName.trim();

  String get initials {
    final parts = displayName.split(' ').where((part) => part.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String? get formattedAddress {
    final parts = [addressLine1, city, state, postalCode]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  bool get hasAddress => formattedAddress != null;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: asString(json['id']),
      firstName: asString(json['firstName']),
      lastName: asNullableString(json['lastName']),
      fullName: asString(json['fullName'], 'Rider'),
      phone: asString(json['phone']),
      email: asNullableString(json['email']),
      addressLine1: asNullableString(json['addressLine1']),
      city: asNullableString(json['city']),
      state: asNullableString(json['state']),
      postalCode: asNullableString(json['postalCode']),
      memberSince: asDateTime(json['memberSince']),
      tenantId: asNullableString(json['tenantId']),
      tenantName: asNullableString(json['tenantName']),
      vehicleCount: asInt(json['vehicleCount']),
      enquiryCount: asInt(json['enquiryCount']),
      activeServiceBookingCount: asInt(json['activeServiceBookingCount']),
    );
  }
}

class ProfileUpdateDraft {
  const ProfileUpdateDraft({
    this.firstName,
    this.lastName,
    this.email,
    this.addressLine1,
    this.city,
    this.state,
    this.postalCode,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? postalCode;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'addressLine1': addressLine1,
        'city': city,
        'state': state,
        'postalCode': postalCode,
      };
}
