import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // 1. User Header Card (Screen 12)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    profile.initials.isNotEmpty ? profile.initials : 'RK',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName.isNotEmpty ? profile.displayName : 'Ravi Kumar',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.phone.isNotEmpty ? profile.phone : '+91 98765 43210',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 20),
                onPressed: () => context.push('/profile/edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Menu Rows List (Screen 12)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _menuRow(
                icon: Icons.two_wheeler_rounded,
                title: 'My Vehicles',
                onTap: () => context.go('/garage'),
              ),
              const Divider(height: 1, indent: 52),
              _menuRow(
                icon: Icons.build_rounded,
                title: 'Service History',
                onTap: () => context.go('/garage'),
              ),
              const Divider(height: 1, indent: 52),
              _menuRow(
                icon: Icons.calendar_today_rounded,
                title: 'Test Ride Bookings',
                onTap: () => context.push('/activity'),
              ),
              const Divider(height: 1, indent: 52),
              _menuRow(
                icon: Icons.receipt_long_rounded,
                title: 'Quotes & Enquiries',
                onTap: () => context.push('/activity'),
              ),
              const Divider(height: 1, indent: 52),
              _menuRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All service updates and offers are up to date.')),
                  );
                },
              ),
              const Divider(height: 1, indent: 52),
              _menuRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => context.push('/profile/edit'),
              ),
              const Divider(height: 1, indent: 52),
              _menuRow(
                icon: Icons.badge_outlined,
                title: 'Dealer Workspace (Staff)',
                onTap: () => context.push('/staff'),
              ),
              const Divider(height: 1, indent: 52),
              _menuRow(
                icon: Icons.power_settings_new_rounded,
                title: 'Logout',
                iconColor: const Color(0xFFDC2626),
                titleColor: const Color(0xFFDC2626),
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Dealership Branch Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alagendra Automobiles · Kotchadai Branch',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 2),
              Text(
                'Theni Main Road, Kotchadai, Madurai - 625016\nHelpline: +91 80155 81405',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF0F172A),
    Color titleColor = const Color(0xFF0F172A),
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      onTap: onTap,
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
