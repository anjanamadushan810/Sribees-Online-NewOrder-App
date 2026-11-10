import 'package:dio/dio.dart';

/// Standardized API exception model for Sribees Price
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your network.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final resData = error.response?.data;
        String errorMessage = 'Something went wrong';

        if (resData is Map) {
          final detail = resData['detail'];
          if (detail is String && detail.trim().isNotEmpty) {
            errorMessage = detail;
          } else if (detail is Map && detail['message'] != null) {
            errorMessage = detail['message'].toString();
          } else if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first['msg'] != null) {
              final loc = first['loc'] is List ? (first['loc'] as List).join('.') : '';
              errorMessage = loc.isNotEmpty
                  ? '${first['msg']} ($loc)'
                  : first['msg'].toString();
            } else {
              errorMessage = detail.toString();
            }
          } else if (resData['message'] != null) {
            errorMessage = resData['message'].toString();
          } else if (resData['error'] != null) {
            if (resData['error'] is Map && resData['error']['message'] != null) {
              errorMessage = resData['error']['message'].toString();
            } else {
              errorMessage = resData['error'].toString();
            }
          } else {
            errorMessage = 'Request failed with status $status';
          }
        }

        if (status == 401) {
          return ApiException(
            message: 'Session expired. Please log in again.',
            statusCode: 401,
            data: resData,
          );
        } else if (status == 429) {
          int? retryAfter;
          if (resData is Map && resData['error'] is Map && resData['error']['retry_after'] != null) {
            retryAfter = (resData['error']['retry_after'] as num?)?.toInt();
          }
          final waitText = retryAfter != null ? 'Please wait $retryAfter seconds.' : 'Please wait a moment.';
          return ApiException(
            message: 'Too many requests. $waitText',
            statusCode: 429,
            data: resData,
          );
        } else if (status == 403) {
          return ApiException(
            message: errorMessage.isNotEmpty
                ? errorMessage
                : 'You do not have permission for this action.',
            statusCode: 403,
            data: resData,
          );
        } else if (status == 404) {
          return ApiException(
            message: errorMessage.isNotEmpty ? errorMessage : 'Item not found.',
            statusCode: 404,
            data: resData,
          );
        }

        return ApiException(
          message: errorMessage,
          statusCode: status,
          data: resData,
        );

      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled.');

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your Wi-Fi or data.',
        );

      default:
        return ApiException(
          message: error.message ?? 'An unexpected network error occurred.',
          statusCode: error.response?.statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
