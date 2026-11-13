import '../../../../core/utils/json_helpers.dart';

class VehicleModelSummary {
  const VehicleModelSummary({
    required this.id,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.manufacturerCode,
    required this.code,
    required this.name,
    required this.category,
    required this.fuelType,
    required this.startingPrice,
    required this.variantCount,
    required this.colorCount,
    required this.has3DAsset,
    this.displacementCc,
    this.batteryCapacityKwh,
    this.heroImageUrl,
  });

  final String id;
  final String manufacturerId;
  final String manufacturerName;
  final String manufacturerCode;
  final String code;
  final String name;
  final String category;
  final String fuelType;
  final int? displacementCc;
  final double? batteryCapacityKwh;
  final double startingPrice;
  final int variantCount;
  final int colorCount;
  final String? heroImageUrl;
  final bool has3DAsset;

  bool get isElectric => fuelType.toUpperCase() == 'ELECTRIC';

  String get categoryLabel {
    final normalized = category.toUpperCase();
    return switch (normalized) {
      'MOTORCYCLE' || 'MOTORCYCLES' => 'Motorcycle',
      'SCOOTER' || 'SCOOTERS' => 'Scooter',
      'ELECTRICVEHICLE' || 'ELECTRIC' || 'EV' => 'Electric',
      _ => 'Two-wheeler',
    };
  }

  factory VehicleModelSummary.fromJson(Map<String, dynamic> json) {
    return VehicleModelSummary(
      id: asString(json['id']),
      manufacturerId: asString(json['manufacturerId']),
      manufacturerName: asString(json['manufacturerName']),
      manufacturerCode: asString(json['manufacturerCode']),
      code: asString(json['code']),
      name: asString(json['name']),
      category: asString(json['category'], 'MOTORCYCLE'),
      fuelType: asString(json['fuelType'], 'PETROL'),
      displacementCc: asNullableInt(json['displacementCc']),
      batteryCapacityKwh: asNullableDouble(json['batteryCapacityKwh']),
      startingPrice: asDouble(json['startingPrice']),
      variantCount: asInt(json['variantCount']),
      colorCount: asInt(json['colorCount']),
      heroImageUrl: asNullableString(json['heroImageUrl']),
      has3DAsset: asBool(json['has3DAsset']),
    );
  }
}

class VehicleModelDetail extends VehicleModelSummary {
  const VehicleModelDetail({
    required super.id,
    required super.manufacturerId,
    required super.manufacturerName,
    required super.manufacturerCode,
    required super.code,
    required super.name,
    required super.category,
    required super.fuelType,
    required super.startingPrice,
    required super.variantCount,
    required super.colorCount,
    required super.has3DAsset,
    required this.variants,
    super.displacementCc,
    super.batteryCapacityKwh,
    super.heroImageUrl,
  });

  final List<VehicleVariant> variants;

  factory VehicleModelDetail.fromJson(Map<String, dynamic> json) {
    final summary = VehicleModelSummary.fromJson(json);
    return VehicleModelDetail(
      id: summary.id,
      manufacturerId: summary.manufacturerId,
      manufacturerName: summary.manufacturerName,
      manufacturerCode: summary.manufacturerCode,
      code: summary.code,
      name: summary.name,
      category: summary.category,
      fuelType: summary.fuelType,
      displacementCc: summary.displacementCc,
      batteryCapacityKwh: summary.batteryCapacityKwh,
      startingPrice: summary.startingPrice,
      variantCount: summary.variantCount,
      colorCount: summary.colorCount,
      heroImageUrl: summary.heroImageUrl,
      has3DAsset: summary.has3DAsset,
      variants: asMapList(json['variants']).map(VehicleVariant.fromJson).toList(),
    );
  }

  VehicleVariant? get primaryVariant => variants.isEmpty ? null : variants.first;
}

class VehicleVariant {
  const VehicleVariant({
    required this.id,
    required this.modelId,
    required this.code,
    required this.name,
    required this.basePrice,
    required this.colors,
    required this.assets3D,
    this.specificationsJson,
    this.featuresJson,
  });

  final String id;
  final String modelId;
  final String code;
  final String name;
  final double basePrice;
  final String? specificationsJson;
  final String? featuresJson;
  final List<VehicleColor> colors;
  final List<Asset3D> assets3D;

  Map<String, dynamic> get specifications => parseJsonObject(specificationsJson);
  Map<String, dynamic> get features => parseJsonObject(featuresJson);

  VehicleColor? get primaryColor {
    if (colors.isEmpty) return null;
    return colors.firstWhere((color) => color.isPrimary, orElse: () => colors.first);
  }

  bool get has3DAsset => assets3D.isNotEmpty;

  factory VehicleVariant.fromJson(Map<String, dynamic> json) {
    return VehicleVariant(
      id: asString(json['id']),
      modelId: asString(json['modelId']),
      code: asString(json['code']),
      name: asString(json['name']),
      basePrice: asDouble(json['basePrice']),
      specificationsJson: asNullableString(json['specificationsJson']),
      featuresJson: asNullableString(json['featuresJson']),
      colors: asMapList(json['colors']).map(VehicleColor.fromJson).toList(),
      assets3D: asMapList(json['assets3D']).map(Asset3D.fromJson).toList(),
    );
  }
}

