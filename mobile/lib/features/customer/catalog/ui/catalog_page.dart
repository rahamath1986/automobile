import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/catalog_notifier.dart';
import '../models/vehicle_model_summary.dart';

class CatalogPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialFuelType;

  const CatalogPage({
    super.key,
    this.initialCategory,
    this.initialFuelType,
  });

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(catalogNotifierProvider.notifier).loadModels(
              category: widget.initialCategory,
              fuelType: widget.initialFuelType,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: _buildBody(catalog),
    );
  }

  Widget _buildBody(CatalogState catalog) {
    switch (catalog.status) {
      case CatalogLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case CatalogLoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                catalog.errorMessage ?? 'Failed to load vehicles',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(catalogNotifierProvider.notifier).loadModels(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case CatalogLoadStatus.success:
        if (catalog.models.isEmpty) {
          return const Center(child: Text('No vehicles found.'));
        }
        return ListView.builder(
          itemCount: catalog.models.length,
          itemBuilder: (context, index) {
            final VehicleModelSummary model = catalog.models[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(model.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${model.manufacturerName} · ${model.category} · ₹${model.startingPrice.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (model.has3DAsset)
                      const Icon(Icons.threed_rotation, size: 18),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  // Navigate to showroom; variantId will be resolved from model detail.
                  // For now we pass the model id.
                  context.go('/showroom/${model.id}');
                },
              ),
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showFilterSheet(BuildContext context) {
    final categories = ['Motorcycle', 'Scooter', 'ElectricVehicle'];
    final fuelTypes = ['Petrol', 'Electric', 'Hybrid'];

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by category',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: categories
                  .map((c) => ActionChip(
                        label: Text(c),
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(catalogNotifierProvider.notifier)
                              .loadModels(category: c);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            const Text('Filter by fuel',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: fuelTypes
                  .map((f) => ActionChip(
                        label: Text(f),
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(catalogNotifierProvider.notifier)
                              .loadModels(fuelType: f);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(catalogNotifierProvider.notifier).clearFilters();
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}
