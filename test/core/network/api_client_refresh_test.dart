import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/core/constants/api_endpoints.dart';
import 'package:sribees_new_orders/core/constants/app_constants.dart';
import 'package:sribees_new_orders/core/network/api_client.dart';
import 'package:sribees_new_orders/core/storage/secure_storage_service.dart';

class InMemorySecureStorage extends SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveAccessToken(String token) async =>
      _data[AppConstants.keyAccessToken] = token;

  @override
  Future<String?> getAccessToken() async =>
      _data[AppConstants.keyAccessToken];

  @override
  Future<void> saveRefreshToken(String token) async =>
      _data[AppConstants.keyRefreshToken] = token;

  @override
  Future<String?> getRefreshToken() async =>
      _data[AppConstants.keyRefreshToken];

  @override
  Future<void> clearAll() async => _data.clear();
}

void main() {
  group('ApiClient Token Refresh & Concurrency Mutex Tests', () {
    late InMemorySecureStorage storage;

    setUp(() {
      storage = InMemorySecureStorage();
    });

    test('Deduplicates concurrent refreshToken calls (Single-Flight Mutex)', () async {
      await storage.saveRefreshToken('initial_rt_token');

      int postCallCount = 0;
      final testTokenDio = Dio();

      testTokenDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.path.contains(ApiEndpoints.refresh)) {
              postCallCount++;
              await Future.delayed(const Duration(milliseconds: 30));
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'token': 'new_at_xyz',
                      'refresh_token': 'new_rt_rotated',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(
        storage: storage,
        tokenDio: testTokenDio,
      );

      // Fire 3 concurrent refresh calls at the exact same moment
      final results = await Future.wait([
        apiClient.refreshToken(),
        apiClient.refreshToken(),
        apiClient.refreshToken(),
      ]);

      // Exactly ONE HTTP POST call should have gone to /admin/auth/refresh
      expect(postCallCount, 1);

      // All 3 callers must receive the exact same new access token
      expect(results[0], 'new_at_xyz');
      expect(results[1], 'new_at_xyz');
      expect(results[2], 'new_at_xyz');

      // Storage must have been updated with rotated tokens
      expect(await storage.getAccessToken(), 'new_at_xyz');
      expect(await storage.getRefreshToken(), 'new_rt_rotated');
    });

    test('Invokes onUnauthorized and wipes storage ONLY on explicit 401/403', () async {
      await storage.saveAccessToken('expired_at');
      await storage.saveRefreshToken('revoked_rt');

      bool unauthorizedTriggered = false;
      final testTokenDio = Dio();

      // Token dio returns 401 on refresh (revoked/expired refresh token)
      testTokenDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'detail': 'Invalid or expired refresh token.'},
                ),
              ),
            );
          },
        ),
      );

      final apiClient = ApiClient(
        storage: storage,
        tokenDio: testTokenDio,
        onUnauthorized: () {
          unauthorizedTriggered = true;
        },
      );

      try {
        await apiClient.refreshToken();
      } catch (_) {}

      // Session must be purged and unauthorized callback triggered
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(unauthorizedTriggered, isTrue);
    });

    test('Does NOT wipe storage or logout on network disconnection/timeout', () async {
      await storage.saveAccessToken('expired_at');
      await storage.saveRefreshToken('valid_rt');

      bool unauthorizedTriggered = false;
      final testTokenDio = Dio();

      // Refresh endpoint fails due to socket timeout / offline
      testTokenDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
                message: 'Connection timed out',
              ),
            );
          },
        ),
      );

      final apiClient = ApiClient(
        storage: storage,
        tokenDio: testTokenDio,
        onUnauthorized: () {
          unauthorizedTriggered = true;
        },
      );

      try {
        await apiClient.refreshToken();
      } catch (_) {}

      // Storage MUST preserve saved tokens!
      expect(await storage.getAccessToken(), 'expired_at');
      expect(await storage.getRefreshToken(), 'valid_rt');
      expect(unauthorizedTriggered, isFalse);
    });
  });
}
