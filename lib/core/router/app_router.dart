import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/auth_provider.dart';

part 'app_router.g.dart';

// ─────────────── Route Paths ───────────────

abstract final class RoutePaths {
  static const String splash = '/';
  static const String ageGate = '/age-gate';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String discovery = '/home/discovery';
  static const String matches = '/home/matches';
  static const String chat = '/home/chat';
  static const String profile = '/home/profile';
  static const String settings = '/settings';
  static const String paywall = '/paywall';
  static const String chatDetail = '/chat/:id';
  static const String profileView = '/profile/:id';
  static const String editProfile = '/edit-profile';
  static const String photoVerification = '/photo-verification';
}

// ─────────────── Route Names ───────────────

abstract final class RouteNames {
  static const String splash = 'splash';
  static const String ageGate = 'ageGate';
  static const String login = 'login';
  static const String register = 'register';
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String discovery = 'discovery';
  static const String matches = 'matches';
  static const String chat = 'chat';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String paywall = 'paywall';
  static const String chatDetail = 'chatDetail';
  static const String profileView = 'profileView';
  static const String editProfile = 'editProfile';
  static const String photoVerification = 'photoVerification';
}

// ─────────────── Shell Scaffold ───────────────

/// The shell for bottom-nav pages. Import your SparkBottomNav here.
class _HomeShellScaffold extends StatelessWidget {
  const _HomeShellScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      // Replace with SparkBottomNav once wired up:
      // bottomNavigationBar: const SparkBottomNav(),
    );
  }
}

// ─────────────── Placeholder screens ───────────────
// These will be replaced with real screens from features/.

Widget _placeholder(String name) =>
    Scaffold(body: Center(child: Text(name, style: const TextStyle(color: Colors.white))));

// ─────────────── Router Provider ───────────────

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.matchedLocation;

      // Public routes that don't require auth
      const publicRoutes = [
        RoutePaths.splash,
        RoutePaths.ageGate,
        RoutePaths.login,
        RoutePaths.register,
      ];

      final isPublicRoute = publicRoutes.contains(currentPath);

      // If on splash, let it handle its own navigation
      if (currentPath == RoutePaths.splash) return null;

      // Not logged in and trying to access protected route
      if (!isLoggedIn && !isPublicRoute) return RoutePaths.login;

      // Logged in and on a public route (except splash)
      if (isLoggedIn && isPublicRoute) return RoutePaths.discovery;

      return null;
    },
    routes: [
      // ── Splash ──
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => _placeholder('Splash'),
      ),

      // ── Age Gate ──
      GoRoute(
        path: RoutePaths.ageGate,
        name: RouteNames.ageGate,
        builder: (context, state) => _placeholder('Age Gate'),
      ),

      // ── Login ──
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => _placeholder('Login'),
      ),

      // ── Register ──
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => _placeholder('Register'),
      ),

      // ── Onboarding ──
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => _placeholder('Onboarding'),
      ),

      // ── Home (Shell with Bottom Nav) ──
      ShellRoute(
        builder: (context, state, child) => _HomeShellScaffold(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.discovery,
            name: RouteNames.discovery,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Discovery'),
            ),
          ),
          GoRoute(
            path: RoutePaths.matches,
            name: RouteNames.matches,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Matches'),
            ),
          ),
          GoRoute(
            path: RoutePaths.chat,
            name: RouteNames.chat,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Chat'),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Profile'),
            ),
          ),
        ],
      ),

      // ── Settings ──
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => _placeholder('Settings'),
      ),

      // ── Paywall ──
      GoRoute(
        path: RoutePaths.paywall,
        name: RouteNames.paywall,
        builder: (context, state) => _placeholder('Paywall'),
      ),

      // ── Chat Detail ──
      GoRoute(
        path: RoutePaths.chatDetail,
        name: RouteNames.chatDetail,
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          return _placeholder('Chat Detail: $chatId');
        },
      ),

      // ── Profile View ──
      GoRoute(
        path: RoutePaths.profileView,
        name: RouteNames.profileView,
        builder: (context, state) {
          final profileId = state.pathParameters['id']!;
          return _placeholder('Profile View: $profileId');
        },
      ),

      // ── Edit Profile ──
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) => _placeholder('Edit Profile'),
      ),

      // ── Photo Verification ──
      GoRoute(
        path: RoutePaths.photoVerification,
        name: RouteNames.photoVerification,
        builder: (context, state) => _placeholder('Photo Verification'),
      ),
    ],
  );
}

// ── Placeholder widget used in NoTransitionPage ──
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 24)),
    );
  }
}
