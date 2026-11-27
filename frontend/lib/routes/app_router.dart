import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';

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
    ],
  );
}
