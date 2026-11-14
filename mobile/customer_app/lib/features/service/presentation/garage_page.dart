import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json_helpers.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/login_required.dart';
import '../../../core/widgets/remote_image.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/service_controllers.dart';
import '../domain/entities/service_entities.dart';

class GaragePage extends ConsumerWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My garage')),
        body: const LoginRequired(
          title: 'Your garage starts here',
          message: 'Sign in to see your owned vehicles, service appointments and live repair progress.',
          icon: Icons.garage_outlined,
          redirect: '/garage',
        ),
      );
    }

    final vehicles = ref.watch(myVehiclesProvider);
    final bookings = ref.watch(myServiceBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My garage'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(myVehiclesProvider);
              ref.invalidate(myServiceBookingsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myVehiclesProvider);
          ref.invalidate(myServiceBookingsProvider);
          await Future.wait([
            ref.read(myVehiclesProvider.future),
            ref.read(myServiceBookingsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            vehicles.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(myVehiclesProvider),
              ),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'My vehicles',
                    subtitle: items.isEmpty
                        ? 'Vehicles appear here after delivery'
                        : '${items.length} owned vehicle${items.length == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _NoVehicles()
                  else
                    ...items.map((vehicle) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VehicleCard(vehicle: vehicle),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'Service appointments',
                    subtitle: 'Live status from the workshop',
                  ),
                ),
                if (vehicles.value?.isNotEmpty ?? false)
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/service/book'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Book'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            bookings.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(myServiceBookingsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.build_circle_outlined,
                    title: 'No service appointments',
                    message: 'When you book a service, you can follow every stage here.',
                  );
                }
                return Column(
                  children: items
                      .map((booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BookingCard(booking: booking),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoVehicles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.two_wheeler_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No vehicle linked yet',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Once your vehicle is delivered, it will be linked to your mobile number automatically. You can then book service and follow the repair live.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Explore models'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final CustomerVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: RemoteImage(
              url: vehicle.heroImageUrl,
              fallbackAsset: RemoteImage.resolveVehicleAsset(vehicle.modelName),
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${vehicle.modelName} ${vehicle.variantName}',
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicle.registrationNumber,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Detail(icon: Icons.fingerprint_rounded, text: vehicle.chassisNumberMasked),
                    if (vehicle.engineNumberMasked != null)
                      _Detail(icon: Icons.settings_rounded, text: vehicle.engineNumberMasked!),
                    if (vehicle.deliveryDate != null)
                      _Detail(
                        icon: Icons.event_available_rounded,
                        text: 'Delivered ${formatShortDate(vehicle.deliveryDate)}',
                      ),
                  ],
                ),
                if (vehicle.lastServiceStatus != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Last service ${formatShortDate(vehicle.lastServiceDate)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      StatusChip(status: vehicle.lastServiceStatus!, compact: true),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/service/book?vehicleId=${vehicle.id}'),
                    icon: const Icon(Icons.build_circle_outlined, size: 18),
                    label: const Text('Book a service'),
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final ServiceBooking booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/service/track/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${booking.modelName} · ${booking.registrationNumber}',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusChip(status: booking.status, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${humanizeEnum(booking.serviceType)} · ${booking.branchName}',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.event_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${formatShortDate(booking.scheduledDate)} · ${booking.timeSlot}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                    ),
                  ),
                  if (booking.jobCardStatus != null) ...[
                    StatusChip(status: booking.jobCardStatus!, compact: true),
                    const SizedBox(width: 6),
                  ],
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      ],
    );
  }
}
