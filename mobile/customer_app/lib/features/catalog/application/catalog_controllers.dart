import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../branding/application/branding_controller.dart';
import '../../../core/providers.dart';
import '../data/datasources/catalog_api.dart';
import '../data/repositories/catalog_repository_impl.dart';
import '../domain/entities/vehicle.dart';
import '../domain/repositories/catalog_repository.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(apiClientProvider)));

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(ref.watch(catalogApiProvider));
});

enum CatalogCategory { all, motorcycle, scooter, electric }

extension CatalogCategoryX on CatalogCategory {
  String get label => switch (this) {
        CatalogCategory.all => 'All',
        CatalogCategory.motorcycle => 'Motorcycles',
        CatalogCategory.scooter => 'Scooters',
        CatalogCategory.electric => 'Electric',
      };

  String? get apiValue => switch (this) {
        CatalogCategory.all => null,
        CatalogCategory.motorcycle => 'Motorcycle',
        CatalogCategory.scooter => 'Scooter',
        CatalogCategory.electric => 'ElectricVehicle',
      };

  bool matches(VehicleModelSummary model) {
    return switch (this) {
      CatalogCategory.all => true,
      CatalogCategory.motorcycle => model.category.toUpperCase().contains('MOTORCYCLE'),
      CatalogCategory.scooter => model.category.toUpperCase().contains('SCOOTER'),
      CatalogCategory.electric =>
        model.category.toUpperCase().contains('ELECTRIC') || model.fuelType.toUpperCase() == 'ELECTRIC',
    };
  }
}

class CatalogFilter {
  const CatalogFilter({this.category = CatalogCategory.all, this.query = ''});

  final CatalogCategory category;
  final String query;

  CatalogFilter copyWith({CatalogCategory? category, String? query}) =>
      CatalogFilter(category: category ?? this.category, query: query ?? this.query);

  List<VehicleModelSummary> apply(List<VehicleModelSummary> models) {
    final normalizedQuery = query.trim().toLowerCase();
    return models.where((model) {
      if (!category.matches(model)) return false;
      if (normalizedQuery.isEmpty) return true;
      return model.name.toLowerCase().contains(normalizedQuery) ||
          model.manufacturerName.toLowerCase().contains(normalizedQuery) ||
          model.code.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
}

final catalogFilterProvider = NotifierProvider<CatalogFilterController, CatalogFilter>(
  CatalogFilterController.new,
);

class CatalogFilterController extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  void setCategory(CatalogCategory category) {
    state = state.copyWith(category: category);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void clear() {
    state = const CatalogFilter();
  }
}

final catalogModelsProvider = FutureProvider.autoDispose<List<VehicleModelSummary>>((ref) async {
  // Only the category changes the server query; free-text search is applied locally
  // so typing does not fire a network request on every keystroke.
  final category = ref.watch(catalogFilterProvider.select((filter) => filter.category));
  return ref.watch(catalogRepositoryProvider).getModels(category: category.apiValue);
});

final modelDetailProvider = FutureProvider.autoDispose.family<VehicleModelDetail, String>((ref, modelId) {
  return ref.watch(catalogRepositoryProvider).getModelDetail(modelId);
});

final branchesProvider = FutureProvider.autoDispose<List<DealershipBranch>>((ref) async {
  final branding = ref.watch(brandingControllerProvider).value;
  final tenantId = branding?.tenantId;
  if (tenantId == null || tenantId.isEmpty) {
    return const [];
  }

  return ref.watch(catalogRepositoryProvider).getBranches(tenantId);
});

typedef PricingQuery = ({String variantId, String? branchId});

final pricingProvider = FutureProvider.autoDispose.family<VariantBranchPricing, PricingQuery>(
  (ref, query) => ref.watch(catalogRepositoryProvider).getPricing(
        variantId: query.variantId,
        branchId: query.branchId,
      ),
);

final branchPricingProvider = FutureProvider.autoDispose.family<List<VariantBranchPricing>, String>(
  (ref, variantId) async {
    final repository = ref.watch(catalogRepositoryProvider);
    final branches = await ref.watch(branchesProvider.future);

    if (branches.isEmpty) {
      return [await repository.getPricing(variantId: variantId)];
    }

    final results = await Future.wait(
      branches.map((branch) => repository.getPricing(variantId: variantId, branchId: branch.id)),
    );
    results.sort((a, b) => a.estimatedOnRoadPrice.compareTo(b.estimatedOnRoadPrice));
    return results;
  },
);

class ComparisonItem {
  const ComparisonItem({required this.model, required this.variant});

  final VehicleModelSummary model;
  final VehicleVariant variant;

  String get key => variant.id;
}

final comparisonControllerProvider = NotifierProvider<ComparisonController, List<ComparisonItem>>(
  ComparisonController.new,
);

class ComparisonController extends Notifier<List<ComparisonItem>> {
  static const maxItems = 3;

  @override
  List<ComparisonItem> build() => const [];

  bool toggle(VehicleModelSummary model, VehicleVariant variant) {
    final exists = state.any((item) => item.key == variant.id);
    if (exists) {
      state = state.where((item) => item.key != variant.id).toList();
      return true;
    }

    if (state.length >= maxItems) {
      return false;
    }

    state = [...state, ComparisonItem(model: model, variant: variant)];
    return true;
  }

  void remove(String variantId) {
    state = state.where((item) => item.key != variantId).toList();
  }

  void clear() {
    state = const [];
  }

  bool contains(String variantId) => state.any((item) => item.key == variantId);
}
