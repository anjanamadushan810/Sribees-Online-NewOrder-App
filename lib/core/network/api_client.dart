import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import '../utils/jwt_utils.dart';
import 'api_exceptions.dart';

/// Centralized Dio API Client with Auto-Auth Interceptors and Silent Token Refresh
class ApiClient {
  late final Dio _dio;
  late final Dio _tokenDio;
  final SecureStorageService storage;
  void Function()? onUnauthorized;

  /// Single-flight completer to deduplicate concurrent refresh calls
  Completer<String?>? _refreshCompleter;

  ApiClient({
    required this.storage,
    this.onUnauthorized,
    Dio? dio,
    Dio? tokenDio,
  }) {
    final baseOptions = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Dedicated Dio instance for auth token operations (avoids interceptor loops)
    _tokenDio = tokenDio ?? Dio(baseOptions);

    _dio = dio ?? Dio(baseOptions);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isAuthEndpoint = options.path.contains('/login') ||
              options.path.contains('/refresh');

          if (!isAuthEndpoint) {
            String? token = await storage.getAccessToken();

            // Proactive silent refresh:
            // If access token is about to expire in <= 90s (or is already expired),
            // refresh it BEFORE sending the request to eliminate 401 interruptions.
            if (token != null && JwtUtils.isExpired(token, thresholdSeconds: 90)) {
              final refreshTokenVal = await storage.getRefreshToken();
              if (refreshTokenVal != null && refreshTokenVal.trim().isNotEmpty) {
                try {
                  final refreshed = await refreshToken();
                  if (refreshed != null && refreshed.isNotEmpty) {
                    token = refreshed;
                  }
                } catch (_) {
                  // Network blip / offline: proceed with existing token
                }
              }
            }

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // No branch header: the server derives branch scope from the
          // login alone (BranchScope). A super admin's branch filter is a
          // query parameter on the call that needs it.
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.contains('/login') ||
              error.requestOptions.path.contains('/refresh');

          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            // Check if another concurrent request already refreshed the token
            final currentToken = await storage.getAccessToken();
            final headerAuth = error.requestOptions.headers['Authorization']?.toString();
            final sentToken = headerAuth?.replaceFirst('Bearer ', '').trim();

            String? tokenToUse;
            if (currentToken != null &&
                currentToken.isNotEmpty &&
                currentToken != sentToken &&
                !JwtUtils.isExpired(currentToken, thresholdSeconds: 15)) {
              tokenToUse = currentToken;
            } else {
              try {
                tokenToUse = await refreshToken();
              } catch (_) {
                // Refresh failed (either offline or revoked)
                return handler.next(error);
              }
            }

            if (tokenToUse != null && tokenToUse.isNotEmpty) {
              // Retry original failed request in an isolated try-catch
              try {
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $tokenToUse';

                final clonedResponse = await _dio.fetch(retryOptions);
                return handler.resolve(clonedResponse);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Single-flight token refresh: concurrent 401s share one ongoing backend request.
  /// Deduplicates parallel calls to avoid invalidating the backend's rotated refresh token.
  Future<String?> refreshToken() async {
    // If a refresh is already in flight, reuse the ongoing future
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    // Ignore uncaught error on the completer future itself since individual callers catch/await it
    completer.future.catchError((_) => null);
    _refreshCompleter = completer;

    try {
      final refreshTokenVal = await storage.getRefreshToken();
      if (refreshTokenVal == null || refreshTokenVal.trim().isEmpty) {
        await storage.clearAll();
        onUnauthorized?.call();
        completer.complete(null);
        return null;
      }

      final refreshResponse = await _tokenDio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshTokenVal.trim()},
      );

      final resData = refreshResponse.data;
      if (resData is Map && resData['data'] is Map) {
        final dataMap = resData['data'] as Map<String, dynamic>;
        final newAccessToken = dataMap['token']?.toString() ??
            dataMap['accessToken']?.toString() ??
            dataMap['access_token']?.toString();
        final newRefreshToken = dataMap['refresh_token']?.toString() ??
            dataMap['refreshToken']?.toString();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storage.saveAccessToken(newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await storage.saveRefreshToken(newRefreshToken);
          }
          completer.complete(newAccessToken);
          return newAccessToken;
        }
      }

      completer.complete(null);
      return null;
    } on DioException catch (dioErr) {
      // ONLY purge session if the refresh endpoint explicitly returned 401 or 403 (revoked/expired)
      // Network drops, timeouts, socket exceptions, 5xx do NOT purge credentials!
      final statusCode = dioErr.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await storage.clearAll();
        onUnauthorized?.call();
      }
      if (!completer.isCompleted) {
        completer.completeError(dioErr);
      }
      rethrow;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  // GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final opt = options ?? Options();
      if (headers != null) {
        opt.headers = {...?opt.headers, ...headers};
      }
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final opt = options ?? Options();
      if (headers != null) {
        opt.headers = {...?opt.headers, ...headers};
      }
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final opt = options ?? Options();
      if (headers != null) {
        opt.headers = {...?opt.headers, ...headers};
      }
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // PATCH
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final opt = options ?? Options();
      if (headers != null) {
        opt.headers = {...?opt.headers, ...headers};
      }
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final opt = options ?? Options();
      if (headers != null) {
        opt.headers = {...?opt.headers, ...headers};
      }
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
