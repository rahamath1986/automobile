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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary,
              Color.lerp(primary, const Color(0xFF0F172A), 0.7)!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 24),
              const Text(
                'Finding your dream ride…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore Two-Wheelers · Book Test Rides · Live Garage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
