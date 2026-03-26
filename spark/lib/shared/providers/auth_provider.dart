import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// Current user — reactive to auth state changes (e.g. session restore on web)
final currentUserProvider = Provider<User?>((ref) {
  // Watch the session stream so this provider updates when auth state changes
  final sessionAsync = ref.watch(authSessionProvider);
  final sessionUser = sessionAsync.maybeWhen(
    data: (s) => s?.user,
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
  final GoTrueClient _auth;

  AuthActionsNotifier(this._auth) : super(const AsyncData(null));

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await _auth.signUp(email: email, password: password);
      // If no session (email confirmation required), sign in immediately
      if (res.session == null && res.user != null) {
        await _auth.signInWithPassword(email: email, password: password);
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
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
      await _auth.signInWithOAuth(OAuthProvider.google);
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithOAuth(OAuthProvider.apple);
    });
  }
}
