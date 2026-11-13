// models/vehicle_model_summary.dart
class VehicleModelSummary {
  final String id;
  final String manufacturerCode;
  final String manufacturerName;
  final String code;
  final String name;
  final String category;
  final String fuelType;
  final int displacementCc;
  final double startingPrice;
  final int variantCount;
  final int colorCount;
  final bool has3DAsset;

  VehicleModelSummary({
    required this.id,
    required this.manufacturerCode,
    required this.manufacturerName,
    required this.code,
    required this.name,
    required this.category,
    required this.fuelType,
    required this.displacementCc,
    required this.startingPrice,
    required this.variantCount,
    required this.colorCount,
    required this.has3DAsset,
  });

  factory VehicleModelSummary.fromJson(Map<String, dynamic> json) => VehicleModelSummary(
        id: json['id'] as String,
        manufacturerCode: json['manufacturerCode'] as String,
        manufacturerName: json['manufacturerName'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        fuelType: json['fuelType'] as String,
        displacementCc: json['displacementCc'] as int,
        startingPrice: (json['startingPrice'] as num).toDouble(),
        variantCount: json['variantCount'] as int,
        colorCount: json['colorCount'] as int,
        has3DAsset: json['has3DAsset'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'manufacturerCode': manufacturerCode,
        'manufacturerName': manufacturerName,
        'code': code,
        'name': name,
        'category': category,
        'fuelType': fuelType,
        'displacementCc': displacementCc,
        'startingPrice': startingPrice,
        'variantCount': variantCount,
        'colorCount': colorCount,
        'has3DAsset': has3DAsset,
      };
}

