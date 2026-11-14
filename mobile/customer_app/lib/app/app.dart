import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/branding/application/branding_controller.dart';
import '../features/branding/domain/entities/branding.dart';
import '../routing/app_router.dart';

class MotoSaasCustomerApp extends ConsumerWidget {
  const MotoSaasCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandingState = ref.watch(brandingControllerProvider);
    final branding = brandingState.value ?? Branding.fallback(AppConfig.dealerCode);
    final theme = AppTheme.build(branding);

    if (brandingState.isLoading) {
      return MaterialApp(
        title: '${branding.tradeName} · Customer',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const _LaunchScreen(),
      );
    }

    return MaterialApp.router(
      title: '${branding.tradeName} · Customer',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Alagendra Logo & Brand Tagline
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        text: 'Alagendra',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const Text(
                      'AUTOMOBILES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Trusted 2-Wheeler Partner',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
            ),

            const Spacer(flex: 2),

            // Sports Motorcycle Hero Illustration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 220,
                child: Image.asset(
                  'assets/images/vehicles/yamaha_r15_red.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.two_wheeler_rounded,
                    size: 96,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Subtle Loading Progress Indicator (No bottom sheet)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Explore · Buy · Service · Track · Offers',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
