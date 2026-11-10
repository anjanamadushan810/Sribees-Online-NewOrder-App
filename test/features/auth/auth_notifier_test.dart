import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/core/constants/app_constants.dart';
import 'package:sribees_new_orders/core/network/api_exceptions.dart';
import 'package:sribees_new_orders/features/auth/models/admin_user.dart';
import 'package:sribees_new_orders/features/auth/models/auth_state.dart';
import 'package:sribees_new_orders/features/auth/providers/auth_provider.dart';

import '../../helpers/fakes.dart';

void main() {
  late MemoryStorage storage;
  late FakeAuthRepository repo;

  AuthNotifier make() =>
      AuthNotifier(repository: repo, storage: storage, restoreOnStart: false);

  setUp(() {
    storage = MemoryStorage();
    repo = FakeAuthRepository(storage);
  });

  group('login', () {
    test('a branch manager gets in, with their own branch resolved', () async {
      repo.branches = const [kalutara, matugama];
      final n = make();
      expect(await n.login(' nimal@sribees.lk ', 'pw'), isTrue);
      expect(n.state.status, AuthStatus.authenticated);
      expect(n.state.branch, matugama);
      expect(storage.data[AppConstants.keyUserData], isNotNull);
    });

    test('a super admin gets in with no branch (sees all)', () async {
      repo.loginResult = AdminUser.fromJson(adminJson(role: 'super_admin', branchId: null));
      final n = make();
      expect(await n.login('a@b.lk', 'pw'), isTrue);
      expect(n.state.user!.isUnscoped, isTrue);
      expect(n.state.branch, isNull);
    });

    test('wrong password (401) -> invalidCredentials, nothing stored', () async {
      repo.loginResult = apiError(401);
      final n = make();
      expect(await n.login('a@b.lk', 'bad'), isFalse);
      expect(n.state.status, AuthStatus.unauthenticated);
      expect(n.state.failure, AuthFailure.invalidCredentials);
      expect(storage.data, isEmpty);
    });

    test('no orders:read -> refused, server session closed, tokens wiped', () async {
      repo.loginResult = AdminUser.fromJson(adminJson(role: 'marketing_manager',
          perms: ['banners:read']));
      final n = make();
      expect(await n.login('a@b.lk', 'pw'), isFalse);
      expect(n.state.failure, AuthFailure.noOrderAccess);
      expect(repo.logoutCalls, 1);
      expect(storage.data, isEmpty);
    });

    test('branch-scoped role without a branch -> noBranch', () async {
      repo.loginResult = AdminUser.fromJson(adminJson(branchId: null));
      final n = make();
      expect(await n.login('a@b.lk', 'pw'), isFalse);
      expect(n.state.failure, AuthFailure.noBranch);
      expect(storage.data, isEmpty);
    });

    test('network trouble maps to its own message', () async {
      final n = make();
      repo.loginResult = apiError(null, kind: ApiErrorKind.offline);
      await n.login('a@b.lk', 'pw');
      expect(n.state.failure, AuthFailure.offline);
      repo.loginResult = apiError(null, kind: ApiErrorKind.timeout);
      await n.login('a@b.lk', 'pw');
      expect(n.state.failure, AuthFailure.timeout);
      repo.loginResult = apiError(502);
      await n.login('a@b.lk', 'pw');
      expect(n.state.failure, AuthFailure.server);
    });
  });

  group('restore session', () {
    Future<void> seed(Map<String, dynamic> admin) async {
      await storage.saveAccessToken('access');
      await storage.saveRefreshToken('refresh');
      await storage.saveUserData(jsonEncode(AdminUser.fromJson(admin).toJson()));
    }

    test('no saved session -> login screen', () async {
      final n = make();
      await n.restoreSession();
      expect(n.state.status, AuthStatus.unauthenticated);
      expect(n.state.failure, isNull);
    });

    test('saved session -> straight in, profile re-read', () async {
      await seed(adminJson());
      final n = make();
      await n.restoreSession();
      expect(n.state.status, AuthStatus.authenticated);
      expect(n.state.branch, matugama);
    });

    test('Orders permission removed since last time -> signed out', () async {
      await seed(adminJson());
      repo.profileResult = AdminUser.fromJson(adminJson(perms: ['products:read']));
      final n = make();
      await n.restoreSession();
      expect(n.state.status, AuthStatus.unauthenticated);
      expect(n.state.failure, AuthFailure.noOrderAccess);
      expect(storage.data, isEmpty);
    });

    test('offline at start -> keeps working from the cached profile', () async {
      await seed(adminJson());
      repo.profileResult = apiError(null, kind: ApiErrorKind.offline);
      final n = make();
      await n.restoreSession();
      expect(n.state.status, AuthStatus.authenticated);
      expect(n.state.user!.fullName, 'Nimal Perera');
    });

    test('server rejects the session -> sessionExpired', () async {
      await seed(adminJson());
      repo.profileResult = apiError(401);
      final n = make();
      await n.restoreSession();
      expect(n.state.status, AuthStatus.unauthenticated);
      expect(n.state.failure, AuthFailure.sessionExpired);
    });
  });

  test('logout ends the server session and wipes the phone', () async {
    final n = make();
    await n.login('a@b.lk', 'pw');
    await n.logout();
    expect(repo.logoutCalls, 1);
    expect(storage.data, isEmpty);
    expect(n.state.status, AuthStatus.unauthenticated);
    expect(n.state.failure, isNull);
  });
}
