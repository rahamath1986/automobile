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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 4),

              // Prominent Brand Logo & Identity (No vehicle image)
              _BrandLogoCenter(),

              Spacer(flex: 4),

              // Subtle Loading Progress Indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFDC2626),
                ),
              ),
              SizedBox(height: 14),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Alagendra Automobiles · Kotchadai, Madurai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogoCenter extends StatelessWidget {
  const _BrandLogoCenter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Prominent Logo Icon Emblem
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Brand Name Text
        const Text(
          'Alagendra',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'AUTOMOBILES',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFFDC2626),
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(height: 12),

        // Tagline
        const Text(
          'Your Trusted 2-Wheeler Partner',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
