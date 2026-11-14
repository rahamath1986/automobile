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
                    data: (models) => SectionHeader(
                      title: filter.query.isEmpty ? 'Explore the range' : 'Search results',
                      subtitle: '${filter.apply(models).length} models available at ${branding.tradeName}',
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
