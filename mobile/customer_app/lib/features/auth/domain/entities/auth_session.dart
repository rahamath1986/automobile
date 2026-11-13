import '../../../../core/utils/json_helpers.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.userType,
    this.email,
    this.tenantId,
    this.tenantCode,
    this.tenantName,
    this.roles = const [],
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final String userType;
  final String? tenantId;
  final String? tenantCode;
  final String? tenantName;
  final List<String> roles;

  bool get isCustomer => userType.toUpperCase() == 'CUSTOMER';
  String get firstName => fullName.trim().isEmpty ? 'Rider' : fullName.trim().split(' ').first;

  factory AuthSession.fromApiResponse(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};

    return AuthSession(
      accessToken: asString(json['accessToken']),
      refreshToken: asString(json['refreshToken']),
      userId: asString(user['id']),
      fullName: asString(user['fullName'], 'Rider'),
      phone: asString(user['phone']),
      email: asNullableString(user['email']),
      userType: asString(user['userType'], 'CUSTOMER'),
      tenantId: asNullableString(user['tenantId']),
      tenantCode: asNullableString(user['tenantCode']),
      tenantName: asNullableString(user['tenantName']),
      roles: asStringList(user['roles']),
    );
  }

  factory AuthSession.fromStorage(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: asString(json['accessToken']),
      refreshToken: asString(json['refreshToken']),
      userId: asString(json['userId']),
      fullName: asString(json['fullName'], 'Rider'),
      phone: asString(json['phone']),
      email: asNullableString(json['email']),
      userType: asString(json['userType'], 'CUSTOMER'),
      tenantId: asNullableString(json['tenantId']),
      tenantCode: asNullableString(json['tenantCode']),
      tenantName: asNullableString(json['tenantName']),
      roles: asStringList(json['roles']),
    );
  }

  Map<String, dynamic> toStorage() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'userType': userType,
        'tenantId': tenantId,
        'tenantCode': tenantCode,
        'tenantName': tenantName,
        'roles': roles,
      };
}
