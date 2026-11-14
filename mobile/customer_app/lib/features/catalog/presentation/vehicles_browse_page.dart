import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/remote_image.dart';
import '../application/catalog_controllers.dart';
import '../domain/entities/vehicle.dart';

/// Screen 3 & Screen 4: Explore 2 Wheelers & Vehicle Listing
class VehiclesBrowsePage extends ConsumerStatefulWidget {
  const VehiclesBrowsePage({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<VehiclesBrowsePage> createState() => _VehiclesBrowsePageState();
}

class _VehiclesBrowsePageState extends ConsumerState<VehiclesBrowsePage> {
  // 'All', 'Petrol', 'Electric'
  String _activeTab = 'All';
  String? _selectedCategory; // 'Scooters', 'Motorcycles', 'Electric (EV)'

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final modelsState = ref.watch(catalogModelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedCategory != null ? _selectedCategory! : 'Explore 2 Wheelers',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedCategory = null),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter by Price, Fuel Type, and Brand')),
              );
            },
          ),
        ],
      ),
      body: _selectedCategory == null
          ? _buildScreen3CategoryHub(context, primary)
          : _buildScreen4Listing(context, primary, modelsState),
    );
  }

  /// Screen 3: Vehicle Categories
  Widget _buildScreen3CategoryHub(BuildContext context, Color primary) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Category 1: Scooters
        _CategoryCard(
          title: 'Scooters',
          subtitle: 'Stylish · Practical · Efficient',
          imageAsset: 'assets/images/vehicles/scooter_front.jpg',
          accentColor: const Color(0xFFDC2626),
          onTap: () => setState(() {
            _selectedCategory = 'Scooters';
            _activeTab = 'All';
          }),
        ),
        const SizedBox(height: 14),

        // Category 2: Motorcycles
        _CategoryCard(
          title: 'Motorcycles',
          subtitle: 'Performance · Power · Control',
          imageAsset: 'assets/images/vehicles/bike_black.jpg',
          accentColor: const Color(0xFF1E293B),
          onTap: () => setState(() {
            _selectedCategory = 'Motorcycles';
            _activeTab = 'All';
          }),
        ),
        const SizedBox(height: 14),

        // Category 3: Electric EV
        _CategoryCard(
          title: 'Electric (EV)',
          subtitle: 'Clean · Smart · Sustainable',
          imageAsset: 'assets/images/vehicles/tvs_iqube.jpg',
          accentColor: const Color(0xFF059669),
          isEV: true,
          onTap: () => setState(() {
            _selectedCategory = 'Electric (EV)';
            _activeTab = 'Electric';
          }),
        ),
      ],
    );
  }

  /// Screen 4: Vehicle Listing with Tabs (All, Petrol, Electric)
  Widget _buildScreen4Listing(
    BuildContext context,
    Color primary,
    AsyncValue<List<VehicleModelSummary>> modelsState,
  ) {
    return Column(
      children: [
        // Tabs: All, Petrol, Electric
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildFilterPill('All', primary),
              const SizedBox(width: 8),
              _buildFilterPill('Petrol', primary),
              const SizedBox(width: 8),
              _buildFilterPill('Electric', primary),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Model List
        Expanded(
          child: modelsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading models: $err')),
            data: (models) {
              final filtered = _filterModels(models);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 10),
                      Text(
                        'No $_activeTab models found in $_selectedCategory',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final model = filtered[index];
                  return _ListingTile(
                    model: model,
                    onTap: () => context.push('/models/${model.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<VehicleModelSummary> _filterModels(List<VehicleModelSummary> models) {
    return models.where((m) {
      if (_selectedCategory == 'Scooters') {
        if (!m.category.toUpperCase().contains('SCOOTER')) return false;
      } else if (_selectedCategory == 'Motorcycles') {
        if (!m.category.toUpperCase().contains('MOTORCYCLE')) return false;
      } else if (_selectedCategory == 'Electric (EV)') {
        if (!m.isElectric && !m.fuelType.toUpperCase().contains('ELECTRIC')) return false;
      }

      if (_activeTab == 'Petrol') {
        if (m.isElectric || m.fuelType.toUpperCase() == 'ELECTRIC') return false;
      } else if (_activeTab == 'Electric') {
        if (!m.isElectric && m.fuelType.toUpperCase() != 'ELECTRIC') return false;
      }

      return true;
    }).toList();
  }

  Widget _buildFilterPill(String label, Color primary) {
    final active = _activeTab == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.accentColor,
    required this.onTap,
    this.isEV = false,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isEV;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Vehicle Thumbnail in soft stage
                Container(
                  width: 90,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.two_wheeler_rounded, size: 36, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Category Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isEV) ...[
                            const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron Arrow
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.model, required this.onTap});

  final VehicleModelSummary model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Vehicle Studio Thumbnail
                Container(
                  width: 80,
                  height: 64,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RemoteImage(
                    url: model.heroImageUrl,
                    fallbackAsset: RemoteImage.resolveVehicleAsset(model.code),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),

                // Vehicle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Starts from ${formatCurrency(model.startingPrice)}*',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

