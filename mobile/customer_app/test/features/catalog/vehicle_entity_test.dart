import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/catalog/domain/entities/vehicle.dart';

void main() {
  group('catalog entities', () {
    test('VehicleModelSummary parses list payload fields', () {
      final model = VehicleModelSummary.fromJson({
        'id': 'model-1',
        'manufacturerId': 'manu-1',
        'manufacturerName': 'Yamaha',
        'manufacturerCode': 'YAM',
        'code': 'R15V4',
        'name': 'R15 V4',
        'category': 'MOTORCYCLE',
        'fuelType': 'PETROL',
        'displacementCc': 155,
        'startingPrice': 182000,
        'variantCount': 2,
        'colorCount': 4,
        'heroImageUrl': 'https://cdn.example.com/r15.jpg',
        'has3DAsset': true,
      });

      expect(model.name, 'R15 V4');
      expect(model.categoryLabel, 'Motorcycle');
      expect(model.isElectric, isFalse);
      expect(model.has3DAsset, isTrue);
      expect(model.startingPrice, 182000);
    });

    test('VehicleModelDetail parses variants, colours and 3D assets', () {
      final detail = VehicleModelDetail.fromJson({
        'id': 'model-1',
        'manufacturerId': 'manu-1',
        'manufacturerName': 'Ather',
        'manufacturerCode': 'ATH',
        'code': 'IQUBE',
        'name': 'iQube',
        'category': 'ELECTRICVEHICLE',
        'fuelType': 'ELECTRIC',
        'startingPrice': 125000,
        'variantCount': 1,
        'colorCount': 1,
        'has3DAsset': true,
        'batteryCapacityKwh': 3.4,
        'variants': [
          {
            'id': 'variant-1',
            'modelId': 'model-1',
            'code': 'IQUBE-ST',
            'name': 'iQube ST',
            'basePrice': 139000,
            'specificationsJson': '{"rangeKm": 145, "topSpeedKph": 78}',
            'featuresJson': '{"features": ["Fast charging", "Touchscreen"]}',
            'colors': [
              {
                'id': 'colour-1',
                'variantId': 'variant-1',
                'colorName': 'Space Grey',
                'hexCode': '#3A3A3A',
                'isPrimary': true,
              },
            ],
            'assets3D': [
              {
                'id': 'asset-1',
                'variantId': 'variant-1',
                'glbFileUrl': 'https://cdn.example.com/iqube.glb',
                'modelFileSizeBytes': 4200000,
                'hotspotsJson': '{}',
              },
            ],
          },
        ],
      });

      expect(detail.variants, hasLength(1));
      expect(detail.primaryVariant?.name, 'iQube ST');
      expect(detail.primaryVariant?.primaryColor?.colorName, 'Space Grey');
      expect(detail.primaryVariant?.specifications['rangeKm'], 145);
      expect(detail.primaryVariant?.has3DAsset, isTrue);
      expect(detail.isElectric, isTrue);
    });

    test('VariantBranchPricing parses on-road estimate', () {
      final pricing = VariantBranchPricing.fromJson({
        'variantId': 'variant-1',
        'variantName': 'R15 V4',
        'modelName': 'R15',
        'branchId': 'branch-1',
        'branchCode': 'BLR-01',
        'branchName': 'Indiranagar',
        'state': 'Karnataka',
        'exShowroomPrice': 182000,
        'rtoPercent': 10,
        'rtoCharges': 18200,
        'insurancePercent': 3.5,
        'insuranceCharges': 6370,
        'handlingCharges': 2500,
        'estimatedOnRoadPrice': 209070,
        'availableUnits': 3,
        'inStock': true,
        'disclaimer': 'Indicative estimate only.',
      });

      expect(pricing.estimatedOnRoadPrice, 209070);
      expect(pricing.inStock, isTrue);
      expect(pricing.branchName, 'Indiranagar');
      expect(pricing.rtoPercent, 10);
    });
  });
}
