import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../branding/application/branding_controller.dart';
import '../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.redirect});

  final String? redirect;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sending = true);
    final phone = _phoneController.text.trim();

    try {
      await ref.read(authControllerProvider.notifier).requestOtp(phone);
      final redirect = widget.redirect;
      if (!mounted) return;
      context.push(
        Uri(
          path: '/otp',
          queryParameters: {
            'phone': phone,
            if (redirect != null && redirect.isNotEmpty) 'redirect': redirect,
          },
        ).toString(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingControllerProvider).value;
    final session = ref.watch(authControllerProvider).value;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (branding != null)
                BrandMark(logoUrl: branding.logoUrl, tradeName: branding.tradeName, size: 52),
              const SizedBox(height: 24),
              Text(
                session == null ? 'Your garage, in one place.' : 'You are already signed in',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session == null
                    ? 'Sign in with your mobile number to track enquiries, test rides, ownership and service progress.'
                    : 'Continue as ${session.fullName}. You can use the app as this customer.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 28),
              if (session != null)
                FilledButton(
                  onPressed: _finish,
                  child: const Text('Continue'),
                )
              else ...[
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: Validators.phone,
                    onFieldSubmitted: (_) => _sendOtp(),
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      hintText: '98765 43210',
                      prefixIcon: Icon(Icons.phone_iphone_rounded),
                      prefixText: '+91 ',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _sending ? null : _sendOtp,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send OTP'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    "We'll send a 6-digit code to verify your number.",
                    style: TextStyle(fontSize: 12, color: primary.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What you unlock',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 14),
                      _Benefit(icon: Icons.receipt_long_rounded, text: 'Enquiries and test ride history'),
                      _Benefit(icon: Icons.garage_rounded, text: 'Your owned vehicles and documents'),
                      _Benefit(icon: Icons.build_circle_outlined, text: 'Service bookings and live progress'),
                      _Benefit(icon: Icons.person_rounded, text: 'Saved profile and delivery address'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _finish() {
    final redirect = widget.redirect;
    if (redirect != null && redirect.isNotEmpty) {
      context.go(redirect);
    } else {
      context.go('/activity');
    }
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
