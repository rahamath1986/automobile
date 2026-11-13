import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/customer/auth/ui/otp_request_page.dart';
import 'features/customer/auth/ui/otp_verify_page.dart';
import 'features/customer/home/customer_home_page.dart';
import 'features/customer/catalog/ui/catalog_page.dart';
import 'features/customer/showroom/ui/showroom_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // ─── Customer auth ─────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (_, __) => const OtpRequestPage(),
    ),
    GoRoute(
      path: '/verify',
      builder: (_, __) => const OtpVerifyPage(),
    ),

    // ─── Customer home & catalog ───────────────────────────────────────────
    GoRoute(
      path: '/customer/home',
      builder: (_, __) => const CustomerHomePage(),
    ),
    GoRoute(
      path: '/catalog',
      builder: (_, state) {
        final category = state.queryParameters['category'];
        final fuelType = state.queryParameters['fuelType'];
        return CatalogPage(initialCategory: category, initialFuelType: fuelType);
      },
    ),

    // ─── Showroom ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/showroom/:variantId',
      builder: (context, state) {
        final variantId = state.pathParameters['variantId']!;
        final colorId = state.queryParameters['colorId'];
        return ShowroomPage(variantId: variantId, colorId: colorId);
      },
    ),

    // ─── Dealer / staff stack (Phase 12) ──────────────────────────────────
    // GoRoute(path: '/staff/login', builder: (_, __) => const StaffLoginPage()),
  ],
);

