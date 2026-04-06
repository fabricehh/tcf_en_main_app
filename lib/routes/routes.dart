import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth_screens/login_screen.dart';
import '../screens/auth_screens/register_screen.dart';
import '../screens/splash_screen/splash_screen.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Configuration des routes avec GoRouter
class RoutesClass {
  static const String splash = '/';
  static const String login = '/connexion';
  static const String register = '/inscription';
  static const String overview = '/app/vue-d-ensemble';
  static const String profile = '/app/profil';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/app',
        redirect: (context, state) async {
          if (state.fullPath == '/app' || state.fullPath == '/app/') {
            return overview;
          }
          return null;
        },
        routes: [
         /* GoRoute(
            path: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),*/
        ],
      ),
    ],
    redirect: (context, state) async {
      final supabase = Supabase.instance.client;
      final isLoggedIn = supabase.auth.currentUser != null;
      String? path = state.fullPath ?? "";

      // Protection de toutes les routes /app/** par défaut
      final protectedRoute = path.startsWith("/app");

      if (protectedRoute && !isLoggedIn) {
        return login;
      }
      // Si l'utilisateur est connecté et essaie d'accéder à /login, rediriger vers /app/dashboard
      if (path == login && isLoggedIn) {
        return overview;
      }

      return null;
    },
  );
}
