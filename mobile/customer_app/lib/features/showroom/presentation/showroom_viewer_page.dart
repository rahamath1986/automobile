import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/remote_image.dart';
import '../application/showroom_controllers.dart';
import '../domain/entities/showroom_asset.dart';
import 'widgets/showroom_web_view.dart';

class ShowroomViewerPage extends ConsumerStatefulWidget {
  const ShowroomViewerPage({
    super.key,
    required this.variantId,
    this.initialColorId,
  });

  final String variantId;
  final String? initialColorId;

  @override
  ConsumerState<ShowroomViewerPage> createState() => _ShowroomViewerPageState();
}

class _ShowroomViewerPageState extends ConsumerState<ShowroomViewerPage> {
  final _webViewKey = GlobalKey<ShowroomWebViewState>();
  String? _colorId;
  String? _selectedColorHex;
  String _liveTier = 'preparing';
  bool _galleryMode = false;
  bool _webViewFailed = false;

  @override
  void initState() {
    super.initState();
    _colorId = widget.initialColorId;
  }

  @override
  Widget build(BuildContext context) {
    final assetState = ref.watch(
      showroomAssetProvider((variantId: widget.variantId, colorId: _colorId)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1020),
        foregroundColor: Colors.white,
        title: Text(
          assetState.value == null
              ? '3D Showroom'
              : '${assetState.value!.modelName} · ${assetState.value!.variantName}',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (assetState.value != null)
            IconButton(
              tooltip: 'Reset camera',
              onPressed: () => _webViewKey.currentState?.reset(),
              icon: const Icon(Icons.center_focus_strong_rounded),
            ),
        ],
      ),
      body: assetState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (error, _) => SafeArea(
          child: ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(
              showroomAssetProvider((variantId: widget.variantId, colorId: _colorId)),
            ),
          ),
        ),
        data: (asset) {
          _selectedColorHex ??= asset.hexCode;
          return Column(
            children: [
              Expanded(child: _buildViewer(asset)),
              _ControlPanel(
                asset: asset,
                selectedColorId: _colorId,
                onColorSelected: (color) {
                  setState(() {
                    _colorId = color.id;
                    _selectedColorHex = color.hexCode;
                    _galleryMode = false;
                  });
                  _webViewKey.currentState?.setColor(color.hexCode);
                },
                onCameraSelected: (view) {
                  setState(() {
                    _galleryMode = false;
                    _webViewFailed = false;
                  });
                  _webViewKey.currentState?.setView(view);
                },
                onHotspotSelected: (hotspot) => _showHotspot(context, hotspot),
                onToggleGallery: () => setState(() => _galleryMode = !_galleryMode),
                showGalleryToggle: asset.hasGallery || asset.hasTurntable,
                galleryMode: _galleryMode,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewer(ShowroomAsset asset) {
    final canRender3D = !_webViewFailed &&
        !_galleryMode &&
        asset.activeTier == ViewerTier.interactive3D;

    if (canRender3D) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ShowroomWebView(
            key: _webViewKey,
            asset: asset,
            onEvent: (type, payload) {
              if (!mounted) return;
              if (type == 'tier') {
                setState(() {
                  _liveTier = payload['tier']?.toString() ?? 'procedural';
                });
              } else if (type == 'hotspot') {
                final id = payload['id']?.toString();
                final hotspot = asset.hotspots.where((item) => item.id == id).firstOrNull;
                if (hotspot != null) _showHotspot(context, hotspot);
              } else if (type == 'webview-error' || type == 'error') {
                setState(() => _webViewFailed = true);
              }
            },
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _TierBadge(
              label: switch (_liveTier) {
                'glb' => 'Interactive 3D',
                'procedural' => '3D preview',
                _ => 'Loading 3D…',
              },
              onDark: true,
            ),
          ),
          if (asset.hasGallery || asset.hasTurntable)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => setState(() => _galleryMode = true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Gallery', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TierBadge(label: asset.activeTier.label, onDark: true),
                const SizedBox(width: 8),
                if (asset.modelFileSizeBytes > 0)
                  _TierBadge(
                    label: '${(asset.modelFileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                    onDark: true,
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return _GalleryViewer(
      asset: asset,
      onShow3D: asset.activeTier == ViewerTier.interactive3D || _webViewFailed
          ? () => setState(() {
                _galleryMode = false;
                _webViewFailed = false;
              })
          : null,
    );
  }

  void _showHotspot(BuildContext context, ShowroomHotspot hotspot) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hotspot.category.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hotspot.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (hotspot.specMetric != null && hotspot.specMetric!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hotspot.specMetric!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              hotspot.description,
              style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.asset, this.onShow3D});

  final ShowroomAsset asset;
  final VoidCallback? onShow3D;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final frames = widget.asset.hasTurntable ? widget.asset.turntableFrames : widget.asset.staticGallery;

    if (frames.isEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          RemoteImage(
            url: widget.asset.availableColors
                .where((color) => color.id == widget.asset.colorId)
                .map((color) => color.imageUrl)
                .firstOrNull,
            fallbackAsset: RemoteImage.resolveVehicleAsset(widget.asset.variantCode),
            fit: BoxFit.contain,
          ),
          const Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Text(
              'Live 3D preview is unavailable right now. An on-road photo will appear here once the dealership uploads it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: frames.length,
          onPageChanged: (value) => setState(() => _index = value),
          itemBuilder: (context, index) => Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: RemoteImage(
              url: frames[index],
              fallbackAsset: RemoteImage.resolveVehicleAsset(widget.asset.variantCode),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: _TierBadge(
            label: widget.asset.hasTurntable ? '360° turntable' : 'Photo gallery',
            onDark: true,
          ),
        ),
        if (widget.onShow3D != null)
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: widget.onShow3D,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text('3D view', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              frames.length > 12 ? 12 : frames.length,
              (dot) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: dot == (_index % 12) ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dot == (_index % 12) ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.asset,
    required this.selectedColorId,
    required this.onColorSelected,
    required this.onCameraSelected,
    required this.onHotspotSelected,
    required this.onToggleGallery,
    required this.showGalleryToggle,
    required this.galleryMode,
  });

  final ShowroomAsset asset;
  final String? selectedColorId;
  final ValueChanged<dynamic> onColorSelected;
  final ValueChanged<String> onCameraSelected;
  final ValueChanged<ShowroomHotspot> onHotspotSelected;
  final VoidCallback onToggleGallery;
  final bool showGalleryToggle;
  final bool galleryMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (asset.availableColors.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Colour',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.availableColors
                          .firstWhere(
                            (color) => color.id == selectedColorId,
                            orElse: () => asset.availableColors.first,
                          )
                          .colorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                  if (showGalleryToggle)
                    TextButton.icon(
                      onPressed: onToggleGallery,
                      icon: Icon(
                        galleryMode ? Icons.view_in_ar_rounded : Icons.photo_library_outlined,
                        size: 16,
                      ),
                      label: Text(galleryMode ? '3D view' : 'Gallery'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: asset.availableColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final color = asset.availableColors[index];
                    final selected = color.id == (selectedColorId ?? asset.colorId);
                    return Tooltip(
                      message: color.colorName,
                      child: GestureDetector(
                        onTap: () => onColorSelected(color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColor(color.hexCode),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: _parseColor(color.hexCode).computeLuminance() > 0.55
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (asset.hotspots.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Explore the details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: asset.hotspots.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final hotspot = asset.hotspots[index];
                    return ActionChip(
                      avatar: const Icon(Icons.adjust_rounded, size: 15, color: Color(0xFF0F172A)),
                      label: Text(
                        hotspot.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFDCE5F0)),
                      onPressed: () => onHotspotSelected(hotspot),
                    );
                  },
                ),
              ),
            ],
            if (!galleryMode && asset.activeTier == ViewerTier.interactive3D) ...[
              const SizedBox(height: 14),
              const Text(
                'Camera views',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _CameraChip(label: 'Hero', view: 'hero', icon: Icons.auto_awesome_rounded),
                  _CameraChip(label: 'Profile', view: 'profile', icon: Icons.crop_landscape_rounded),
                  _CameraChip(label: 'Cockpit', view: 'cockpit', icon: Icons.speed_rounded),
                  _CameraChip(label: 'Rear', view: 'rear', icon: Icons.keyboard_double_arrow_left_rounded),
                  _CameraChip(label: 'Top', view: 'top', icon: Icons.vertical_align_top_rounded),
                ]
                    .map((chip) => _CameraChipButton(chip: chip, onSelected: onCameraSelected))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CameraChip {
  const _CameraChip({required this.label, required this.view, required this.icon});

  final String label;
  final String view;
  final IconData icon;
}

class _CameraChipButton extends StatelessWidget {
  const _CameraChipButton({required this.chip, required this.onSelected});

  final _CameraChip chip;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onSelected(chip.view),
      icon: Icon(chip.icon, size: 16),
      label: Text(chip.label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label, this.onDark = false});

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onDark ? Colors.black.withValues(alpha: 0.55) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onDark ? Colors.white : const Color(0xFF475569),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.tryParse(value, radix: 16) ?? 0xFF002C6C);
}
