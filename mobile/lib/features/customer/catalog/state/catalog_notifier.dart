import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/vehicle_model_summary.dart';
import '../services/catalog_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────
enum CatalogLoadStatus { idle, loading, success, error }

class CatalogState {
  final CatalogLoadStatus status;
  final List<VehicleModelSummary> models;
  final String? errorMessage;
  final String? selectedCategory;
  final String? selectedFuelType;

  const CatalogState({
    required this.status,
    this.models = const [],
    this.errorMessage,
    this.selectedCategory,
    this.selectedFuelType,
  });

  CatalogState copyWith({
    CatalogLoadStatus? status,
    List<VehicleModelSummary>? models,
    String? errorMessage,
    String? selectedCategory,
    String? selectedFuelType,
  }) =>
      CatalogState(
        status: status ?? this.status,
        models: models ?? this.models,
        errorMessage: errorMessage,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        selectedFuelType: selectedFuelType ?? this.selectedFuelType,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final catalogNotifierProvider =
    StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final service = ref.read(catalogServiceProvider);
  return CatalogNotifier(service);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────
class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogService _service;

  CatalogNotifier(this._service)
      : super(const CatalogState(status: CatalogLoadStatus.idle));

  Future<void> loadModels({
    String? category,
    String? fuelType,
    String? manufacturerId,
  }) async {
    state = state.copyWith(
      status: CatalogLoadStatus.loading,
      selectedCategory: category,
      selectedFuelType: fuelType,
    );
    try {
      final models = await _service.fetchModels(
        category: category,
        fuelType: fuelType,
        manufacturerId: manufacturerId,
      );
      state = state.copyWith(status: CatalogLoadStatus.success, models: models);
    } catch (e) {
      state = state.copyWith(
        status: CatalogLoadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearFilters() => loadModels();
}

