import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/analytics_service.dart';
import '../../../../firebase/auth_service.dart';
import '../../../../firebase/crashlytics_service.dart';
import '../../../../firebase/firebase_providers.dart';
import 'auth_state.dart';

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    final current = ref.read(authServiceProvider).currentUser;
    if (current != null) {
      return AuthState(status: AuthStatus.authenticated, user: current);
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  AuthService get _auth => ref.read(authServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);
  CrashlyticsService get _crashlytics => ref.read(crashlyticsServiceProvider);

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final credential = await _auth.signInWithGoogle();
      if (!ref.mounted) return;

      // User đóng dialog — không coi là lỗi.
      if (credential == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final user = credential.user;
      state = AuthState(status: AuthStatus.authenticated, user: user);

      unawaited(_analytics.logLogin().catchError((_) {}));
      unawaited(_analytics.setUserId(user?.uid).catchError((_) {}));
      if (user != null) {
        unawaited(_crashlytics.setUserIdentifier(user.uid).catchError((_) {}));
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _friendlyMessage(e),
      );
    }
  }

  static String _friendlyMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('network') || raw.contains('NETWORK')) {
      return 'Network error. Check your connection and try again.';
    }
    if (raw.contains('missing-id-token') ||
        raw.contains('google-sign-in-config') ||
        raw.contains('SHA-1') ||
        raw.contains('clientConfigurationError')) {
      return 'Google Sign-In misconfigured. Add debug SHA-1 in Firebase Console, then rebuild.';
    }
    return 'Sign-in failed. Please try again.';
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
