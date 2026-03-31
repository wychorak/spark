import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notifications/notification_service.dart';

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
import '../../features/profile/presentation/screens/profile_detail_screen.dart';

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

bool _isAuthPath(String path) {
  return path == RoutePaths.ageGate ||
      path == RoutePaths.login ||
      path == RoutePaths.register;
}

bool _requiresAuth(String path) {
  return path == RoutePaths.home ||
      path == RoutePaths.discovery ||
      path == RoutePaths.matches ||
      path == RoutePaths.chat ||
      path == RoutePaths.profile ||
      path == RoutePaths.settings ||
      path == RoutePaths.paywall ||
      path == RoutePaths.editProfile ||
      path == RoutePaths.photoVerification ||
      path.startsWith('/chat/') ||
      path.startsWith('/profile/');
}

bool _requiresVerification(String path) {
  return path == RoutePaths.home ||
      path == RoutePaths.discovery ||
      path == RoutePaths.matches ||
      path == RoutePaths.chat ||
      path.startsWith('/chat/');
}

// ─────────────── Router Provider ───────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  Widget buildHomeTab(BuildContext context, int tabIndex) {
    ProviderScope.containerOf(context, listen: false)
        .read(homeTabProvider.notifier)
        .state = tabIndex;
    return const HomeScreen();
  }

  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final path = state.uri.path;
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (_requiresAuth(path)) {
          return RoutePaths.login;
        }
        return null;
      }

      Map<String, dynamic>? profile;
      try {
        profile = await Supabase.instance.client
            .from('user_profiles')
            .select('id, is_verified')
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {}

      final hasProfile = profile != null;
      final isVerified = profile?['is_verified'] == true;

      if (!hasProfile && path != RoutePaths.onboarding) {
        return RoutePaths.onboarding;
      }

      if (hasProfile && path == RoutePaths.onboarding) {
        return isVerified ? RoutePaths.home : RoutePaths.photoVerification;
      }

      if (_isAuthPath(path) || path == RoutePaths.ageGate) {
        return isVerified ? RoutePaths.home : RoutePaths.photoVerification;
      }

      if (!isVerified &&
          _requiresVerification(path) &&
          path != RoutePaths.photoVerification) {
        return RoutePaths.photoVerification;
      }

      if (isVerified && path == RoutePaths.photoVerification) {
        return RoutePaths.home;
      }

      return null;
    },
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
        path: RoutePaths.discovery,
        name: RouteNames.discovery,
        builder: (context, state) => buildHomeTab(context, 0),
      ),
      GoRoute(
        path: RoutePaths.matches,
        name: RouteNames.matches,
        builder: (context, state) => buildHomeTab(context, 1),
      ),
      GoRoute(
        path: RoutePaths.chat,
        name: RouteNames.chat,
        builder: (context, state) => buildHomeTab(context, 2),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => buildHomeTab(context, 3),
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
          final name = state.uri.queryParameters['name'] ?? '';
          final photo = state.uri.queryParameters['photo'] ?? '';
          final mode = state.uri.queryParameters['mode'] ?? 'relationship';
          final uid = state.uri.queryParameters['uid'] ?? '';
          return ChatScreen(
            matchId: chatId,
            matchName: name,
            matchPhotoUrl: photo,
            matchMode: mode,
            otherUserId: uid,
          );
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
      GoRoute(
        path: '/profile/:id',
        name: RouteNames.profileView,
        builder: (context, state) {
          final profileId = state.pathParameters['id'] ?? '';
          return ProfileDetailScreen(profileId: profileId);
        },
      ),
    ],
  );
});
