import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/remote_image.dart';
import '../application/catalog_controllers.dart';
import '../domain/entities/vehicle.dart';
import 'widgets/emi_calculator_widget.dart';

enum VehiclePhotoAngle {
  front('FRONT', Icons.explore_outlined),
  side('SIDE', Icons.two_wheeler_rounded),
  back('BACK', Icons.replay_rounded);

  const VehiclePhotoAngle(this.label, this.icon);
  final String label;
  final IconData icon;
}

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
  bool _isFavorite = false;

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
          backgroundColor: Colors.white,
          body: _DetailBody(
            detail: detail,
            variantId: _variantId,
            colorId: _colorId,
            branchId: _branchId,
            isFavorite: _isFavorite,
            onFavoriteToggled: () => setState(() => _isFavorite = !_isFavorite),
            onVariantChanged: (v) => setState(() {
              _variantId = v.id;
              _colorId = v.primaryColor?.id ?? (v.colors.isNotEmpty ? v.colors.first.id : null);
            }),
            onColorChanged: (cId) => setState(() => _colorId = cId),
            onBranchChanged: (bId) => setState(() => _branchId = bId),
          ),
          bottomNavigationBar: variant == null
              ? null
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
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
                                color: isComparing ? const Color(0xFFDC2626) : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final uri = Uri(
                                    path: '/test-ride',
                                    queryParameters: {
                                      'variantId': variant.id,
                                      'branchId': effectiveBranchId ?? '22222222-2222-2222-2222-222222222222',
                                      'modelName': detail.name,
                                      'variantName': variant.name,
                                    },
                                  );
                                  context.push(uri.toString());
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                                  foregroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  'Book Test Ride',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final uri = Uri(
                                    path: '/enquiry',
                                    queryParameters: {
                                      'variantId': variant.id,
                                      'branchId': effectiveBranchId ?? '22222222-2222-2222-2222-222222222222',
                                      if (color != null) 'colorId': color.id,
                                      'modelName': detail.name,
                                      'variantName': variant.name,
                                    },
                                  );
                                  context.push(uri.toString());
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626), // Alagendra Red
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  'Get a Quote',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'No login required',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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

class _DetailBody extends StatefulWidget {
  const _DetailBody({
    required this.detail,
    required this.variantId,
    required this.colorId,
    required this.branchId,
    required this.isFavorite,
    required this.onFavoriteToggled,
    required this.onVariantChanged,
    required this.onColorChanged,
    required this.onBranchChanged,
  });

