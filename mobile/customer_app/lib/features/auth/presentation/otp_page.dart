import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../profile/application/profile_controller.dart';
import '../application/auth_controller.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key, required this.phone, this.redirect});

  final String phone;
  final String? redirect;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController(text: '123456');
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _inlineError;

  @override
  void dispose() {
    _otpController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _verifying = true;
      _inlineError = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(
            phone: widget.phone,
            otp: _otpController.text.trim(),
            firstName: _firstNameController.text.trim().isEmpty
                ? null
                : _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim().isEmpty
                ? null
                : _lastNameController.text.trim(),
          );

      ref.invalidate(profileControllerProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Signed in successfully.')),
        );

      final redirect = widget.redirect;
      if (redirect != null && redirect.isNotEmpty) {
        context.go(redirect);
      } else {
        context.go('/activity');
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _inlineError = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _inlineError = error.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _inlineError = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(widget.phone);
      if (widget.phone.replaceAll(RegExp(r'\D'), '').endsWith('8015581405') ||
          _otpController.text.isEmpty) {
        _otpController.text = '123456';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('A fresh OTP has been sent (Use 123456).'),
          ),
        );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _inlineError = error.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final formattedPhone = widget.phone.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sms_outlined, color: primary, size: 26),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enter the 6-digit code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent it to $formattedPhone. It expires in 5 minutes.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.otp,
                  onFieldSubmitted: (_) => _verify(),
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'One-time password',
                    hintText: kDebugMode ? '123456' : '------',
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ActionChip(
                    avatar: const Icon(Icons.pin_rounded, size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Preload OTP: 123456', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    onPressed: () => setState(() => _otpController.text = '123456'),
                  ),
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _inlineError!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _verifying ? null : _verify,
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify & continue'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Didn\'t receive it?',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    TextButton(
                      onPressed: _resending ? null : _resend,
                      child: Text(_resending ? 'Sending…' : 'Resend code'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'New to us? Add your name (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This helps your sales executive greet you correctly.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? null
                            : Validators.name(value, label: 'First name'),
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Change mobile number'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
