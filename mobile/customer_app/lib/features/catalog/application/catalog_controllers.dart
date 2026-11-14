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

final List<ComparisonItem> sampleComparisonItems = [
  ComparisonItem(
    model: const VehicleModelSummary(
      id: 'mod-yamaha-r15-v4',
      manufacturerId: 'mfr-yamaha',
      manufacturerName: 'Yamaha',
      manufacturerCode: 'YAMAHA',
      code: 'YZF-R15-V4',
      name: 'YZF-R15 V4',
      category: 'Motorcycle',
      fuelType: 'Petrol',
      startingPrice: 182000,
      variantCount: 4,
      colorCount: 5,
      has3DAsset: true,
      displacementCc: 155,
      heroImageUrl: 'assets/images/vehicles/yamaha_r15_v4.jpg',
    ),
    variant: VehicleVariant(
      id: 'var-r15-v4-racing-blue',
      modelId: 'mod-yamaha-r15-v4',
      code: 'R15-V4-RB',
      name: 'Racing Blue Metallic (Quickshifter)',
      basePrice: 187000,
      colors: const [
        VehicleColor(
          id: 'col-1',
          variantId: 'var-r15-v4-racing-blue',
          colorName: 'Racing Blue',
          hexCode: '#002B7F',
          isPrimary: true,
          imageUrl: 'assets/images/vehicles/yamaha_r15_v4.jpg',
        ),
      ],
      assets3D: const [],
      specificationsJson: '{"Displacement":"155 cc Liquid-Cooled SOHC","Max Power":"18.4 PS @ 10,000 rpm","Max Torque":"14.2 Nm @ 7,500 rpm","Transmission":"6-Speed with Assist & Slipper Clutch","Fuel Tank":"11 L","Brakes":"Dual Channel ABS","Kerb Weight":"142 kg"}',
      featuresJson: '{"Quick Shifter":"Yes (Up-shift)","Traction Control":"Yes","Variable Valve Actuation (VVA)":"Yes","Bluetooth Connectivity":"Y-Connect Connected App"}',
    ),
  ),
  ComparisonItem(
    model: const VehicleModelSummary(
      id: 'mod-yamaha-aerox-155',
      manufacturerId: 'mfr-yamaha',
      manufacturerName: 'Yamaha',
      manufacturerCode: 'YAMAHA',
      code: 'AEROX-155',
      name: 'Aerox 155',
      category: 'Scooter',
      fuelType: 'Petrol',
      startingPrice: 148000,
      variantCount: 3,
      colorCount: 4,
      has3DAsset: true,
      displacementCc: 155,
      heroImageUrl: 'assets/images/vehicles/yamaha_aerox_155.jpg',
    ),
    variant: VehicleVariant(
      id: 'var-aerox-motogp',
      modelId: 'mod-yamaha-aerox-155',
      code: 'AEROX-155-GP',
      name: 'Monster Energy MotoGP Edition',
      basePrice: 152500,
      colors: const [
        VehicleColor(
          id: 'col-2',
          variantId: 'var-aerox-motogp',
          colorName: 'Monster Energy Black',
          hexCode: '#111827',
          isPrimary: true,
          imageUrl: 'assets/images/vehicles/yamaha_aerox_155.jpg',
        ),
      ],
      assets3D: const [],
      specificationsJson: '{"Displacement":"155 cc Liquid-Cooled SOHC","Max Power":"15.0 PS @ 8,000 rpm","Max Torque":"13.9 Nm @ 6,500 rpm","Transmission":"V-Belt Automatic CVT","Fuel Tank":"5.5 L (External Cap)","Brakes":"Single Channel ABS","Kerb Weight":"126 kg"}',
      featuresJson: '{"Underseat Storage":"24.5 Litres","Variable Valve Actuation (VVA)":"Yes","Smart Motor Generator (SMG)":"Yes","Bluetooth Connectivity":"Y-Connect Digital Cluster"}',
    ),
  ),
  ComparisonItem(
    model: const VehicleModelSummary(
      id: 'mod-tvs-iqube',
      manufacturerId: 'mfr-tvs',
      manufacturerName: 'TVS Motor Company',
      manufacturerCode: 'TVS',
      code: 'TVS-IQUBE',
      name: 'TVS iQube Electric',
      category: 'Electric',
      fuelType: 'Electric',
      startingPrice: 117000,
      variantCount: 3,
      colorCount: 4,
      has3DAsset: true,
      batteryCapacityKwh: 3.4,
      heroImageUrl: 'assets/images/vehicles/tvs_iqube.jpg',
    ),
    variant: VehicleVariant(
      id: 'var-iqube-st',
      modelId: 'mod-tvs-iqube',
      code: 'IQUBE-ST-34',
      name: 'ST 3.4 kWh SmartXonnect',
      basePrice: 129000,
      colors: const [
        VehicleColor(
          id: 'col-3',
          variantId: 'var-iqube-st',
          colorName: 'Titanium Grey Matte',
          hexCode: '#475569',
          isPrimary: true,
          imageUrl: 'assets/images/vehicles/tvs_iqube.jpg',
        ),
      ],
      assets3D: const [],
      specificationsJson: '{"Battery Capacity":"3.4 kWh Lithium-Ion (IP67)","Certified Range":"100 km (Eco)","Top Speed":"78 km/h","Motor Type":"BLDC Hub Motor (4.4 kW Peak)","Charging Time":"0-80% in 4h 30m","Brakes":"Front Disc / Rear Drum Combined","Kerb Weight":"118 kg"}',
      featuresJson: '{"Touchscreen TFT Console":"7-inch Full Colour Screen","Turn-by-Turn Navigation":"Yes (Voice assist)","Regenerative Braking":"Yes","Telematics & Geofencing":"SmartXonnect Live Telemetry"}',
    ),
  ),
];

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

  void loadSampleComparison() {
    state = List.from(sampleComparisonItems);
  }

  bool contains(String variantId) => state.any((item) => item.key == variantId);
}
