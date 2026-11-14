import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'remote_image.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.logoUrl, required this.tradeName, this.size = 40});

  final String? logoUrl;
  final String tradeName;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: RemoteImage(
          url: logoUrl,
          width: size,
          height: size,
          borderRadius: 12,
          icon: Icons.storefront_rounded,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.fallbackPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tradeName.trim().isEmpty ? 'M' : tradeName.trim()[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}