  final VehicleModelDetail detail;
  final String? variantId;
  final String? colorId;
  final String? branchId;
  final bool isFavorite;
  final VoidCallback onFavoriteToggled;
  final ValueChanged<VehicleVariant> onVariantChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onBranchChanged;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  VehicleVariant? get _variant {
    if (widget.detail.variants.isEmpty) return null;
    if (widget.variantId == null) return widget.detail.primaryVariant;
    return widget.detail.variants.firstWhere(
      (variant) => variant.id == widget.variantId,
      orElse: () => widget.detail.primaryVariant!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final variant = _variant;
    final color = variant == null
        ? null
        : (widget.colorId == null
            ? variant.primaryColor
            : variant.colors.firstWhere(
                (item) => item.id == widget.colorId,
                orElse: () => variant.primaryColor ?? variant.colors.first,
              ));

    return Consumer(
      builder: (context, ref, _) {
        final branchesState = ref.watch(branchesProvider);
        final branches = branchesState.value ?? const <DealershipBranch>[];
        final effectiveBranchId = widget.branchId ?? (branches.isEmpty ? null : branches.first.id);

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 380,
              backgroundColor: const Color(0xFFF8FAFC),
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
                  padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
                  child: _CircleButton(
                    icon: widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: widget.isFavorite ? const Color(0xFFDC2626) : null,
                    onPressed: widget.onFavoriteToggled,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
                  child: _CircleButton(
                    icon: Icons.share_outlined,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share ${widget.detail.manufacturerName} ${widget.detail.name} with your friends.')),
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _BikeWale360Viewer(
                  detail: widget.detail,
                  variant: variant,
                  color: color,
                ),
              ),
            ),

            // Vehicle Title, Price & Spec Chips (Matching Screen 5)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.detail.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatCurrency(variant?.basePrice ?? widget.detail.startingPrice),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Ex-showroom',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3 Quick Spec Chips
                    Row(
                      children: [
                        if (widget.detail.isElectric) ...[
                          _specCard('100 km', 'Range (Eco)'),
                          const SizedBox(width: 10),
                          _specCard(
                            widget.detail.batteryCapacityKwh != null
                                ? '${widget.detail.batteryCapacityKwh!.toStringAsFixed(1)} kWh'
                                : '3.4 kWh',
                            'Battery (IP67)',
                          ),
                          const SizedBox(width: 10),
                          _specCard('78 km/h', 'Top Speed'),
                        ] else ...[
                          _specCard(
                            widget.detail.displacementCc != null ? '${widget.detail.displacementCc} cc' : '155 cc',
                            'Displacement',
                          ),
                          const SizedBox(width: 10),
                          _specCard('18.4 PS', 'Max Power'),
                          const SizedBox(width: 10),
                          _specCard('45 km/l*', 'Mileage'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Color Selector Row (Matching Screen 5)
            if (variant != null && variant.colors.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Color: ${color?.colorName ?? variant.colors.first.colorName}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: variant.colors.map((item) {
                          final selected = item.id == color?.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: GestureDetector(
                              onTap: () => widget.onColorChanged(item.id),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _hexColor(item.hexCode),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                    width: selected ? 3.0 : 1.5,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: selected
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: _contrastColor(item.hexCode),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Trims / Variant selector
            if (widget.detail.variants.length > 1)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Variant / Trim',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.detail.variants.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = widget.detail.variants[index];
                            final selected = item.id == variant?.id;
                            return _VariantCard(
                              variant: item,
                              selected: selected,
                              onTap: () => widget.onVariantChanged(item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // Tab bar (Overview | Features | Specs)
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFDC2626), // Alagendra Red
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFFDC2626),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Features'),
                    Tab(text: 'Specs'),
                  ],
                ),
              ),
            ),

            // Tab Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    switch (_tabController.index) {
                      case 1:
                        return _buildFeaturesTab(variant);
                      case 2:
                        return _buildSpecsTab(variant);
                      default:
                        return _buildOverviewTab(variant, effectiveBranchId, branches);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _specCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(VehicleVariant? variant, String? branchId, List<DealershipBranch> branches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // On-road estimate and EMI calculator
        Row(
          children: [
            const Expanded(
              child: Text(
                'On-Road Price Breakdown',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
            if (branches.length > 1)
              DropdownButton<String>(
                value: branchId,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: branches
                    .map((branch) => DropdownMenuItem(
                          value: branch.id,
                          child: Text(branch.city.isEmpty ? branch.name : branch.city, style: const TextStyle(fontSize: 12.5)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) widget.onBranchChanged(value);
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (variant != null)
          _PricingPanel(variant: variant, branchId: branchId),

        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => EmiCalculatorWidget.show(
                  context,
                  initialPrice: (variant?.basePrice ?? widget.detail.startingPrice).toDouble(),
                  modelName: widget.detail.name,
                  variantName: variant?.name,
                ),
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: const Text('Calculate EMI'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesTab(VehicleVariant? variant) {
    final features = variant?.features ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Features & Technology',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        if (features.isNotEmpty)
          _FeatureWrap(features: features)
        else
          Column(
            children: [
              _featureItem(Icons.key_rounded, 'Smart Key System', 'Keyless ignition, answer-back and remote seat opening.'),
              _featureItem(Icons.lightbulb_rounded, 'Full LED Headlamp', 'Superior night-time visibility and signature DRL.'),
              _featureItem(Icons.speed_rounded, 'Digital Speedometer Console', 'Trip meter, fuel gauge, clock and service reminder.'),
              _featureItem(Icons.sports_motorsports_rounded, 'Large Underseat Storage', 'Spacious storage with front glove box and USB charging.'),
            ],
          ),
      ],
    );
  }

  Widget _featureItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsTab(VehicleVariant? variant) {
    final specs = variant?.specifications ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Specifications',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        if (specs.isNotEmpty)
          _SpecTable(specifications: specs)
        else
          _SpecTable(
            specifications: {
              'Engine Type': '4 Stroke, SI Engine, Air Cooled',
              'Displacement': '109.51 cc',
              'Max Power': '7.8 PS @ 8000 rpm',
              'Max Torque': '8.8 Nm @ 5500 rpm',
              'Fuel System': 'Programmed Fuel Injection (PGM-FI)',
              'Starting Method': 'Self / Kick',
              'Clutch Type': 'Automatic Centrifugal Clutch Dry Type',
              'Transmission': 'V-Matic Automatic',
              'Brakes Front': '130 mm Drum',
              'Brakes Rear': '130 mm Drum with Equalizer (CBS)',
              'Fuel Tank Capacity': '5.3 Litres',
              'Kerb Weight': '106 kg',
            },
          ),
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
}

// --- INTERACTIVE MULTI-ANGLE & 360 VIEWER (MATCHING IMAGE 1 & IMAGE 2) ---

enum _ViewMode {
  rotation360,
  front,
  rear,
  side,
}

class _BikeWale360Viewer extends StatefulWidget {
  const _BikeWale360Viewer({
    required this.detail,
    required this.variant,
    required this.color,
  });

  final VehicleModelDetail detail;
  final VehicleVariant? variant;
  final VehicleColor? color;

  @override
  State<_BikeWale360Viewer> createState() => _BikeWale360ViewerState();
}

class _BikeWale360ViewerState extends State<_BikeWale360Viewer> {
  double _degrees = 0.0;
  bool _isAutoSpinning = false;
  Timer? _spinTimer;
  _ViewMode _activeMode = _ViewMode.front;

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoSpin() {
    setState(() {
      _isAutoSpinning = !_isAutoSpinning;
      if (_isAutoSpinning) {
        _activeMode = _ViewMode.rotation360;
        _spinTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _degrees = (_degrees + 1.8) % 360;
          });
        });
      } else {
        _spinTimer?.cancel();
      }
    });
  }

  void _step(double delta) {
    if (_isAutoSpinning) _toggleAutoSpin();
    setState(() {
      _activeMode = _ViewMode.rotation360;
      _degrees = (_degrees + delta) % 360;
      if (_degrees < 0) _degrees += 360;
    });
  }

  void _setDegrees(double d) {
    if (_isAutoSpinning) _toggleAutoSpin();
    setState(() {
      _activeMode = _ViewMode.rotation360;
      _degrees = (d % 360 + 360) % 360;
    });
  }

  void _selectMode(_ViewMode mode) {
    if (_isAutoSpinning) _toggleAutoSpin();
    setState(() {
      _activeMode = mode;
      switch (mode) {
        case _ViewMode.front:
          _degrees = 90.0;
          break;
        case _ViewMode.rear:
          _degrees = 270.0;
          break;
        case _ViewMode.side:
          _degrees = 0.0;
          break;
        case _ViewMode.rotation360:
          break;
      }
    });
  }

  static (String assetPath, bool isMirrored) _resolveImage(
    VehicleModelDetail detail,
    VehicleVariant? variant,
    VehicleColor? color,
    _ViewMode mode,
    double degrees,
  ) {
    final colorName = (color?.colorName ?? '').toLowerCase();

    // Colorway prefix
    String prefix = 'scooter';
    if (colorName.contains('blue') || colorName.contains('racing') || colorName.contains('cyan')) {
      prefix = 'scooter_blue';
    } else if (colorName.contains('black') || colorName.contains('dark') || colorName.contains('knight')) {
      prefix = 'scooter_black';
    } else if (colorName.contains('grey') ||
        colorName.contains('gray') ||
        colorName.contains('silver') ||
        colorName.contains('metallic') ||
        colorName.contains('white')) {
      prefix = 'scooter_grey';
    }

    switch (mode) {
      case _ViewMode.front:
        return ('assets/images/vehicles/${prefix}_front.jpg', false);
      case _ViewMode.rear:
        return ('assets/images/vehicles/${prefix}_rear.jpg', false);
      case _ViewMode.side:
        return ('assets/images/vehicles/${prefix}_side.jpg', false);
      case _ViewMode.rotation360:
        final d = (degrees % 360 + 360) % 360;
        // 45° - 135°: Front View
        // 135° - 225°: Mirrored Side View
        // 225° - 315°: Rear View
        // 315° - 45°: Left Side Profile
        if (d >= 45 && d < 135) {
          return ('assets/images/vehicles/${prefix}_front.jpg', false);
        } else if (d >= 135 && d < 225) {
          return ('assets/images/vehicles/${prefix}_side.jpg', true);
        } else if (d >= 225 && d < 315) {
          return ('assets/images/vehicles/${prefix}_rear.jpg', false);
        } else {
          return ('assets/images/vehicles/${prefix}_side.jpg', false);
        }
    }
  }

  String _getAngleLabel(double d) {
    final norm = (d % 360 + 360) % 360;
    if (norm >= 337.5 || norm < 22.5) return 'Left Side Profile';
    if (norm >= 22.5 && norm < 67.5) return 'Front Three-Quarter';
    if (norm >= 67.5 && norm < 112.5) return 'Front View';
    if (norm >= 112.5 && norm < 157.5) return 'Front Three-Quarter Right';
    if (norm >= 157.5 && norm < 202.5) return 'Right Side Profile';
    if (norm >= 202.5 && norm < 247.5) return 'Rear Three-Quarter Right';
    if (norm >= 247.5 && norm < 292.5) return 'Rear View';
    return 'Rear Three-Quarter Left';
  }

  @override
  Widget build(BuildContext context) {
    final (imagePath, isMirrored) = _resolveImage(
      widget.detail,
      widget.variant,
      widget.color,
      _activeMode,
      _degrees,
    );

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_isAutoSpinning) _toggleAutoSpin();
        setState(() {
          _activeMode = _ViewMode.rotation360;
          _degrees = (_degrees - details.delta.dx * 0.75) % 360;
          if (_degrees < 0) _degrees += 360;
        });
      },
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Studio Lighting Gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.1,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF1F5F9),
                    Color(0xFFE2E8F0),
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Turntable Platform Shadow under the bike
            Positioned(
              bottom: 46,
              left: 36,
              right: 36,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.elliptical(220, 24)),
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Main Vehicle Photography Display (100% visible, BoxFit.contain)
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 68, 20, 56),
                child: Transform(
                  alignment: Alignment.center,
                  transform: isMirrored ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
                  child: RemoteImage(
                    url: imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Bottom 360 Scrubber & Controller (Active when 360° rotation selected)
            if (_activeMode == _ViewMode.rotation360)
              Positioned(
                bottom: 58,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            color: Colors.white,
                            onPressed: () => _step(-45),
                            icon: const Icon(Icons.rotate_left_rounded),
                            tooltip: 'Rotate left 45°',
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                activeTrackColor: const Color(0xFFDC2626),
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: _degrees,
                                min: 0,
                                max: 360,
                                onChanged: (val) => _setDegrees(val),
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            color: Colors.white,
                            onPressed: () => _step(45),
                            icon: const Icon(Icons.rotate_right_rounded),
                            tooltip: 'Rotate right 45°',
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            color: _isAutoSpinning ? const Color(0xFFDC2626) : Colors.white,
                            onPressed: _toggleAutoSpin,
                            icon: Icon(
                              _isAutoSpinning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            ),
                            tooltip: _isAutoSpinning ? 'Pause auto-spin' : 'Auto-spin 360°',
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 6, right: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getAngleLabel(_degrees),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_degrees.round()}° / 360°',
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Mode Selection Pills (Centered, Clean, Zero Overlap!)
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modePill('Front', _ViewMode.front, Icons.arrow_upward_rounded),
                      const SizedBox(width: 4),
                      _modePill('Rear', _ViewMode.rear, Icons.arrow_downward_rounded),
                      const SizedBox(width: 4),
                      _modePill('Side', _ViewMode.side, Icons.swap_horiz_rounded),
                      const SizedBox(width: 4),
                      _modePill('360°', _ViewMode.rotation360, Icons.sync_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modePill(String label, _ViewMode mode, IconData icon) {
    final active = _activeMode == mode;
    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDC2626) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ON-ROAD PRICING PANEL ---

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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pricing.branchName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (pricing.inStock)
                    const _Pill(text: 'In stock', tone: Color(0xFF166534))
                  else
                    const _Pill(text: 'Enquire for stock', tone: Color(0xFF92400E)),
                ],
              ),
              const SizedBox(height: 12),
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
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estimated on-road',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    formatCurrency(pricing.estimatedOnRoadPrice),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFDC2626), // Alagendra Red
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: index == entries.length - 1 ? const Radius.circular(12) : Radius.zero,
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
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
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              variant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatCurrency(variant.basePrice),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed, this.iconColor});

  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: iconColor ?? const Color(0xFF0F172A)),
      ),
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
