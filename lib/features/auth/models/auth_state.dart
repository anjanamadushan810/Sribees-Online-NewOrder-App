import 'admin_user.dart';
import 'branch.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

/// Why the last sign-in attempt (or session check) failed.
enum AuthFailure {
  invalidCredentials, // 401 on login: wrong email/password or disabled account
  noOrderAccess, // signed in, but the role lacks orders:read
  noBranch, // branch-scoped role with no branch assigned
  sessionExpired, // refresh token rejected
  offline,
  timeout,
  server,
  unknown,
}

class AuthState {
  final AuthStatus status;
  final AdminUser? user;

  /// The admin's own branch (null for unscoped admins, or if it could not
  /// be loaded yet).
  final Branch? branch;
  final AuthFailure? failure;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.branch,
    this.failure,
  });

  bool get isBusy => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AdminUser? user,
    Branch? branch,
    AuthFailure? failure,
    bool clearFailure = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        branch: branch ?? this.branch,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}
