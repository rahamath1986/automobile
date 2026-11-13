import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/remote_image.dart';
import '../application/catalog_controllers.dart';

class ComparePage extends ConsumerWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(comparisonControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare vehicles'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(comparisonControllerProvider.notifier).clear(),
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.compare_arrows_rounded,
              title: 'No vehicles to compare',
              message:
                  'Select up to 3 variants while browsing models to compare prices, specifications and features side-by-side.',
              action: FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Browse showroom'),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Comparing ${items.length} of ${ComparisonController.maxItems} vehicles',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (items.length < ComparisonController.maxItems)
                        TextButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add vehicle'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _ComparisonTable(items: items),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ComparisonTable extends ConsumerWidget {
  const _ComparisonTable({required this.items});

  final List<ComparisonItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specKeys = _collectSpecKeys(items);
    final primary = Theme.of(context).colorScheme.primary;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle card headers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 140),
              ...items.map((item) {
                final heroImage = item.variant.primaryColor?.imageUrl ?? item.model.heroImageUrl;
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(left: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              height: 110,
                              width: double.infinity,
                              child: RemoteImage(url: heroImage, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => ref.read(comparisonControllerProvider.notifier).remove(item.variant.id),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.model.manufacturerName.toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.model.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                item.variant.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatCurrency(item.variant.basePrice),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: primary),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () {
                                    final uri = Uri(
                                      path: '/enquiry',
                                      queryParameters: {
                                        'variantId': item.variant.id,
                                        'modelName': item.model.name,
                                        'variantName': item.variant.name,
                                      },
                                    );
                                    context.push(uri.toString());
                                  },
                                  child: const Text('Enquire', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 18),

          _buildSectionHeader('General details'),
          _buildRow('Category', items.map((i) => i.model.categoryLabel).toList()),
          _buildRow('Fuel type', items.map((i) => i.model.fuelType).toList()),
          _buildRow(
            'Engine / Battery',
            items.map((i) {
              if (i.model.displacementCc != null) return '${i.model.displacementCc} cc';
              if (i.model.batteryCapacityKwh != null) return '${i.model.batteryCapacityKwh} kWh';
              return '—';
            }).toList(),
          ),
          _buildRow('Colours available', items.map((i) => '${i.variant.colors.length} colours').toList()),
          _buildRow('3D showroom', items.map((i) => i.variant.has3DAsset ? 'Available' : 'Standard view').toList()),

          if (specKeys.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionHeader('Key specifications'),
            for (final key in specKeys)
              _buildRow(
                _prettyKey(key),
                items.map((i) => _formatSpec(i.variant.specifications[key])).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildRow(String label, List<String> values) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          ...values.map((v) => Container(
                width: 200,
                margin: const EdgeInsets.only(left: 12),
                child: Text(
                  v,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              )),
        ],
      ),
    );
  }

  static List<String> _collectSpecKeys(List<ComparisonItem> items) {
    final set = <String>{};
    for (final item in items) {
      set.addAll(item.variant.specifications.keys);
    }
    return set.take(12).toList();
  }

  static String _formatSpec(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  static String _prettyKey(String key) {
    final spaced = key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    if (spaced.isEmpty) return spaced;
    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
