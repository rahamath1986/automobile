import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json_helpers.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/login_required.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/service_controllers.dart';
import '../domain/entities/service_entities.dart';

class ServiceTrackingPage extends ConsumerStatefulWidget {
  const ServiceTrackingPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<ServiceTrackingPage> createState() => _ServiceTrackingPageState();
}

class _ServiceTrackingPageState extends ConsumerState<ServiceTrackingPage> {
  bool _approving = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service progress')),
        body: const LoginRequired(
          title: 'Sign in to track service',
          message: 'Live repair progress is available to the vehicle owner.',
          icon: Icons.build_circle_outlined,
          redirect: '/garage',
        ),
      );
    }

    final trackingState = ref.watch(serviceTrackingProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service progress'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(serviceTrackingProvider(widget.bookingId)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: trackingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(serviceTrackingProvider(widget.bookingId)),
        ),
        data: (tracking) => _TrackingBody(
          tracking: tracking,
          approving: _approving,
          onRefresh: _refresh,
          onApprove: tracking.jobCard == null
              ? null
              : () => _approveEstimate(tracking.jobCard!.id, tracking.jobCard!.estimatedCost),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(serviceTrackingProvider(widget.bookingId));
    await ref.read(serviceTrackingProvider(widget.bookingId).future);
  }

  Future<void> _approveEstimate(String jobCardId, double estimatedCost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve estimate?'),
        content: Text(
          'You are approving an estimated cost of ${formatCurrency(estimatedCost)}. The final invoice may vary if additional work is found.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _approving = true);
    try {
      await ref.read(serviceRepositoryProvider).approveEstimate(jobCardId);
      ref.invalidate(serviceTrackingProvider(widget.bookingId));
      ref.invalidate(myServiceBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Estimate approved. Work will continue.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({
    required this.tracking,
    required this.approving,
    required this.onRefresh,
    required this.onApprove,
  });

  final ServiceTracking tracking;
  final bool approving;
  final Future<void> Function() onRefresh;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final booking = tracking.booking;
    final jobCard = tracking.jobCard;
    final primary = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${booking.modelName} ${booking.variantName}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusChip(status: jobCard?.status ?? booking.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.registrationNumber} · ${humanizeEnum(booking.serviceType)}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (tracking.progressPercent.clamp(0, 100)) / 100,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFE8EDF5),
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tracking.currentStage.isEmpty ? 'Progress will update soon' : tracking.currentStage,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: primary),
                        ),
                      ),
                      Text(
                        '${tracking.progressPercent}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.branchName,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        '${formatShortDate(booking.scheduledDate)} · ${booking.timeSlot}',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (tracking.awaitingCustomerApproval && jobCard != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions_rounded, color: Color(0xFF92400E)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Your approval is needed',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                      ),
                      Text(
                        formatCurrency(jobCard.estimatedCost),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The workshop has prepared an estimate. Review the line items below and approve to continue the repair.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E), height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: approving ? null : onApprove,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB45309)),
                    child: approving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Approve estimate'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const SectionHeader(title: 'Workshop timeline'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                children: [
                  if (tracking.timeline.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Your vehicle has been checked in. The timeline will appear as work progresses.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                      ),
                    )
                  else
                    for (var index = 0; index < tracking.timeline.length; index++)
                      _TimelineStep(
                        step: tracking.timeline[index],
                        isLast: index == tracking.timeline.length - 1,
                      ),
                ],
              ),
            ),
          ),
          if (jobCard != null) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Job card'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            jobCard.jobCardNumber,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (jobCard.customerApproved)
                          const Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 16, color: Color(0xFF166534)),
                              SizedBox(width: 4),
                              Text(
                                'Approved',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (jobCard.technicianName != null)
                          _Meta(icon: Icons.engineering_outlined, text: jobCard.technicianName!),
                        _Meta(icon: Icons.speed_rounded, text: '${jobCard.odometerReading} km'),
                        _Meta(icon: Icons.local_gas_station_outlined, text: '${jobCard.fuelLevelPercent}% fuel'),
                        _Meta(
                          icon: Icons.currency_rupee_rounded,
                          text: 'Estimate ${formatCurrency(jobCard.estimatedCost)}',
                        ),
                      ],
                    ),
                    if (jobCard.items.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(),
                      ),
                      const Text(
                        'Line items',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...jobCard.items.map((item) => _LineItem(item: item)),
                    ] else ...[
                      const SizedBox(height: 14),
                      const Text(
                        'The technician is preparing the estimate items.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EDF5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your vehicle is yet to be checked in at the workshop. Check back after your appointment time.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});

  final ServiceTimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    const blue = Color(0xFF2563EB);
    const grey = Color(0xFFCBD5E1);

    final nodeColor = step.completed ? green : (step.current ? blue : grey);
    final lineColor = step.completed ? green : const Color(0xFFE2E8F0);

    String subtext;
    if (step.completed) {
      subtext = 'Completed on schedule';
    } else if (step.current) {
      subtext = 'Active in workshop bay';
    } else {
      subtext = 'Pending';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: step.completed ? green : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: step.current ? 3 : 2),
                  boxShadow: step.current
                      ? [
                          BoxShadow(
                            color: blue.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: step.completed
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : step.current
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
                            ),
                          )
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 22, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: step.current ? FontWeight.w800 : FontWeight.w600,
                      color: step.current
                          ? const Color(0xFF0F172A)
                          : step.completed
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: step.current ? FontWeight.w600 : FontWeight.w400,
                      color: step.current
                          ? blue
                          : step.completed
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.item});

  final ServiceProgressItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${humanizeEnum(item.itemType)} · ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} × ${formatCurrency(item.unitPrice)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(item.totalPrice),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              if (!item.isApproved)
                const Text(
                  'Awaiting approval',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      ],
    );
  }
}
