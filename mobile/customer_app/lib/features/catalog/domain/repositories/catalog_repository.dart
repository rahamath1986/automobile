import '../entities/vehicle.dart';

abstract class CatalogRepository {
  Future<List<VehicleModelSummary>> getModels({String? category});
  Future<VehicleModelDetail> getModelDetail(String modelId);
  Future<List<DealershipBranch>> getBranches(String tenantId);
  Future<VariantBranchPricing> getPricing({required String variantId, String? branchId});
}
