import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model_summary.dart';
import '../../../core/network/api_client.dart';

/// Provider exposing the CatalogService to the app.
final catalogServiceProvider = Provider<CatalogService>((ref) {
  final dio = ref.read(dioProvider);
  return CatalogService(dio);
});

class CatalogService {
  final Dio _dio;
  CatalogService(this._dio);

  /// Retrieves the list of vehicle models for the current tenant.
  /// Optional filters: category, manufacturerId, fuelType.
  Future<List<VehicleModelSummary>> fetchModels({
    String? category,
    String? manufacturerId,
    String? fuelType,
  }) async {
    final response = await _dio.get('/api/v1/catalog/models', queryParameters: {
      if (category != null) 'category': category,
      if (manufacturerId != null) 'manufacturerId': manufacturerId,
      if (fuelType != null) 'fuelType': fuelType,
    });

    final List data = response.data as List;
    return data.map((e) => VehicleModelSummary.fromJson(e as Map<String, dynamic>)).toList();
  }
}

