import '../datasources/catalog_api.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._api);

  final CatalogApi _api;

  @override
  Future<List<VehicleModelSummary>> getModels({String? category}) => _api.getModels(category: category);

  @override
  Future<VehicleModelDetail> getModelDetail(String modelId) => _api.getModelDetail(modelId);

  @override
  Future<List<DealershipBranch>> getBranches(String tenantId) => _api.getBranches(tenantId);

  @override
  Future<VariantBranchPricing> getPricing({required String variantId, String? branchId}) =>
      _api.getPricing(variantId: variantId, branchId: branchId);
}
