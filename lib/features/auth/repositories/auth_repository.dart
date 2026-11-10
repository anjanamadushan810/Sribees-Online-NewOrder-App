import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/admin_user.dart';
import '../models/branch.dart';

/// Server calls behind sign-in. An interface so tests can swap in a fake.
abstract class AuthRepository {
  /// Signs in, stores the token pair, returns the admin.
  Future<AdminUser> login(String email, String password);

  /// The current admin (fresh role, branch and permissions).
  Future<AdminUser> getProfile();

  /// Branches this admin may see (super admin: all; others: their own).
  Future<List<Branch>> getBranches();

  /// Ends the server session (best effort); never throws.
  Future<void> logout();

  /// Renews the access token if it is close to expiry; never throws.
  Future<void> refreshIfNeeded();
}

class HttpAuthRepository implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;

  HttpAuthRepository({required this.apiClient, required this.storage});

  @override
  Future<AdminUser> login(String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {'email': email.trim(), 'password': password},
    );
    final body = response.data;
    if (body is Map && body['data'] is Map) {
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final access = (data['token'] ?? data['accessToken'] ?? '').toString();
      final refresh = (data['refresh_token'] ?? data['refreshToken'] ?? '').toString();
      if (access.isEmpty || refresh.isEmpty || data['admin'] is! Map) {
        throw const FormatException('login response without tokens');
      }
      await storage.saveAccessToken(access);
      await storage.saveRefreshToken(refresh);
      return AdminUser.fromJson(Map<String, dynamic>.from(data['admin'] as Map));
    }
    throw const FormatException('unexpected login response');
  }

  @override
  Future<AdminUser> getProfile() async {
    final response = await apiClient.get(ApiEndpoints.me);
    final body = response.data;
    if (body is Map && body['admin'] is Map) {
      return AdminUser.fromJson(Map<String, dynamic>.from(body['admin'] as Map));
    }
    throw const FormatException('unexpected profile response');
  }

  @override
  Future<List<Branch>> getBranches() async {
    final response = await apiClient.get(
      ApiEndpoints.branches,
      queryParameters: {'include_inactive': false},
    );
    final body = response.data;
    final list = (body is Map && body['data'] is Map) ? body['data']['branches'] : null;
    if (list is! List) return const [];
    return [
      for (final b in list)
        if (b is Map) Branch.fromJson(Map<String, dynamic>.from(b)),
    ];
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Best effort: the local session is cleared regardless.
    }
  }

  @override
  Future<void> refreshIfNeeded() async {
    try {
      await apiClient.refreshToken();
    } catch (_) {
      // Offline: keep the current token; a 401/403 is handled by ApiClient.
    }
  }
}
