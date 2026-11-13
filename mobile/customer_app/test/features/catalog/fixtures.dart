import 'package:motosaas_customer/features/catalog/domain/entities/vehicle.dart';

VehicleModelSummary modelFixture(
  String id, {
  String name = 'R15 V4',
  String category = 'MOTORCYCLE',
  String fuelType = 'PETROL',
}) {
  return VehicleModelSummary(
    id: id,
    manufacturerId: 'manufacturer-1',
    manufacturerName: 'Yamaha',
    manufacturerCode: 'YAM',
    code: id.toUpperCase(),
    name: name,
    category: category,
    fuelType: fuelType,
    startingPrice: 180000,
    variantCount: 1,
    colorCount: 2,
    has3DAsset: true,
  );
}

VehicleVariant variantFixture(String id) {
  return VehicleVariant(
    id: id,
    modelId: 'model-1',
    code: id.toUpperCase(),
    name: 'Variant $id',
    basePrice: 185000,
    specificationsJson: '{"displacementCc": 155, "powerPs": 18.4}',
    featuresJson: '{"features": ["Traction control", "Quick shifter"]}',
    colors: const [
      VehicleColor(
        id: 'colour-1',
        variantId: 'variant-1',
        colorName: 'Racing Blue',
        hexCode: '#0031AD',
        isPrimary: true,
      ),
    ],
    assets3D: const [],
  );
}
