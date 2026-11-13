import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.icon = Icons.two_wheeler_rounded,
    this.backgroundColor,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;
  final IconData icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final validUrl = url != null && (url!.startsWith('http://') || url!.startsWith('https://'));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: validUrl
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: fit,
                width: width,
                height: height,
                placeholder: (context, _) => _placeholder(context, loading: true),
                errorWidget: (context, _, __) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
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
