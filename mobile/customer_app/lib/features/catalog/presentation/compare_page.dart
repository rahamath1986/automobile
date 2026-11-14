import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
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
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Side-by-Side Model Comparison',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Compare power, top speed, mileage, on-road prices, and digital console features side-by-side.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(comparisonControllerProvider.notifier).loadSampleComparison();
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Compare Popular (R15 vs Aerox vs iQube)'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Browse showroom catalogue'),
                    ),
                  ],
                ),
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

  static const double _labelWidth = 110.0;
  static const double _colWidth = 160.0;

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
              const SizedBox(width: _labelWidth),
              ...items.map((item) {
                final heroImage = item.variant.primaryColor?.imageUrl ?? item.model.heroImageUrl;
                return Container(
                  width: _colWidth,
                  margin: const EdgeInsets.only(left: 10),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 96,
                              width: double.infinity,
                              color: const Color(0xFFF8FAFC),
                              padding: const EdgeInsets.all(4),
                              child: RemoteImage(
                                url: heroImage,
                                fallbackAsset: RemoteImage.resolveVehicleAsset('${item.model.code} ${item.variant.name}'),
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => ref.read(comparisonControllerProvider.notifier).remove(item.variant.id),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded, size: 15, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.model.manufacturerName.toUpperCase(),
                                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.model.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                item.variant.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(item.variant.basePrice),
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: primary),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
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
                                  child: const Text('Enquire', style: TextStyle(fontSize: 11.5)),
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
          const SizedBox(height: 14),

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
          _buildRow(
            'Colours available',
            items.map((i) {
              if (i.variant.colors.isEmpty) return 'Standard finish';
              return i.variant.colors.map((c) => c.colorName).join('\n');
            }).toList(),
          ),

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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildRow(String label, List<String> values) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          ...values.map((v) => Container(
                width: _colWidth,
                margin: const EdgeInsets.only(left: 10),
                child: Text(
                  v,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.35,
                  ),
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
