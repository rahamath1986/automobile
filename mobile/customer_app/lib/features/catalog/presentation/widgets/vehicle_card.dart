import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../domain/entities/vehicle.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.model, required this.onTap});

  final VehicleModelSummary model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: primary.withValues(alpha: 0.08),
          highlightColor: primary.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Vehicle Studio Stage
              Stack(
                children: [
                  Container(
                    height: 196,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.15),
                        radius: 1.15,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF8FAFC),
                          Color(0xFFEDF2F7),
                        ],
                        stops: [0.35, 0.75, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Studio Turntable Shadow under the wheels
                        Positioned(
                          bottom: 14,
                          left: 32,
                          right: 32,
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.elliptical(200, 18)),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.22),
                                  Colors.black.withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Authentic Manufacturer Motorcycle/Scooter Image (Fully Visible, No Crop)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            child: RemoteImage(
                              url: model.heroImageUrl,
                              fallbackAsset: RemoteImage.resolveVehicleAsset(model.code),
                              fit: BoxFit.contain,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top-Left Category & EV Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (model.isElectric)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'Electric EV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  model.categoryLabel.toLowerCase().contains('scooter')
                                      ? Icons.electric_scooter_rounded
                                      : Icons.two_wheeler_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  model.categoryLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Top-Right 360° Studio Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_rounded, size: 13, color: Color(0xFF0284C7)),
                          SizedBox(width: 3.5),
                          Text(
                            '360° View',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Card Content & Specifications
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand / Manufacturer
                    Text(
                      model.manufacturerName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Model Name
                    Text(
                      model.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Spec Highlight Pills Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (model.isElectric) ...[
                            _SpecChip(
                              icon: Icons.speed_rounded,
                              label: '100-145 km',
                            ),
                            const SizedBox(width: 6),
                            _SpecChip(
                              icon: Icons.battery_charging_full_rounded,
                              label: '${model.batteryCapacityKwh ?? 3.4} kWh',
                            ),
                            const SizedBox(width: 6),
                            const _SpecChip(
                              icon: Icons.electric_bolt_rounded,
                              label: '78 km/h',
                            ),
                          ] else ...[
                            if (model.displacementCc != null)
                              _SpecChip(
                                icon: Icons.tune_rounded,
                                label: '${model.displacementCc} cc',
                              ),
                            const SizedBox(width: 6),
                            const _SpecChip(
                              icon: Icons.local_gas_station_rounded,
                              label: '45 km/l',
                            ),
                            const SizedBox(width: 6),
                            const _SpecChip(
                              icon: Icons.speed_rounded,
                              label: '6-Speed VVA',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Price & Action Button Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Starting Ex-Showroom',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatCurrency(model.startingPrice),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primary,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Interactive Explore Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${model.variantCount} trims',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
