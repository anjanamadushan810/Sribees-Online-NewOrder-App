import 'package:dio/dio.dart';

/// What went wrong, in a form the UI can turn into a translated sentence.
enum ApiErrorKind {
  offline,
  timeout,
  unauthorized, // 401
  forbidden, // 403
  notFound, // 404
  conflict, // 400/409/422: the server refused the request as sent
  rateLimited, // 429
  server, // 5xx
  cancelled,
  unknown,
}

/// Standardized API exception for Sribees New Orders.
///
/// [message] is the server's own wording (English) for logs and for cases
/// the app has no translation for; screens should prefer [kind].
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final ApiErrorKind kind;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
    ApiErrorKind? kind,
  }) : kind = kind ?? kindForStatus(statusCode);

  static ApiErrorKind kindForStatus(int? status) {
    if (status == null) return ApiErrorKind.unknown;
    if (status == 401) return ApiErrorKind.unauthorized;
    if (status == 403) return ApiErrorKind.forbidden;
    if (status == 404) return ApiErrorKind.notFound;
    if (status == 429) return ApiErrorKind.rateLimited;
    if (status >= 500) return ApiErrorKind.server;
    if (status >= 400) return ApiErrorKind.conflict;
    return ApiErrorKind.unknown;
  }

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your network.',
          statusCode: error.response?.statusCode,
          kind: ApiErrorKind.timeout,
        );

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final resData = error.response?.data;
        return ApiException(
          message: _serverMessage(resData) ?? 'Request failed with status $status',
          statusCode: status,
          data: resData,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          kind: ApiErrorKind.cancelled,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection.',
          kind: ApiErrorKind.offline,
        );

      default:
        return ApiException(
          message: error.message ?? 'An unexpected network error occurred.',
          statusCode: error.response?.statusCode,
          kind: error.response == null ? ApiErrorKind.offline : null,
        );
    }
  }

  /// FastAPI's `detail` (string, {message}, or validation list) or the app's
  /// `{error: {message}}` / `{message}` envelope.
  static String? _serverMessage(dynamic resData) {
    if (resData is! Map) return null;
    final detail = resData['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    if (detail is Map && detail['message'] != null) return detail['message'].toString();
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
      return detail.toString();
    }
    final error = resData['error'];
    if (error is Map && error['message'] != null) return error['message'].toString();
    if (error != null) return error.toString();
    if (resData['message'] != null) return resData['message'].toString();
    return null;
  }

  @override
  String toString() => message;
}
