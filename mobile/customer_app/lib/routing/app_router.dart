import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/otp_page.dart';
import '../features/catalog/presentation/compare_page.dart';
import '../features/catalog/presentation/home_page.dart';
import '../features/catalog/presentation/model_detail_page.dart';
import '../features/leads/presentation/activity_page.dart';
import '../features/leads/presentation/enquiry_page.dart';
import '../features/leads/presentation/test_ride_page.dart';
import '../features/profile/presentation/edit_profile_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/service/presentation/garage_page.dart';
import '../features/service/presentation/service_booking_page.dart';
import '../features/service/presentation/service_tracking_page.dart';
import '../features/shell/presentation/customer_shell.dart';
import '../features/showroom/presentation/showroom_viewer_page.dart';

import '../features/staff/staff_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/staff', builder: (context, state) => const StaffPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/compare', builder: (context, state) => const ComparePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/activity', builder: (context, state) => const ActivityPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/garage', builder: (context, state) => const GaragePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/models/:modelId',
        builder: (context, state) => ModelDetailPage(modelId: state.pathParameters['modelId'] ?? ''),
      ),
      GoRoute(
        path: '/viewer/:variantId',
        builder: (context, state) => ShowroomViewerPage(
          variantId: state.pathParameters['variantId'] ?? '',
          initialColorId: state.uri.queryParameters['colorId'],
        ),
      ),
      GoRoute(
        path: '/enquiry',
        builder: (context, state) => EnquiryPage(
          variantId: state.uri.queryParameters['variantId'] ?? '',
          branchId: state.uri.queryParameters['branchId'] ?? '',
          colorId: state.uri.queryParameters['colorId'],
          modelName: state.uri.queryParameters['modelName'] ?? '',
          variantName: state.uri.queryParameters['variantName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/test-ride',
        builder: (context, state) => TestRidePage(
          variantId: state.uri.queryParameters['variantId'] ?? '',
          branchId: state.uri.queryParameters['branchId'] ?? '',
          modelName: state.uri.queryParameters['modelName'] ?? '',
          variantName: state.uri.queryParameters['variantName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => OtpPage(
          phone: state.uri.queryParameters['phone'] ?? '',
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/service/book',
        builder: (context, state) => ServiceBookingPage(
          initialVehicleId: state.uri.queryParameters['vehicleId'],
        ),
      ),
      GoRoute(
        path: '/service/track/:bookingId',
        builder: (context, state) => ServiceTrackingPage(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
