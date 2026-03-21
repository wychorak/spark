import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/age_gate_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/discovery/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/premium/presentation/screens/paywall_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/safety/presentation/screens/photo_verification_screen.dart';

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

// ─────────────── Router Provider ───────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.ageGate,
        name: RouteNames.ageGate,
        builder: (context, state) => const AgeGateScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.paywall,
        name: RouteNames.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: RoutePaths.chatDetail,
        name: RouteNames.chatDetail,
        builder: (context, state) {
          final chatId = state.pathParameters['id'] ?? '';
          return ChatScreen(matchId: chatId);
        },
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.photoVerification,
        name: RouteNames.photoVerification,
        builder: (context, state) => const PhotoVerificationScreen(),
      ),
    ],
  );
});
