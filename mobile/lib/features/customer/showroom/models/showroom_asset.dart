// models/showroom_asset.dart
class ShowroomAsset {
  final String variantId;
  final String variantCode;
  final String variantName;
  final String modelName;
  final double basePrice;
  final String? colorId;
  final String? colorName;
  final String? hexCode;
  final String? glbFileUrl;
  final String? usdzFileUrl;
  final int? modelFileSizeBytes;
  final bool? hasDracoCompression;
  final String activeTier; // e.g., "Tier1_Interactive3D"
  // Add other fields as needed (cameraPresets, hotspots, etc.)

  ShowroomAsset({
    required this.variantId,
    required this.variantCode,
    required this.variantName,
    required this.modelName,
    required this.basePrice,
    this.colorId,
    this.colorName,
    this.hexCode,
    this.glbFileUrl,
    this.usdzFileUrl,
    this.modelFileSizeBytes,
    this.hasDracoCompression,
    required this.activeTier,
  });

  factory ShowroomAsset.fromJson(Map<String, dynamic> json) => ShowroomAsset(
        variantId: json['variantId'] as String,
        variantCode: json['variantCode'] as String,
        variantName: json['variantName'] as String,
        modelName: json['modelName'] as String,
        basePrice: (json['basePrice'] as num).toDouble(),
        colorId: json['colorId'] as String?,
        colorName: json['colorName'] as String?,
        hexCode: json['hexCode'] as String?,
        glbFileUrl: json['glbFileUrl'] as String?,
        usdzFileUrl: json['usdzFileUrl'] as String?,
        modelFileSizeBytes: json['modelFileSizeBytes'] as int?,
        hasDracoCompression: json['hasDracoCompression'] as bool?,
        activeTier: json['activeTier'] as String,
      );
}

