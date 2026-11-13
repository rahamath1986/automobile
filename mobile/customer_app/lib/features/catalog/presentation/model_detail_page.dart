import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/remote_image.dart';
import '../application/catalog_controllers.dart';
import '../domain/entities/vehicle.dart';

class ModelDetailPage extends ConsumerStatefulWidget {
  const ModelDetailPage({super.key, required this.modelId});

  final String modelId;

  @override
  ConsumerState<ModelDetailPage> createState() => _ModelDetailPageState();
}

class _ModelDetailPageState extends ConsumerState<ModelDetailPage> {
  String? _variantId;
  String? _colorId;
  String? _branchId;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(modelDetailProvider(widget.modelId));

    return detailState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(modelDetailProvider(widget.modelId)),
              ),
              const Positioned(
                top: 8,
                left: 8,
                child: BackButton(),
              ),
            ],
          ),
        ),
      ),
      data: (detail) {
        final variant = detail.variants.isEmpty
            ? null
            : (_variantId == null
                ? detail.primaryVariant
                : detail.variants.firstWhere(
                    (v) => v.id == _variantId,
                    orElse: () => detail.primaryVariant!,
                  ));

        final branches = ref.watch(branchesProvider).value ?? const <DealershipBranch>[];
        final effectiveBranchId = _branchId ?? (branches.isEmpty ? null : branches.first.id);

        final color = variant == null
            ? null
            : (_colorId == null
                ? variant.primaryColor
                : variant.colors.firstWhere(
                    (c) => c.id == _colorId,
                    orElse: () => variant.primaryColor ?? variant.colors.first,
                  ));

        final comparison = ref.watch(comparisonControllerProvider);
        final isComparing = variant != null && comparison.any((c) => c.key == variant.id);

        return Scaffold(
          body: _DetailBody(
            detail: detail,
            variantId: _variantId,
            colorId: _colorId,
            branchId: _branchId,
            onVariantChanged: (v) => setState(() {
              _variantId = v.id;
              _colorId = null;
            }),
            onColorChanged: (cId) => setState(() => _colorId = cId),
            onBranchChanged: (bId) => setState(() => _branchId = bId),
          ),
          bottomNavigationBar: variant == null
              ? null
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE8EDF5))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        IconButton.outlined(
                          tooltip: isComparing ? 'Remove from comparison' : 'Compare variant',
                          onPressed: () {
                            final added = ref
                                .read(comparisonControllerProvider.notifier)
                                .toggle(detail, variant);
                            if (!added) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You can compare up to 3 variants at a time.')),
                              );
                            }
                          },
                          icon: Icon(
                            isComparing ? Icons.check_circle_rounded : Icons.compare_arrows_rounded,
                            color: isComparing ? Theme.of(context).colorScheme.primary : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              final uri = Uri(
                                path: '/enquiry',
                                queryParameters: {
                                  'variantId': variant.id,
                                  if (effectiveBranchId != null) 'branchId': effectiveBranchId,
                                  if (color != null) 'colorId': color.id,
                                  'modelName': detail.name,
                                  'variantName': variant.name,
                                },
                              );
                              context.push(uri.toString());
                            },
                            child: const Text('Enquire'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final uri = Uri(
                                path: '/test-ride',
                                queryParameters: {
                                  'variantId': variant.id,
                                  if (effectiveBranchId != null) 'branchId': effectiveBranchId,
                                  'modelName': detail.name,
                                  'variantName': variant.name,
                                },
                              );
                              context.push(uri.toString());
                            },
                            child: const Text('Test ride'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.detail,
    required this.variantId,
    required this.colorId,
    required this.branchId,
    required this.onVariantChanged,
    required this.onColorChanged,
    required this.onBranchChanged,
  });

  final VehicleModelDetail detail;
  final String? variantId;
  final String? colorId;
  final String? branchId;
  final ValueChanged<VehicleVariant> onVariantChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onBranchChanged;

  VehicleVariant? get _variant {
    if (detail.variants.isEmpty) return null;
    if (variantId == null) return detail.primaryVariant;
    return detail.variants.firstWhere(
      (variant) => variant.id == variantId,
      orElse: () => detail.primaryVariant!,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = _variant;
    final color = variant == null
        ? null
        : (colorId == null
            ? variant.primaryColor
            : variant.colors.firstWhere(
                (item) => item.id == colorId,
                orElse: () => variant.primaryColor ?? variant.colors.first,
              ));

    final branchesState = ref.watch(branchesProvider);
    final branches = branchesState.value ?? const <DealershipBranch>[];
    final effectiveBranchId = branchId ?? (branches.isEmpty ? null : branches.first.id);

    final primary = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 290,
          backgroundColor: const Color(0xFFF4F6FB),
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(
                icon: Icons.share_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share ${detail.manufacturerName} ${detail.name} with your friends.')),
                  );
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                RemoteImage(url: color?.imageUrl ?? detail.heroImageUrl, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x22000000)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.manufacturerName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(text: detail.categoryLabel),
                    _Pill(text: detail.fuelType.toLowerCase() == 'electric' ? 'Electric' : 'Petrol'),
                    if (detail.displacementCc != null) _Pill(text: '${detail.displacementCc} cc'),
                    if (detail.batteryCapacityKwh != null)
                      _Pill(text: '${detail.batteryCapacityKwh!.toStringAsFixed(1)} kWh'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Starting from',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(variant?.basePrice ?? detail.startingPrice),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (detail.has3DAsset)
                      OutlinedButton.icon(
                        onPressed: variant == null
                            ? null
                            : () => _openShowroom(context, variant, color?.id),
                        icon: const Icon(Icons.view_in_ar_rounded, size: 18),
                        label: const Text('3D showroom'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (detail.variants.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Choose your variant'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.variants.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = detail.variants[index];
                        final selected = item.id == variant?.id;
                        return _VariantCard(
                          variant: item,
                          selected: selected,
                          onTap: () => onVariantChanged(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (variant != null && variant.colors.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Colour',
                    subtitle: color?.colorName ?? 'Choose a finish',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: variant.colors.map((item) {
                      final selected = item.id == color?.id;
                      return GestureDetector(
                        onTap: () => onColorChanged(item.id),
                        child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _hexColor(item.hexCode),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? primary : const Color(0xFFE2E8F0),
                                  width: selected ? 3 : 1,
                                ),
                              ),
                              child: selected
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: _contrastColor(item.hexCode),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 74,
                              child: Text(
                                item.colorName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionHeader(title: 'On-road estimate')),
                    if (branches.length > 1)
                      DropdownButton<String>(
                        value: effectiveBranchId,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(14),
                        items: branches
                            .map((branch) => DropdownMenuItem(
                                  value: branch.id,
                                  child: Text(branch.city.isEmpty ? branch.name : branch.city),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onBranchChanged(value);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (variant == null)
                  const Text('Variant pricing is unavailable for this model.')
                else
                  _PricingPanel(
                    variant: variant,
                    branchId: effectiveBranchId,
                  ),
              ],
            ),
          ),
        ),
        if (variant != null && variant.specifications.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Specifications'),
                  const SizedBox(height: 12),
                  _SpecTable(specifications: variant.specifications),
                ],
              ),
            ),
          ),
        if (variant != null && variant.features.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Highlights'),
                  const SizedBox(height: 12),
                  _FeatureWrap(features: variant.features),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Color _hexColor(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFF002C6C);
  }

  Color _contrastColor(String hex) {
    final color = _hexColor(hex);
    return color.computeLuminance() > 0.55 ? const Color(0xFF0F172A) : Colors.white;
  }

  void _openShowroom(BuildContext context, VehicleVariant variant, String? colorId) {
    final uri = Uri(
      path: '/viewer/${variant.id}',
      queryParameters: {if (colorId != null) 'colorId': colorId},
    );
    context.push(uri.toString());
  }
}

class _PricingPanel extends ConsumerWidget {
  const _PricingPanel({required this.variant, required this.branchId});

  final VehicleVariant variant;
  final String? branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingState = ref.watch(
      pricingProvider((variantId: variant.id, branchId: branchId)),
    );

    return pricingState.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ErrorState(
            compact: true,
            message: error.toString(),
            onRetry: () => ref.invalidate(
              pricingProvider((variantId: variant.id, branchId: branchId)),
            ),
          ),
        ),
      ),
      data: (pricing) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pricing.branchName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (pricing.inStock)
                    const _Pill(text: 'In stock', tone: Color(0xFF166534))
                  else
                    const _Pill(text: 'Enquire for stock', tone: Color(0xFF92400E)),
                ],
              ),
              const SizedBox(height: 14),
              _PriceRow(label: 'Ex-showroom', value: formatCurrency(pricing.exShowroomPrice)),
              _PriceRow(
                label: 'RTO registration${pricing.rtoPercent > 0 ? ' (${pricing.rtoPercent.toStringAsFixed(1)}%)' : ''}',
                value: formatCurrency(pricing.rtoCharges),
              ),
              _PriceRow(
                label: 'Insurance${pricing.insurancePercent > 0 ? ' (${pricing.insurancePercent.toStringAsFixed(1)}%)' : ''}',
                value: formatCurrency(pricing.insuranceCharges),
              ),
              if (pricing.accessoriesCharges > 0)
                _PriceRow(label: 'Accessories', value: formatCurrency(pricing.accessoriesCharges)),
              _PriceRow(label: 'Handling & logistics', value: formatCurrency(pricing.handlingCharges)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estimated on-road',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    formatCurrency(pricing.estimatedOnRoadPrice),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'EMI from ${formatEmiEstimate(pricing.estimatedOnRoadPrice)} / month · 36 months, 10.5% p.a.',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              if (pricing.disclaimer.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  pricing.disclaimer,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

class _SpecTable extends StatelessWidget {
  const _SpecTable({required this.specifications});

  final Map<String, dynamic> specifications;

  @override
  Widget build(BuildContext context) {
    final entries = specifications.entries
        .where((entry) => entry.value != null && entry.value.toString().trim().isNotEmpty)
        .take(14)
        .toList();

    if (entries.isEmpty) {
      return const Text('Specifications will be published soon.');
    }

    return Card(
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(20) : Radius.zero,
                  bottom: index == entries.length - 1 ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      _prettyKey(entries[index].key),
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Text(
                      _prettyValue(entries[index].value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureWrap extends StatelessWidget {
  const _FeatureWrap({required this.features});

  final Map<String, dynamic> features;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];

    void addValue(String key, dynamic value) {
      if (value is bool) {
        if (value) labels.add(_prettyKey(key));
      } else if (value is List) {
        for (final item in value) {
          if (item != null) labels.add(item.toString());
        }
      } else if (value is String && value.trim().isNotEmpty) {
        labels.add(value.trim());
      } else if (value is num) {
        labels.add('${_prettyKey(key)}: $value');
      }
    }

    final nested = features['features'];
    if (nested is List) {
      for (final item in nested) {
        if (item is String) {
          labels.add(item);
        } else if (item is Map && item['name'] != null) {
          labels.add(item['name'].toString());
        }
      }
    }

    for (final entry in features.entries) {
      if (entry.key == 'features') continue;
      addValue(entry.key, entry.value);
    }

    if (labels.isEmpty) {
      return const Text('Feature list will be published soon.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .toSet()
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({required this.variant, required this.selected, required this.onTap});

  final VehicleVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 156,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              variant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(variant.basePrice),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.tone});

  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: IconButton(onPressed: onPressed, icon: Icon(icon, size: 20)),
    );
  }
}

String _prettyKey(String key) {
  final spaced = key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}');
  if (spaced.isEmpty) return spaced;
  return spaced
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _prettyValue(dynamic value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) return value.map((item) => item.toString()).join(', ');
  if (value is Map) {
    return value.entries
        .map((entry) => '${_prettyKey(entry.key.toString())}: ${entry.value}')
        .join(' · ');
  }
  return value.toString();
}
