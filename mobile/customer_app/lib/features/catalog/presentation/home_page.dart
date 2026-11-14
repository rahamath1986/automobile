import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../branding/application/branding_controller.dart';
import '../../branding/domain/entities/branding.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/brand_mark.dart';
import '../application/catalog_controllers.dart';
import '../domain/entities/vehicle.dart';
import 'widgets/vehicle_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingControllerProvider).value ??
        Branding.fallback(AppConfig.dealerCode);
    final session = ref.watch(authControllerProvider).value;
    final filter = ref.watch(catalogFilterProvider);
    final modelsState = ref.watch(catalogModelsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(brandingControllerProvider);
            ref.invalidate(catalogModelsProvider);
            ref.invalidate(branchesProvider);
            await ref.read(catalogModelsProvider.future);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    branding: branding,
                    signedInName: session?.firstName,
                    onProfile: () {
                      if (session == null) {
                        context.push('/login');
                      } else {
                        context.go('/profile');
                      }
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: CatalogHeroBanner(
                    onBrowse: () => _focusCatalog(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _QuickActionGrid(
                    onNewVehicles: () => context.go('/vehicles'),
                    onOffers: () => context.go('/offers'),
                    onService: () => context.go('/garage'),
                    onTestRide: () => context.push('/test-ride'),
                    onFindStore: () => _showStoreDialog(context),
                    onSupport: () => _showContact(context, branding),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => ref.read(catalogFilterProvider.notifier).setQuery(value),
                    decoration: InputDecoration(
                      hintText: 'Search models, brands or codes',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: filter.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                ref.read(catalogFilterProvider.notifier).setQuery('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: CatalogCategory.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = CatalogCategory.values[index];
                        final isSelected = filter.category == category;
                        final primary = Theme.of(context).colorScheme.primary;
                        return ChoiceChip(
                          label: Text(
                            category.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primary,
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          side: BorderSide(
                            color: isSelected ? primary : const Color(0xFFDCE5F0),
                          ),
                          onSelected: (_) =>
                              ref.read(catalogFilterProvider.notifier).setCategory(category),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
                sliver: SliverToBoxAdapter(
                  child: modelsState.maybeWhen(
                    data: (models) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: SectionHeader(
                            title: filter.query.isEmpty ? 'Popular Models' : 'Search results',
                            subtitle: '${filter.apply(models).length} models available at ${branding.tradeName}',
                          ),
                        ),
                        if (filter.query.isEmpty)
                          TextButton(
                            onPressed: () => context.go('/vehicles'),
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),
                    orElse: () => const SectionHeader(
                      title: 'Explore the range',
                      subtitle: 'Curated two-wheelers for every ride',
                    ),
                  ),
                ),
              ),
              ..._buildCatalogSlivers(modelsState, filter),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCatalogSlivers(
    AsyncValue<List<VehicleModelSummary>> modelsState,
    CatalogFilter filter,
  ) {
    return [
      modelsState.when(
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, _) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(catalogModelsProvider),
            ),
          ),
        ),
        data: (allModels) {
          final models = filter.apply(allModels);
          if (models.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No models match that search',
                  message: 'Try a different keyword or category.',
                  action: OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(catalogFilterProvider.notifier).clear();
                    },
                    child: const Text('Reset filters'),
                  ),
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverList.separated(
              itemCount: models.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final model = models[index];
                return VehicleCard(
                  model: model,
                  onTap: () => context.push('/models/${model.id}'),
                );
              },
            ),
          );
        },
      ),
    ];
  }

  void _focusCatalog(BuildContext context) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + 260)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _showStoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Alagendra Dealership',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kotchadai Branch (Authorised Dealership)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Theni Main Road, Kotchadai, Madurai, Tamil Nadu - 625016',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('09:00 AM - 08:00 PM · Open Today', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('+91 80155 81405 / 0452-2458900', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Google Maps navigation to Kotchadai branch, Madurai...')),
              );
            },
            icon: const Icon(Icons.directions_rounded, size: 16),
            label: const Text('Get Directions'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  void _showContact(BuildContext context, Branding branding) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Talk to ${branding.tradeName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call_rounded, color: Color(0xFFDC2626)),
              title: Text(branding.supportPhone ?? '+91 80155 81405'),
              subtitle: const Text('Kotchadai branch sales & service helpline'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined, color: Color(0xFFDC2626)),
              title: const Text('Kotchadai Branch, Madurai'),
              subtitle: const Text('Theni Main Road, Kotchadai, Madurai - 625016'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.onNewVehicles,
    required this.onOffers,
    required this.onService,
    required this.onTestRide,
    required this.onFindStore,
    required this.onSupport,
  });

  final VoidCallback onNewVehicles;
  final VoidCallback onOffers;
  final VoidCallback onService;
  final VoidCallback onTestRide;
  final VoidCallback onFindStore;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionItem(Icons.two_wheeler_rounded, 'New Vehicles', onNewVehicles),
              _actionItem(Icons.local_offer_outlined, 'Offers', onOffers),
              _actionItem(Icons.build_circle_outlined, 'Service', onService),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionItem(Icons.speed_rounded, 'Test Ride', onTestRide),
              _actionItem(Icons.storefront_outlined, 'Find a Store', onFindStore),
              _actionItem(Icons.support_agent_rounded, 'Support', onSupport),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA), width: 1),
              ),
              child: Icon(icon, color: const Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.branding,
    required this.signedInName,
    required this.onProfile,
  });

  final Branding branding;
  final String? signedInName;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BrandMark(logoUrl: branding.logoUrl, tradeName: branding.tradeName, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branding.tradeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                signedInName == null ? 'Authorised two-wheeler dealership' : 'Welcome back, $signedInName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Contact dealership',
          onPressed: () => _showContact(context),
          icon: const Icon(Icons.support_agent_rounded),
        ),
        const SizedBox(width: 2),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onProfile,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              signedInName == null ? Icons.person_outline_rounded : Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _showContact(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Talk to ${branding.tradeName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call_rounded),
              title: Text(branding.supportPhone ?? AppConfig.supportFallbackPhone),
              subtitle: const Text('Sales & service helpline'),
            ),
            if (branding.supportEmail != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(branding.supportEmail!),
                subtitle: const Text('Email us'),
              ),
          ],
        ),
      ),
    );
  }
}

class CatalogHeroBanner extends StatelessWidget {
  const CatalogHeroBanner({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, const Color(0xFF0F172A), 0.6)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.two_wheeler_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFDE047)),
                      SizedBox(width: 4),
                      Text(
                        'Direct From Manufacturer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Explore New Motorcycles\n& Electric Scooters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authentic models, 360° studio views & instant test rides',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onBrowse,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Browse Showroom'),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_downward_rounded, size: 15),
                    ],
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
