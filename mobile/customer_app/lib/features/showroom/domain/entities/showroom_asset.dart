import '../../../catalog/domain/entities/vehicle.dart';
import '../../../../core/utils/json_helpers.dart';

enum ViewerTier {
  interactive3D,
  turntable360,
  staticGallery;

  static ViewerTier fromJson(dynamic value) {
    if (value is num) {
      return switch (value.toInt()) {
        1 => ViewerTier.turntable360,
        2 => ViewerTier.staticGallery,
        _ => ViewerTier.interactive3D,
      };
    }

    final normalized = asString(value).toLowerCase();
    if (normalized.contains('turntable') || normalized.contains('tier2')) {
      return ViewerTier.turntable360;
    }
    if (normalized.contains('static') || normalized.contains('gallery') || normalized.contains('tier3')) {
      return ViewerTier.staticGallery;
    }
    return ViewerTier.interactive3D;
  }

  String get label => switch (this) {
        ViewerTier.interactive3D => 'Interactive 3D',
        ViewerTier.turntable360 => '360° Turntable',
        ViewerTier.staticGallery => 'Photo Gallery',
      };
}

class CameraVector3 {
  const CameraVector3({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;

  factory CameraVector3.fromJson(Map<String, dynamic> json) => CameraVector3(
        x: asDouble(json['x']),
        y: asDouble(json['y']),
        z: asDouble(json['z']),
      );
}

class CameraPreset {
  const CameraPreset({
    required this.position,
    required this.target,
    required this.fov,
    required this.minPolarAngleDeg,
    required this.maxPolarAngleDeg,
    required this.minDistanceMeters,
    required this.maxDistanceMeters,
  });

  final CameraVector3 position;
  final CameraVector3 target;
  final double fov;
  final double minPolarAngleDeg;
  final double maxPolarAngleDeg;
  final double minDistanceMeters;
  final double maxDistanceMeters;

  factory CameraPreset.fromJson(Map<String, dynamic> json) => CameraPreset(
        position: CameraVector3.fromJson(
          json['position'] is Map ? Map<String, dynamic>.from(json['position'] as Map) : const {},
        ),
        target: CameraVector3.fromJson(
          json['target'] is Map ? Map<String, dynamic>.from(json['target'] as Map) : const {},
        ),
        fov: asDouble(json['fov'], 45),
        minPolarAngleDeg: asDouble(json['minPolarAngleDeg'], 5),
        maxPolarAngleDeg: asDouble(json['maxPolarAngleDeg'], 75),
        minDistanceMeters: asDouble(json['minDistanceMeters'], 1.5),
        maxDistanceMeters: asDouble(json['maxDistanceMeters'], 6),
      );
}

class CameraPresetsManifest {
  const CameraPresetsManifest({
    required this.hero,
    required this.profile,
    required this.cockpit,
    required this.rear,
    required this.top,
  });

  final CameraPreset hero;
  final CameraPreset profile;
  final CameraPreset cockpit;
  final CameraPreset rear;
  final CameraPreset top;

  static CameraPresetsManifest fallback() {
    final preset = CameraPreset(
      position: const CameraVector3(x: 2.4, y: 1.2, z: 2.4),
      target: const CameraVector3(x: 0, y: 0.6, z: 0),
      fov: 45,
      minPolarAngleDeg: 5,
      maxPolarAngleDeg: 75,
      minDistanceMeters: 1.5,
      maxDistanceMeters: 6,
    );
    return CameraPresetsManifest(
      hero: preset,
      profile: preset,
      cockpit: preset,
      rear: preset,
      top: preset,
    );
  }

  factory CameraPresetsManifest.fromJson(Map<String, dynamic> json) {
    CameraPreset parse(String key) {
      final raw = json[key];
      if (raw is Map) {
        return CameraPreset.fromJson(Map<String, dynamic>.from(raw));
      }
      return fallback().hero;
    }

    return CameraPresetsManifest(
      hero: parse('heroView'),
      profile: parse('profileView'),
      cockpit: parse('cockpitView'),
      rear: parse('rearView'),
      top: parse('topView'),
    );
  }
}

class ShowroomHotspot {
  const ShowroomHotspot({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.position,
    this.specMetric,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final CameraVector3 position;
  final String? specMetric;

  factory ShowroomHotspot.fromJson(Map<String, dynamic> json) => ShowroomHotspot(
        id: asString(json['id']),
        title: asString(json['title']),
        description: asString(json['description']),
        category: asString(json['category'], 'Mechanical'),
        position: CameraVector3.fromJson(
          json['position'] is Map ? Map<String, dynamic>.from(json['position'] as Map) : const {},
        ),
        specMetric: asNullableString(json['specMetric']),
      );
}

class ShowroomAsset {
  const ShowroomAsset({
    required this.variantId,
    required this.variantCode,
    required this.variantName,
    required this.modelName,
    required this.basePrice,
    required this.colorName,
    required this.hexCode,
    required this.activeTier,
    required this.turntableFrames,
    required this.staticGallery,
    required this.cameraPresets,
    required this.hotspots,
    required this.availableColors,
    this.colorId,
    this.glbFileUrl,
    this.usdzFileUrl,
    this.modelFileSizeBytes = 0,
    this.hasDracoCompression = false,
  });

  final String variantId;
  final String variantCode;
  final String variantName;
  final String modelName;
  final double basePrice;
  final String? colorId;
  final String colorName;
  final String hexCode;
  final ViewerTier activeTier;
  final String? glbFileUrl;
  final String? usdzFileUrl;
  final int modelFileSizeBytes;
  final bool hasDracoCompression;
  final List<String> turntableFrames;
  final List<String> staticGallery;
  final CameraPresetsManifest cameraPresets;
  final List<ShowroomHotspot> hotspots;
  final List<VehicleColor> availableColors;

  bool get hasTurntable => turntableFrames.isNotEmpty;
  bool get hasGallery => staticGallery.isNotEmpty;

  factory ShowroomAsset.fromJson(Map<String, dynamic> json) {
    return ShowroomAsset(
      variantId: asString(json['variantId']),
      variantCode: asString(json['variantCode']),
      variantName: asString(json['variantName']),
      modelName: asString(json['modelName']),
      basePrice: asDouble(json['basePrice']),
      colorId: asNullableString(json['colorId']),
      colorName: asString(json['colorName'], 'Standard'),
      hexCode: asString(json['hexCode'], '#002C6C'),
      activeTier: ViewerTier.fromJson(json['activeTier']),
      glbFileUrl: asNullableString(json['glbFileUrl']),
      usdzFileUrl: asNullableString(json['usdzFileUrl']),
      modelFileSizeBytes: asInt(json['modelFileSizeBytes']),
      hasDracoCompression: asBool(json['hasDracoCompression']),
      turntableFrames: asStringList(json['turntable360FrameUrls']),
      staticGallery: asStringList(json['staticGalleryImageUrls']),
      cameraPresets: json['cameraPresets'] is Map
          ? CameraPresetsManifest.fromJson(Map<String, dynamic>.from(json['cameraPresets'] as Map))
          : CameraPresetsManifest.fallback(),
      hotspots: asMapList(json['hotspots']).map(ShowroomHotspot.fromJson).toList(),
      availableColors: asMapList(json['availableColors']).map(VehicleColor.fromJson).toList(),
    );
  }
}
