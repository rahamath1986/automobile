import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/showroom/domain/entities/showroom_asset.dart';

void main() {
  group('ViewerTier', () {
    test('maps backend numeric enum values', () {
      expect(ViewerTier.fromJson(0), ViewerTier.interactive3D);
      expect(ViewerTier.fromJson(1), ViewerTier.turntable360);
      expect(ViewerTier.fromJson(2), ViewerTier.staticGallery);
    });

    test('maps string values and defaults to interactive 3D', () {
      expect(ViewerTier.fromJson('Turntable360'), ViewerTier.turntable360);
      expect(ViewerTier.fromJson('static_gallery'), ViewerTier.staticGallery);
      expect(ViewerTier.fromJson('TIER_1'), ViewerTier.interactive3D);
      expect(ViewerTier.fromJson(null), ViewerTier.interactive3D);
    });
  });

  group('ShowroomAsset', () {
    test('parses tier, camera presets, hotspots and colours', () {
      final asset = ShowroomAsset.fromJson({
        'variantId': 'variant-1',
        'variantCode': 'R15-V4',
        'variantName': 'R15 V4',
        'modelName': 'R15',
        'basePrice': 182000,
        'colorId': 'colour-1',
        'colorName': 'Racing Blue',
        'hexCode': '#0031AD',
        'activeTier': 0,
        'glbFileUrl': 'https://cdn.example.com/r15.glb',
        'modelFileSizeBytes': 6400000,
        'hasDracoCompression': true,
        'turntable360FrameUrls': ['https://cdn.example.com/f1.jpg'],
        'staticGalleryImageUrls': ['https://cdn.example.com/g1.jpg'],
        'cameraPresets': {
          'heroView': {
            'position': {'x': 2.4, 'y': 1.2, 'z': 2.4},
            'target': {'x': 0, 'y': 0.6, 'z': 0},
            'fov': 45,
            'minPolarAngleDeg': 5,
            'maxPolarAngleDeg': 75,
            'minDistanceMeters': 1.5,
            'maxDistanceMeters': 6,
          },
        },
        'hotspots': [
          {
            'id': 'engine',
            'title': '155cc VVA engine',
            'description': 'Variable valve actuation for strong mid-range.',
            'category': 'Engine',
            'specMetric': '18.4 PS',
            'position': {'x': 0, 'y': 0.7, 'z': 0},
          },
        ],
        'availableColors': [
          {
            'id': 'colour-1',
            'variantId': 'variant-1',
            'colorName': 'Racing Blue',
            'hexCode': '#0031AD',
            'isPrimary': true,
          },
          {
            'id': 'colour-2',
            'variantId': 'variant-1',
            'colorName': 'Metallic Red',
            'hexCode': '#B00020',
            'isPrimary': false,
          },
        ],
      });

      expect(asset.activeTier, ViewerTier.interactive3D);
      expect(asset.hasTurntable, isTrue);
      expect(asset.hasGallery, isTrue);
      expect(asset.cameraPresets.hero.fov, 45);
      expect(asset.cameraPresets.hero.position.x, 2.4);
      expect(asset.hotspots.first.specMetric, '18.4 PS');
      expect(asset.availableColors, hasLength(2));
    });

    test('falls back to safe camera presets when manifest is missing them', () {
      final asset = ShowroomAsset.fromJson({
        'variantId': 'variant-2',
        'variantName': 'Aerox',
        'modelName': 'Aerox 155',
        'hexCode': '#111111',
        'activeTier': 2,
      });

      expect(asset.activeTier, ViewerTier.staticGallery);
      expect(asset.cameraPresets.profile.position.z, 2.4);
      expect(asset.hasTurntable, isFalse);
    });
  });
}
