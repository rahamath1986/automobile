import '../../../../core/network/api_client.dart';
import '../../domain/entities/vehicle.dart';

class CatalogApi {
  CatalogApi(this._client);

  final ApiClient _client;

  Future<List<VehicleModelSummary>> getModels({String? category}) async {
    final payload = await _client.get('/catalog/models', query: {'category': category});
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => VehicleModelSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }

  Future<VehicleModelDetail> getModelDetail(String modelId) async {
    final payload = await _client.get('/catalog/models/$modelId');
    if (payload is Map<String, dynamic>) {
      return VehicleModelDetail.fromJson(payload);
    }
    throw StateError('Vehicle model details were not returned.');
  }

  Future<List<DealershipBranch>> getBranches(String tenantId) async {
    final payload = await _client.get('/tenants/$tenantId/branches');
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => DealershipBranch.fromJson(Map<String, dynamic>.from(item)))
          .where((branch) => branch.isActive)
          .toList();
    }
    return const [];
  }

  Future<VariantBranchPricing> getPricing({required String variantId, String? branchId}) async {
    final payload = await _client.get(
      '/catalog/variants/$variantId/pricing',
      query: {'branchId': branchId},
    );

    if (payload is Map<String, dynamic>) {
      return VariantBranchPricing.fromJson(payload);
    }

    throw StateError('Branch pricing was not returned.');
  }
}
