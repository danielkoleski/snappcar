import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/invoices/presentation/pages/invoice_capture_page.dart';
import '../../features/invoices/presentation/pages/invoices_list_page.dart';
import '../../features/maintenance/presentation/pages/add_maintenance_page.dart';
import '../../features/maintenance/presentation/pages/maintenance_list_page.dart';
import '../../features/mileage/presentation/pages/mileage_page.dart';
import '../../features/notifications/presentation/pages/notification_preferences_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/vehicles/presentation/pages/add_vehicle_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_list_page.dart';
import '../shell/main_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authStream = Supabase.instance.client.auth.onAuthStateChange;

  return GoRouter(
    initialLocation: '/vehicles',
    refreshListenable: _GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/vehicles';
      return null;
    },
    routes: [
      // ── Auth routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),

      // ── Shell (bottom nav) ────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/vehicles',
            name: 'vehiclesList',
            builder: (context, state) => const VehiclesListPage(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'addVehicle',
                builder: (context, state) => const AddVehiclePage(),
              ),
              GoRoute(
                path: ':vehicleId',
                name: 'vehicleDetail',
                builder: (context, state) => VehicleDetailPage(
                  vehicleId: state.pathParameters['vehicleId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'maintenance',
                    name: 'maintenanceList',
                    builder: (context, state) => MaintenanceListPage(
                      vehicleId: state.pathParameters['vehicleId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'add',
                        name: 'addMaintenance',
                        builder: (context, state) => AddMaintenancePage(
                          vehicleId: state.pathParameters['vehicleId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'mileage',
                    name: 'mileage',
                    builder: (context, state) => MileagePage(
                      vehicleId: state.pathParameters['vehicleId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'invoices',
                    name: 'invoicesList',
                    builder: (context, state) => InvoicesListPage(
                      vehicleId: state.pathParameters['vehicleId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'capture',
                        name: 'invoiceCapture',
                        builder: (context, state) => InvoiceCapturePage(
                          vehicleId: state.pathParameters['vehicleId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'notifications',
                name: 'notificationPreferences',
                builder: (context, state) =>
                    const NotificationPreferencesPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Adapts an auth stream to a [ChangeNotifier] for go_router's refreshListenable.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
