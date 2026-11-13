import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../branding/application/branding_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/login_required.dart';
import '../../leads/application/leads_controllers.dart';
import '../../service/application/service_controllers.dart';
import '../application/profile_controller.dart';
import '../domain/entities/customer_profile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const LoginRequired(
          title: 'Sign in to your account',
          message: 'Manage your contact details, delivery address and dealership relationship.',
          icon: Icons.person_outline_rounded,
          redirect: '/profile',
        ),
      );
    }

    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (profileState.value != null)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileControllerProvider.notifier).refresh(),
        child: profileState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
                ),
              ),
            ],
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile unavailable.'));
            }
            return _ProfileBody(profile: profile);
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingControllerProvider).value;
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, Color.lerp(primary, Colors.black, 0.35)!],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.phone,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      if (profile.memberSince != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Member since ${formatMonthYear(profile.memberSince)}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatCard(label: 'Vehicles', value: '${profile.vehicleCount}', icon: Icons.two_wheeler_rounded),
            const SizedBox(width: 10),
            _StatCard(label: 'Enquiries', value: '${profile.enquiryCount}', icon: Icons.chat_bubble_outline_rounded),
            const SizedBox(width: 10),
            _StatCard(
              label: 'In service',
              value: '${profile.activeServiceBookingCount}',
              icon: Icons.build_circle_outlined,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Contact details'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.phone_iphone_rounded,
                label: 'Mobile',
                value: profile.phone,
                note: 'Used for sign in and service updates',
              ),
              const Divider(),
              _InfoTile(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: profile.email ?? 'Not added',
                note: profile.email == null ? 'Add an email for invoices and reminders' : null,
                muted: profile.email == null,
              ),
              const Divider(),
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: profile.formattedAddress ?? 'Not added',
                note: profile.hasAddress ? null : 'Add your delivery address to speed up paperwork',
                muted: !profile.hasAddress,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/edit'),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit profile'),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'My dealership'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.receipt_long_outlined,
                title: 'Enquiries & test rides',
                subtitle: 'See your conversations and booked rides',
                onTap: () => context.push('/activity'),
              ),
              const Divider(),
              _ActionTile(
                icon: Icons.garage_outlined,
                title: 'My vehicles & service',
                subtitle: 'Track ownership and live workshop progress',
                onTap: () => context.push('/garage'),
              ),
              const Divider(),
              _ActionTile(
                icon: Icons.support_agent_rounded,
                title: 'Contact dealership',
                subtitle: branding?.supportPhone ?? AppConfig.supportFallbackPhone,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branding?.tradeName ?? 'Dealership support',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        _InfoTile(
                          icon: Icons.phone_rounded,
                          label: 'Helpline',
                          value: branding?.supportPhone ?? AppConfig.supportFallbackPhone,
                        ),
                        if (branding?.supportEmail != null) ...[
                          const SizedBox(height: 8),
                          _InfoTile(
                            icon: Icons.mail_outline_rounded,
                            label: 'Email',
                            value: branding!.supportEmail!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context, ref),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB91C1C),
            side: const BorderSide(color: Color(0xFFFECACA)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '${branding?.tradeName ?? 'MotoSaaS'} · ${AppConfig.appName} Customer',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need your mobile number and an OTP to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).logout();
    ref.invalidate(profileControllerProvider);
    ref.invalidate(myEnquiriesProvider);
    ref.invalidate(myTestRidesProvider);
    ref.invalidate(myVehiclesProvider);
    ref.invalidate(myServiceBookingsProvider);

    if (context.mounted) {
      context.go('/home');
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 21, color: const Color(0xFF64748B)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: muted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                note!,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
