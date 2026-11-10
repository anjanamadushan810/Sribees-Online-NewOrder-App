import 'package:sribees_new_orders/core/constants/app_constants.dart';
import 'package:sribees_new_orders/core/network/api_exceptions.dart';
import 'package:sribees_new_orders/core/storage/secure_storage_service.dart';
import 'package:sribees_new_orders/features/auth/models/admin_user.dart';
import 'package:sribees_new_orders/features/auth/models/branch.dart';
import 'package:sribees_new_orders/features/auth/repositories/auth_repository.dart';

/// SecureStorageService without the platform channel.
class MemoryStorage extends SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<void> saveAccessToken(String token) async => data[AppConstants.keyAccessToken] = token;
  @override
  Future<String?> getAccessToken() async => data[AppConstants.keyAccessToken];
  @override
  Future<void> saveRefreshToken(String token) async => data[AppConstants.keyRefreshToken] = token;
  @override
  Future<String?> getRefreshToken() async => data[AppConstants.keyRefreshToken];
  @override
  Future<void> saveUserData(String jsonStr) async => data[AppConstants.keyUserData] = jsonStr;
  @override
  Future<String?> getUserData() async => data[AppConstants.keyUserData];
  @override
  Future<void> clearAll() async => data.clear();
}

const matugama = Branch(branchId: 'B-1', name: 'Matugama', code: 'MTG');
const kalutara = Branch(branchId: 'B-2', name: 'Kalutara', code: 'KLT');

Map<String, dynamic> adminJson({
  String role = 'branch_manager',
  String? branchId = 'B-1',
  List<String> perms = const ['orders:read', 'orders:update'],
  String name = 'Nimal Perera',
  String? roleName,
}) =>
    {
      'adminId': 'A-1',
      'email': 'nimal@sribees.lk',
      'fullName': name,
      'role': role,
      'roleName': roleName,
      'branchId': branchId,
      'isActive': true,
      'lastLogin': null,
      'createdAt': '2026-11-01T00:00:00Z',
      'permissions': [
        for (final p in perms) {'resource': p.split(':')[0], 'action': p.split(':')[1]},
      ],
    };

/// Scriptable AuthRepository.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.storage);

  final MemoryStorage storage;

  /// What `login` returns (or throws) next.
  Object loginResult = AdminUser.fromJson(adminJson());

  /// What `getProfile` returns (or throws) next.
  Object? profileResult;
  List<Branch> branches = const [matugama];

  int logoutCalls = 0;
  int refreshCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AdminUser> login(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    final r = loginResult;
    if (r is AdminUser) {
      await storage.saveAccessToken('access');
      await storage.saveRefreshToken('refresh');
      return r;
    }
    throw r;
  }

  @override
  Future<AdminUser> getProfile() async {
    final r = profileResult ?? loginResult;
    if (r is AdminUser) return r;
    throw r;
  }

  @override
  Future<List<Branch>> getBranches() async => branches;

  @override
  Future<void> logout() async => logoutCalls++;

  @override
  Future<void> refreshIfNeeded() async => refreshCalls++;
}

ApiException apiError(int? status, {ApiErrorKind? kind}) =>
    ApiException(message: 'x', statusCode: status, kind: kind);
