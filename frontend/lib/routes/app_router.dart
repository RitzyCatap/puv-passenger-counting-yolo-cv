import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/operator/operator_dashboard.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',

    routes: [
      // Home page
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),

      // Login page
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),

      // Temporary dashboard preview routes.
      // Available only in debug builds.
      if (kDebugMode) ...[
        GoRoute(
          path: '/preview/admin',
          name: 'adminPreview',
          builder: (context, state) {
            return const AdminDashboard();
          },
        ),

        GoRoute(
          path: '/preview/operator',
          name: 'operatorPreview',
          builder: (context, state) {
            return const OperatorDashboard();
          },
        ),
      ],
    ],
  );
}
