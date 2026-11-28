import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/operator/operator_dashboard.dart';
import '../services/session_manager.dart';

class AppRouter {
  AppRouter._();

  static final SessionManager _session = SessionManager.instance;

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _session,

    redirect: (context, state) {
      final path = state.uri.path;

      final isAuthenticated = _session.isAuthenticated;

      final isAdminRoute =
          path == '/dashboard/admin' || path == '/preview/admin';

      final isOperatorRoute =
          path == '/dashboard/operator' || path == '/preview/operator';

      if (isAdminRoute || isOperatorRoute) {
        if (!isAuthenticated) {
          return '/login';
        }

        if (_session.isAdmin) {
          if (path != '/dashboard/admin') {
            return '/dashboard/admin';
          }
        } else if (_session.isOperator) {
          if (path != '/dashboard/operator') {
            return '/dashboard/operator';
          }
        } else {
          return '/login';
        }
      }

      if (isAuthenticated && path == '/login') {
        return _session.isAdmin ? '/dashboard/admin' : '/dashboard/operator';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),

      GoRoute(
        path: '/dashboard/admin',
        name: 'adminDashboard',
        builder: (context, state) {
          return const AdminDashboard();
        },
      ),

      GoRoute(
        path: '/dashboard/operator',
        name: 'operatorDashboard',
        builder: (context, state) {
          return const OperatorDashboard();
        },
      ),

      // Former preview URLs no longer bypass authentication.
      GoRoute(
        path: '/preview/admin',
        redirect: (context, state) => '/dashboard/admin',
      ),

      GoRoute(
        path: '/preview/operator',
        redirect: (context, state) => '/dashboard/operator',
      ),
    ],
  );
}
