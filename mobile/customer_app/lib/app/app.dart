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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, Color.lerp(primary, Colors.black, 0.5)!],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 56),
              SizedBox(height: 16),
              Text(
                'Starting your showroom…',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
