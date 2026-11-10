import 'dart:convert';

/// JWT Helper utilities for proactive token validation without network calls
class JwtUtils {
  JwtUtils._();

  /// Decode JWT payload map without external dependencies
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payloadStr = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if a JWT token is expired (or close to expiring within [thresholdSeconds])
  static bool isExpired(String? token, {int thresholdSeconds = 60}) {
    if (token == null || token.trim().isEmpty) return true;

    final payload = decodePayload(token);
    if (payload == null || !payload.containsKey('exp')) return true;

    final exp = payload['exp'];
    if (exp is num) {
      final expDateTime = DateTime.fromMillisecondsSinceEpoch(
        (exp * 1000).toInt(),
        isUtc: true,
      );
      final nowUtc = DateTime.now().toUtc();
      return nowUtc.add(Duration(seconds: thresholdSeconds)).isAfter(expDateTime);
    }

    return true;
  }
}
