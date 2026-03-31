import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/crash_reporting_service.dart';
import '../../features/notifications/notification_service.dart';
import 'supabase_provider.dart';

/// Stream of auth state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.onAuthStateChange;
});

/// Current session stream
final authSessionProvider = StreamProvider<Session?>((ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.onAuthStateChange.map((event) => event.session);
});

/// Current user reactive to auth state changes.
final currentUserProvider = Provider<User?>((ref) {
  final sessionAsync = ref.watch(authSessionProvider);
  final sessionUser = sessionAsync.maybeWhen(
    data: (session) => session?.user,
    orElse: () => null,
  );
  return sessionUser ?? Supabase.instance.client.auth.currentUser;
});

/// Whether the user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Auth actions notifier
final authActionsProvider =
    StateNotifierProvider<AuthActionsNotifier, AsyncValue<void>>((ref) {
  return AuthActionsNotifier(ref.watch(supabaseAuthProvider));
});

class AuthActionsNotifier extends StateNotifier<AsyncValue<void>> {
  AuthActionsNotifier(this._auth) : super(const AsyncData(null));

  final GoTrueClient _auth;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithPassword(email: email, password: password);
      await _syncSignedInUser();
      await AnalyticsService.instance.track(
        'sign_in_success',
        properties: {'method': 'email'},
      );
    });
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await _auth.signUp(email: email, password: password);

      if (res.user != null &&
          (res.user!.identities == null || res.user!.identities!.isEmpty)) {
        throw const AuthException(
          'User already registered',
          statusCode: '400',
          code: 'user_already_exists',
        );
      }

      if (res.session == null && res.user != null) {
        await _auth.signInWithPassword(email: email, password: password);
      }

      await _syncSignedInUser();
      await AnalyticsService.instance.track(
        'sign_up_success',
        properties: {'method': 'email'},
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AnalyticsService.instance.track('sign_out');
      await AnalyticsService.instance.clearUser();
      await CrashReportingService.instance.clearUser();
      await NotificationService.instance.deleteToken();
      try {
        await Purchases.logOut();
      } catch (_) {}
      await _auth.signOut();
    });
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.resetPasswordForEmail(email);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AnalyticsService.instance.track(
        'sign_in_started',
        properties: {'method': 'google'},
      );
      await _auth.signInWithOAuth(OAuthProvider.google);
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AnalyticsService.instance.track(
        'sign_in_started',
        properties: {'method': 'apple'},
      );
      await _auth.signInWithOAuth(OAuthProvider.apple);
    });
  }

  Future<void> _syncSignedInUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await Purchases.logIn(user.id);
    } catch (_) {}

    await AnalyticsService.instance.identifyUser(
      userId: user.id,
      email: user.email,
    );
    await CrashReportingService.instance.setUser(
      userId: user.id,
      email: user.email,
    );
  }
}
