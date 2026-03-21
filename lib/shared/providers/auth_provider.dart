import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

part 'auth_provider.g.dart';

/// Stream of auth state changes (sign in, sign out, token refresh, etc.)
@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.onAuthStateChange;
}

/// Current auth session (nullable). Emits on every auth change.
@riverpod
Stream<Session?> authState(Ref ref) {
  final auth = ref.watch(supabaseAuthProvider);
  // Seed with current session, then follow the stream
  return auth.onAuthStateChange.map((event) => event.session);
}

/// Current user (nullable), derived from session.
@riverpod
User? currentUser(Ref ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.currentUser;
}

/// Whether the user is currently logged in.
@riverpod
bool isLoggedIn(Ref ref) {
  return ref.watch(currentUserProvider) != null;
}

/// Auth actions notifier – sign in, sign up, sign out, reset password.
@riverpod
class AuthActions extends _$AuthActions {
  @override
  FutureOr<void> build() {}

  GoTrueClient get _auth => ref.read(supabaseAuthProvider);

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
      await _auth.signUp(email: email, password: password);
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
