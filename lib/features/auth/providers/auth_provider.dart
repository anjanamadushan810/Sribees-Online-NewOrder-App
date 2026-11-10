import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/jwt_utils.dart';
import '../models/admin_user.dart';
import '../models/auth_state.dart';
import '../models/branch.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    storage: ref.watch(secureStorageProvider),
  );
  // A refresh token the server rejects ends the session everywhere.
  ref.watch(apiClientProvider).onUnauthorized = notifier.sessionExpired;
  return notifier;
});

/// Sign-in, session restore and sign-out.
///
/// Who may use the app is the admin web's rule: any active admin whose
/// effective permissions include `orders:read`. A branch-scoped role must
/// also have a branch. The server enforces both on every request; the
/// checks here only give a clear message instead of empty screens.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SecureStorageService storage;

  AuthNotifier({
    required this.repository,
    required this.storage,
    bool restoreOnStart = true,
  }) : super(const AuthState()) {
    if (restoreOnStart) restoreSession();
  }

  /// App start: open straight from the cached profile, then re-check the
  /// profile with the server so a removed permission takes effect.
  Future<void> restoreSession() async {
    final access = await storage.getAccessToken();
    final refresh = await storage.getRefreshToken();
    final cached = _decodeUser(await storage.getUserData());
    if (cached == null || ((access ?? '').isEmpty && (refresh ?? '').isEmpty)) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    if (_accessFailure(cached) != null) {
      await _clearLocal();
      state = AuthState(status: AuthStatus.unauthenticated, failure: _accessFailure(cached));
      return;
    }
    state = AuthState(status: AuthStatus.authenticated, user: cached);
    await refreshProfile();
  }

  /// Re-read role, branch and permissions from the server.
  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      final user = await repository.getProfile();
      final failure = _accessFailure(user);
      if (failure != null) {
        await repository.logout();
        await _clearLocal();
        state = AuthState(status: AuthStatus.unauthenticated, failure: failure);
        return;
      }
      await storage.saveUserData(jsonEncode(user.toJson()));
      final branch = await _loadOwnBranch(user);
      if (!mounted || state.status != AuthStatus.authenticated) return;
      state = AuthState(status: AuthStatus.authenticated, user: user, branch: branch);
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized || e.kind == ApiErrorKind.forbidden) {
        await sessionExpired();
      }
      // Offline / server trouble: keep working from the cached profile.
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearFailure: true);
    try {
      final user = await repository.login(email, password);
      final failure = _accessFailure(user);
      if (failure != null) {
        // Signed in on the server but not allowed here: close that session.
        await repository.logout();
        await _clearLocal();
        state = AuthState(status: AuthStatus.unauthenticated, failure: failure);
        return false;
      }
      await storage.saveUserData(jsonEncode(user.toJson()));
      final branch = await _loadOwnBranch(user);
      state = AuthState(status: AuthStatus.authenticated, user: user, branch: branch);
      return true;
    } on ApiException catch (e) {
      await _clearLocal();
      state = AuthState(status: AuthStatus.unauthenticated, failure: _failureFor(e));
      return false;
    } catch (_) {
      await _clearLocal();
      state = const AuthState(status: AuthStatus.unauthenticated, failure: AuthFailure.unknown);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await repository.logout();
    await _clearLocal();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// The server refused our refresh token: back to the login screen.
  Future<void> sessionExpired() async {
    await _clearLocal();
    if (!mounted) return;
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      failure: AuthFailure.sessionExpired,
    );
  }

  /// Foreground again: renew a token that is about to expire, then re-check
  /// permissions.
  Future<void> onAppResumed() async {
    if (state.status != AuthStatus.authenticated) return;
    final token = await storage.getAccessToken();
    if (token == null || JwtUtils.isExpired(token, thresholdSeconds: 120)) {
      await repository.refreshIfNeeded();
    }
    await refreshProfile();
  }

  // ---------------------------------------------------------------------

  static AuthFailure? _accessFailure(AdminUser user) {
    if (!user.canReadOrders) return AuthFailure.noOrderAccess;
    if (!user.isUnscoped && user.branchId == null) return AuthFailure.noBranch;
    return null;
  }

  static AuthFailure _failureFor(ApiException e) {
    switch (e.kind) {
      case ApiErrorKind.unauthorized:
        return AuthFailure.invalidCredentials;
      case ApiErrorKind.offline:
        return AuthFailure.offline;
      case ApiErrorKind.timeout:
        return AuthFailure.timeout;
      case ApiErrorKind.server:
        return AuthFailure.server;
      case ApiErrorKind.conflict:
        // 422: the email is not a valid address.
        return AuthFailure.invalidCredentials;
      default:
        return AuthFailure.unknown;
    }
  }

  Future<Branch?> _loadOwnBranch(AdminUser user) async {
    if (user.branchId == null) return null;
    try {
      final branches = await repository.getBranches();
      for (final b in branches) {
        if (b.branchId.toLowerCase() == user.branchId!.toLowerCase()) return b;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _clearLocal() => storage.clearAll();

  static AdminUser? _decodeUser(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return AdminUser.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