class VehicleColor {
  const VehicleColor({
    required this.id,
    required this.variantId,
    required this.colorName,
    required this.hexCode,
    required this.isPrimary,
    this.imageUrl,
  });

  final String id;
  final String variantId;
  final String colorName;
  final String hexCode;
  final bool isPrimary;
  final String? imageUrl;

  factory VehicleColor.fromJson(Map<String, dynamic> json) {
    return VehicleColor(
      id: asString(json['id']),
      variantId: asString(json['variantId']),
      colorName: asString(json['colorName']),
      hexCode: asString(json['hexCode'], '#000000'),
      isPrimary: asBool(json['isPrimary']),
      imageUrl: asNullableString(json['imageUrl']),
    );
  }
}

class Asset3D {
  const Asset3D({
    required this.id,
    required this.variantId,
    required this.glbFileUrl,
    required this.modelFileSizeBytes,
    this.colorId,
    this.usdzFileUrl,
    this.hotspotsJson,
    this.cameraPresetsJson,
  });

  final String id;
  final String variantId;
  final String? colorId;
  final String glbFileUrl;
  final String? usdzFileUrl;
  final int modelFileSizeBytes;
  final String? hotspotsJson;
  final String? cameraPresetsJson;

  factory Asset3D.fromJson(Map<String, dynamic> json) {
    return Asset3D(
      id: asString(json['id']),
      variantId: asString(json['variantId']),
      colorId: asNullableString(json['colorId']),
      glbFileUrl: asString(json['glbFileUrl']),
      usdzFileUrl: asNullableString(json['usdzFileUrl']),
      modelFileSizeBytes: asInt(json['modelFileSizeBytes']),
      hotspotsJson: asNullableString(json['hotspotsJson']),
      cameraPresetsJson: asNullableString(json['cameraPresetsJson']),
    );
  }
}

class DealershipBranch {
  const DealershipBranch({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.name,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phone,
    required this.isHeadquarters,
    required this.isActive,
    this.email,
  });

  final String id;
  final String tenantId;
  final String code;
  final String name;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String phone;
  final String? email;
  final bool isHeadquarters;
  final bool isActive;

  String get shortLocation => city.isEmpty ? name : '$name · $city';

  String get fullAddress {
    final parts = [addressLine1, city, state, postalCode].where((part) => part.trim().isNotEmpty);
    return parts.join(', ');
  }

  factory DealershipBranch.fromJson(Map<String, dynamic> json) {
    return DealershipBranch(
      id: asString(json['id']),
      tenantId: asString(json['tenantId']),
      code: asString(json['code']),
      name: asString(json['name']),
      addressLine1: asString(json['addressLine1']),
      city: asString(json['city']),
      state: asString(json['state']),
      postalCode: asString(json['postalCode']),
      phone: asString(json['phone']),
      email: asNullableString(json['email']),
      isHeadquarters: asBool(json['isHeadquarters']),
      isActive: asBool(json['isActive'], true),
    );
  }
}

class VariantBranchPricing {
  const VariantBranchPricing({
    required this.variantId,
    required this.variantName,
    required this.modelName,
    required this.branchName,
    required this.exShowroomPrice,
    required this.rtoCharges,
    required this.insuranceCharges,
    required this.handlingCharges,
    required this.estimatedOnRoadPrice,
    required this.availableUnits,
    required this.inStock,
    required this.disclaimer,
    this.branchId,
    this.branchCode = 'ALL',
    this.state = '',
    this.accessoriesCharges = 0,
    this.rtoPercent = 0,
    this.insurancePercent = 0,
  });

  final String variantId;
  final String variantName;
  final String modelName;
  final String? branchId;
  final String branchCode;
  final String branchName;
  final String state;
  final double exShowroomPrice;
  final double rtoPercent;
  final double rtoCharges;
  final double insurancePercent;
  final double insuranceCharges;
  final double accessoriesCharges;
  final double handlingCharges;
  final double estimatedOnRoadPrice;
  final int availableUnits;
  final bool inStock;
  final String disclaimer;

  factory VariantBranchPricing.fromJson(Map<String, dynamic> json) {
    return VariantBranchPricing(
      variantId: asString(json['variantId']),
      variantName: asString(json['variantName']),
      modelName: asString(json['modelName']),
      branchId: asNullableString(json['branchId']),
      branchCode: asString(json['branchCode'], 'ALL'),
      branchName: asString(json['branchName'], 'All Branches'),
      state: asString(json['state']),
      exShowroomPrice: asDouble(json['exShowroomPrice']),
      rtoPercent: asDouble(json['rtoPercent']),
      rtoCharges: asDouble(json['rtoCharges']),
      insurancePercent: asDouble(json['insurancePercent']),
      insuranceCharges: asDouble(json['insuranceCharges']),
      accessoriesCharges: asDouble(json['accessoriesCharges']),
      handlingCharges: asDouble(json['handlingCharges']),
      estimatedOnRoadPrice: asDouble(json['estimatedOnRoadPrice']),
      availableUnits: asInt(json['availableUnits']),
      inStock: asBool(json['inStock']),
      disclaimer: asString(json['disclaimer']),
    );
  }
}
