import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/showroom_notifier.dart';
import '../models/showroom_asset.dart';

class ShowroomPage extends ConsumerStatefulWidget {
  final String variantId;
  final String? colorId;

  const ShowroomPage({
    required this.variantId,
    this.colorId,
    super.key,
  });

  @override
  ConsumerState<ShowroomPage> createState() => _ShowroomPageState();
}

class _ShowroomPageState extends ConsumerState<ShowroomPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(showroomNotifierProvider.notifier)
        .loadAsset(variantId: widget.variantId, colorId: widget.colorId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showroomNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: state.status == ShowroomLoadStatus.success
            ? Text(state.asset!.variantName)
            : const Text('Showroom'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ShowroomState state) {
    switch (state.status) {
      case ShowroomLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case ShowroomLoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? 'Failed to load showroom',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(showroomNotifierProvider.notifier)
                    .loadAsset(variantId: widget.variantId),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case ShowroomLoadStatus.success:
        final asset = state.asset!;
        return _ShowroomContent(asset: asset);

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Showroom content ─────────────────────────────────────────────────────────
class _ShowroomContent extends StatelessWidget {
  final ShowroomAsset asset;
  const _ShowroomContent({required this.asset});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 3-D viewer area (Tier label + placeholder; full viewer plugged in later)
        _ViewerPlaceholder(tier: asset.activeTier, glbUrl: asset.glbFileUrl),
        const SizedBox(height: 20),

        // Vehicle details
        Text(asset.modelName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(asset.variantCode,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Text('₹ ${asset.basePrice.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.green)),

        const Divider(height: 32),

        // Color chip
        if (asset.colorName != null) ...[
          const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _hexToColor(asset.hexCode ?? '#888888'),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
              ),
              const SizedBox(width: 8),
              Text(asset.colorName!),
            ],
          ),
          const Divider(height: 32),
        ],

        // Active tier badge
        _TierBadge(tier: asset.activeTier),
        const SizedBox(height: 20),

        // Enquire / Test Ride CTA buttons (wired in later phases)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: navigate to enquiry form (Phase 9)
                },
                child: const Text('Enquire Now'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: navigate to test-ride booking (Phase 9)
                },
                child: const Text('Book Test Ride'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

// ─── Viewer placeholder widget ─────────────────────────────────────────────────
class _ViewerPlaceholder extends StatelessWidget {
  final String tier;
  final String? glbUrl;

  const _ViewerPlaceholder({required this.tier, this.glbUrl});

  @override
  Widget build(BuildContext context) {
    final label = switch (tier) {
      'Tier1_Interactive3D' => '3D Interactive Viewer',
      'Tier2_Turntable360' => '360° Turntable',
      _ => 'Photo Gallery',
    };
    final icon = switch (tier) {
      'Tier1_Interactive3D' => Icons.threed_rotation,
      'Tier2_Turntable360' => Icons.rotate_90_degrees_cw,
      _ => Icons.photo_library,
    };

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (glbUrl != null) ...[
              const SizedBox(height: 6),
              Text(
                'GLB ready',
                style: TextStyle(color: Colors.greenAccent.shade200, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tier badge ───────────────────────────────────────────────────────────────
class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = switch (tier) {
      'Tier1_Interactive3D' => ('3D Mode', Colors.indigo),
      'Tier2_Turntable360' => ('360° Mode', Colors.teal),
      _ => ('Gallery Mode', Colors.blueGrey),
    };

    return Chip(
      avatar: const Icon(Icons.verified, size: 16),
      label: Text(label.$1),
      backgroundColor: label.$2.shade100,
    );
  }
}

