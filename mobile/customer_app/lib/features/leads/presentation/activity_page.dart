import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/login_required.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/leads_controllers.dart';
import '../domain/entities/lead.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My activity')),
        body: const LoginRequired(
          title: 'Sign in to see your activity',
          message: 'Track enquiries and test rides you have started with the dealership.',
          icon: Icons.receipt_long_outlined,
          redirect: '/activity',
        ),
      );
    }

    final enquiries = ref.watch(myEnquiriesProvider);
    final testRides = ref.watch(myTestRidesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My activity'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(myEnquiriesProvider);
                ref.invalidate(myTestRidesProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Enquiries'),
              Tab(text: 'Test rides'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EnquiryList(state: enquiries),
            _TestRideList(state: testRides),
          ],
        ),
      ),
    );
  }
}

class _EnquiryList extends ConsumerWidget {
  const _EnquiryList({required this.state});

  final AsyncValue<List<Enquiry>> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myEnquiriesProvider);
        await ref.read(myEnquiriesProvider.future);
      },
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(myEnquiriesProvider),
              ),
            ),
          ],
        ),
        data: (enquiries) {
          if (enquiries.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No enquiries yet',
                  message: 'Ask about a vehicle and your conversation will appear here.',
                  action: FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Explore models'),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: enquiries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _EnquiryCard(enquiry: enquiries[index]),
          );
        },
      ),
    );
  }
}

class _TestRideList extends ConsumerWidget {
  const _TestRideList({required this.state});

  final AsyncValue<List<TestRide>> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myTestRidesProvider);
        await ref.read(myTestRidesProvider.future);
      },
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(myTestRidesProvider),
              ),
            ),
          ],
        ),
        data: (testRides) {
          if (testRides.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.speed_rounded,
                  title: 'No test rides booked',
                  message: 'Feel the ride before you decide. Book a test ride from any model page.',
                  action: FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Find a model'),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: testRides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _TestRideCard(testRide: testRides[index]),
          );
        },
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    enquiry.modelName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                StatusChip(status: enquiry.status, compact: true),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              enquiry.variantName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            _MetaRow(icon: Icons.storefront_rounded, text: enquiry.branchName),
            if (enquiry.colorName != null) ...[
              const SizedBox(height: 6),
              _MetaRow(icon: Icons.palette_outlined, text: enquiry.colorName!),
            ],
            const SizedBox(height: 6),
            _MetaRow(icon: Icons.schedule_rounded, text: 'Sent ${formatDateTime(enquiry.createdAt)}'),
            if (enquiry.assignedSalesExecutiveName != null) ...[
              const SizedBox(height: 6),
              _MetaRow(
                icon: Icons.person_pin_circle_outlined,
                text: 'Handled by ${enquiry.assignedSalesExecutiveName}',
              ),
            ],
            if (enquiry.notes != null && enquiry.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  enquiry.notes!,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestRideCard extends StatelessWidget {
  const _TestRideCard({required this.testRide});

  final TestRide testRide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    testRide.modelName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                StatusChip(status: testRide.status, compact: true),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              testRide.variantName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatDateTime(testRide.scheduledAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _MetaRow(icon: Icons.storefront_rounded, text: testRide.branchName),
            if (testRide.feedbackNotes != null && testRide.feedbackNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _MetaRow(icon: Icons.star_outline_rounded, text: testRide.feedbackNotes!),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}
