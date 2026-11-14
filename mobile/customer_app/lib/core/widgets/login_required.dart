import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_states.dart';

/// Consistent sign-in gate used by Activity, Garage and Profile tabs.
class LoginRequired extends StatelessWidget {
  const LoginRequired({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
    this.redirect,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? redirect;

  @override
  Widget build(BuildContext context) {
    final target = Uri(
      path: '/login',
      queryParameters: {
        if (redirect != null && redirect!.isNotEmpty) 'redirect': redirect!,
      },
    ).toString();

    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () => context.push(target),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Sign in with mobile'),
          ),
          const SizedBox(height: 10),
          ActionChip(
            avatar: const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFFDC2626)),
            label: const Text(
              'Preload User: 8015581405 (Pass: 123456)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFFEF2F2),
            side: const BorderSide(color: Color(0xFFFECACA)),
            onPressed: () => context.push(target),
          ),
        ],
      ),
    );
  }
}
