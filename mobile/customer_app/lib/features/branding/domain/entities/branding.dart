import '../../../../core/utils/json_helpers.dart';

class Branding {
  const Branding({
    required this.tenantId,
    required this.dealerCode,
    required this.tradeName,
    required this.legalName,
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
    this.taxId,
    this.supportPhone,
    this.supportEmail,
    this.websiteUrl,
    this.manufacturerNames = const [],
  });

  final String? tenantId;
  final String dealerCode;
  final String tradeName;
  final String legalName;
  final String? logoUrl;
  final String? taxId;
  final String primaryColor;
  final String secondaryColor;
  final String? supportPhone;
  final String? supportEmail;
  final String? websiteUrl;
  final List<String> manufacturerNames;

  bool get hasTenant => tenantId != null && tenantId!.isNotEmpty;

  factory Branding.fromJson(Map<String, dynamic> json) {
    return Branding(
      tenantId: asNullableString(json['tenantId']),
      dealerCode: asString(json['dealerCode'], 'ALAGENDRA'),
      tradeName: asString(json['tradeName'], 'Alagendra Automobiles'),
      legalName: asString(json['legalName'], 'Alagendra Automobiles'),
      logoUrl: asNullableString(json['logoUrl']),
      taxId: asNullableString(json['taxId']),
      primaryColor: asString(json['primaryColor'], '#DC2626'),
      secondaryColor: asString(json['secondaryColor'], '#0F172A'),
      supportPhone: asNullableString(json['supportPhone']),
      supportEmail: asNullableString(json['supportEmail']),
      websiteUrl: asNullableString(json['websiteUrl']),
      manufacturerNames: asStringList(json['associatedManufacturerNames']),
    );
  }

  factory Branding.fallback(String dealerCode) {
    return Branding(
      tenantId: null,
      dealerCode: dealerCode,
      tradeName: 'Alagendra Automobiles',
      legalName: 'Alagendra Automobiles Pvt Ltd',
      primaryColor: '#DC2626',
      secondaryColor: '#0F172A',
      supportPhone: '+91 90000 00000',
      supportEmail: 'care@alagendra.example',
    );
  }
}
