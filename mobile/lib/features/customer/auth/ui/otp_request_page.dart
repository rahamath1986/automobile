import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_state.dart';

class OtpRequestPage extends ConsumerStatefulWidget {
  const OtpRequestPage({super.key});

  @override
  ConsumerState<OtpRequestPage> createState() => _OtpRequestPageState();
}

class _OtpRequestPageState extends ConsumerState<OtpRequestPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to state changes.
    ref.listen<AuthState>(authNotifierProvider, (_, state) {
      if (state.stage == AuthStage.awaitingOtpEntry) {
        // Navigate to OTP verification screen.
        context.go('/verify');
      } else if (state.stage == AuthStage.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
        );
      }
    });

    final isLoading = ref.watch(authNotifierProvider).stage == AuthStage.requestingOtp;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Welcome to\nMotoSaaS',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Enter your mobile number to continue.'),
              const SizedBox(height: 40),

              // Phone input
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Send OTP button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final phone = '+91${_phoneController.text.trim()}';
                          ref.read(authNotifierProvider.notifier).requestOtp(phone);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 24),

              // Staff login link
              Center(
                child: TextButton(
                  onPressed: () => context.go('/staff/login'),
                  child: const Text('I am a dealer / staff'),
                ),
              ),

              // Guest explore link
              Center(
                child: TextButton(
                  onPressed: () => context.go('/catalog'),
                  child: const Text('Continue as Guest →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

