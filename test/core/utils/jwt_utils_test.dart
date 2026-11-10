import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/core/utils/jwt_utils.dart';

void main() {
  group('JwtUtils tests', () {
    String createMockJwt(Map<String, dynamic> payload) {
      final headerStr = jsonEncode({'alg': 'HS256', 'typ': 'JWT'});
      final headerBase64 = base64Url.encode(utf8.encode(headerStr)).replaceAll('=', '');
      final payloadStr = jsonEncode(payload);
      final payloadBase64 = base64Url.encode(utf8.encode(payloadStr)).replaceAll('=', '');
      return '$headerBase64.$payloadBase64.mockSignature';
    }

    test('Decodes payload correctly from valid JWT token', () {
      final token = createMockJwt({
        'sub': 'admin-uuid-123',
        'email': 'admin@sribees.com',
        'is_admin': true,
        'exp': 1800000000,
      });

      final payload = JwtUtils.decodePayload(token);
      expect(payload, isNotNull);
      expect(payload!['sub'], 'admin-uuid-123');
      expect(payload['email'], 'admin@sribees.com');
      expect(payload['is_admin'], isTrue);
      expect(payload['exp'], 1800000000);
    });

    test('Returns null for malformed JWT token', () {
      expect(JwtUtils.decodePayload('not.a.valid.jwt.token'), isNull);
      expect(JwtUtils.decodePayload('invalid'), isNull);
      expect(JwtUtils.decodePayload(''), isNull);
    });

    test('Identifies expired token when exp is in the past', () {
      final pastEpoch = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) - 3600; // 1 hr ago
      final token = createMockJwt({'sub': 'test', 'exp': pastEpoch});

      expect(JwtUtils.isExpired(token), isTrue);
    });

    test('Identifies non-expired token when exp is far in future', () {
      final futureEpoch = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 7200; // 2 hrs future
      final token = createMockJwt({'sub': 'test', 'exp': futureEpoch});

      expect(JwtUtils.isExpired(token), isFalse);
    });

    test('Considers token expired if within threshold seconds buffer', () {
      final soonEpoch = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 30; // Expires in 30s
      final token = createMockJwt({'sub': 'test', 'exp': soonEpoch});

      // Default threshold is 60s, so 30s left should trigger proactive refresh
      expect(JwtUtils.isExpired(token, thresholdSeconds: 60), isTrue);
      // But with 10s threshold, it is still valid
      expect(JwtUtils.isExpired(token, thresholdSeconds: 10), isFalse);
    });

    test('Considers null or empty token as expired', () {
      expect(JwtUtils.isExpired(null), isTrue);
      expect(JwtUtils.isExpired(''), isTrue);
      expect(JwtUtils.isExpired('   '), isTrue);
    });
  });
}
