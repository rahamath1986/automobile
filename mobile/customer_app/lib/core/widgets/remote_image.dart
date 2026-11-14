import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.icon = Icons.two_wheeler_rounded,
    this.backgroundColor,
  });

  final String? url;
  final String? fallbackAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;
  final IconData icon;
  final Color? backgroundColor;

  /// Helper to resolve a bundled motorcycle image based on vehicle model/variant code or color name.
  static String? resolveVehicleAsset(String? hint) {
    if (hint == null || hint.isEmpty) return null;
    final lower = hint.toLowerCase();

    // Check specific color cues first for instant visual feedback
    if (lower.contains('radeon')) {
      if (lower.contains('red')) return 'assets/images/vehicles/bike_red.jpg';
      return 'assets/images/vehicles/bike_black.jpg';
    }

    if (lower.contains('dark') || lower.contains('knight') || lower.contains('black')) {
      return 'assets/images/vehicles/yamaha_r15_dark_knight.jpg';
    }

    if (lower.contains('red') || lower.contains('vermilion') || lower.contains('crimson')) {
      return 'assets/images/vehicles/yamaha_r15_red.jpg';
    }

    if (lower.contains('grey') || lower.contains('gray') || lower.contains('metallic') || lower.contains('r15m') || lower.contains('silver') || lower.contains('white')) {
      return 'assets/images/vehicles/yamaha_r15m.jpg';
    }

    if (lower.contains('aerox') || lower.contains('scooter')) {
      return 'assets/images/vehicles/yamaha_aerox_155.jpg';
    }

    if (lower.contains('iqube') || lower.contains('electric') || lower.contains('ev')) {
      return 'assets/images/vehicles/tvs_iqube.jpg';
    }

    if (lower.contains('blue') || lower.contains('r15') || lower.contains('yzf') || lower.contains('motorcycle')) {
      return 'assets/images/vehicles/yamaha_r15_v4.jpg';
    }

    return 'assets/images/vehicles/yamaha_r15_v4.jpg';
  }

  @override
  Widget build(BuildContext context) {
    // Filter out old wikimedia delivery snapshots in favor of authentic bundled manufacturer assets
    final isWikimediaDelivery = url != null && (url!.contains('upload.wikimedia.org') || url!.contains('wikipedia'));
    final cleanUrl = isWikimediaDelivery ? null : url;
    final effectiveFallback = fallbackAsset ?? resolveVehicleAsset(url);
    final isLocalAsset = cleanUrl != null && cleanUrl.startsWith('assets/');
    final isNetworkUrl = cleanUrl != null && (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://'));

    Widget content;
    if (isLocalAsset) {
      content = Image.asset(
        cleanUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, _, __) => _buildFallback(context, effectiveFallback),
      );
    } else if (isNetworkUrl) {
      content = CachedNetworkImage(
        imageUrl: cleanUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, _) => _placeholder(context, loading: true),
        errorWidget: (context, _, __) => _buildFallback(context, effectiveFallback),
      );
    } else {
      content = _buildFallback(context, effectiveFallback);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: content,
      ),
    );
  }

  Widget _buildFallback(BuildContext context, String? asset) {
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, _, __) => _placeholder(context),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context, {bool loading = false}) {
    final color = backgroundColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: color.withValues(alpha: 0.7)),
            )
          : Icon(icon, size: 44, color: color.withValues(alpha: 0.55)),
      ),
    );
  }
}
