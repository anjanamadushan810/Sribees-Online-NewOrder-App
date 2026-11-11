import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/providers/core_providers.dart';
import 'push_messaging.dart';

/// The server side: POST / DELETE /admin/push-tokens.
abstract class StaffDevicesApi {
  Future<void> register({
    required String token,
    required String deviceId,
    required String platform,
    required String language,
  });

  Future<void> unregister(String deviceId);
}

class HttpStaffDevicesApi implements StaffDevicesApi {
  HttpStaffDevicesApi(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<void> register({
    required String token,
    required String deviceId,
    required String platform,
    required String language,
  }) async {
    await apiClient.post(ApiEndpoints.staffPushTokens, data: {
      'token': token,
      'device_id': deviceId,
      'platform': platform,
      'language': language,
    });
  }

  @override
  Future<void> unregister(String deviceId) async {
    await apiClient.delete('${ApiEndpoints.staffPushTokens}/${Uri.encodeComponent(deviceId)}');
  }
}

/// Whether this phone is registered with the server for alerts.
class PushStatus {
  const PushStatus.unknown() : ok = false, reason = null, known = false;
  const PushStatus.ok() : ok = true, reason = null, known = true;
  const PushStatus.failed(this.reason) : ok = false, known = true;

  final bool ok;
  final bool known;
  final String? reason;
}

/// Tells the server which phone to ring, and stops it on sign-out.
class PushRegistrar {
  PushRegistrar({
    required this.messaging,
    required this.api,
    this.retryDelays = const [Duration(seconds: 3), Duration(seconds: 10), Duration(seconds: 30)],
  });

  final PushMessaging messaging;
  final StaffDevicesApi api;

  /// Waits between attempts. A first launch often races Google Play services
  /// for the FCM token; tests pass none.
  final List<Duration> retryDelays;

  /// What the last attempt found, for Settings. A phone that cannot ring must
  /// say so and why -- a silent failure here once looked like "alerts don't
  /// work" with nothing to go on.
  final status = ValueNotifier<PushStatus>(const PushStatus.unknown());

  /// Register this install for the signed-in admin, retrying a few times.
  /// Safe to call again (token refresh, language change, resume): the server
  /// upserts. Returns false when the phone still cannot receive alerts.
  Future<bool> register({required String language, String? token}) async {
    if (!messaging.available) {
      status.value = const PushStatus.failed('Firebase did not start on this phone');
      return false;
    }
    for (var attempt = 0;; attempt++) {
      final result = await _registerOnce(language: language, token: token);
      status.value = result;
      if (result.ok || attempt >= retryDelays.length) return result.ok;
      await Future<void>.delayed(retryDelays[attempt]);
    }
  }

  Future<PushStatus> _registerOnce({required String language, String? token}) async {
    String? t = token;
    if (t == null || t.isEmpty) {
      try {
        t = await messaging.token();
      } catch (e) {
        return PushStatus.failed('FCM token: $e');
      }
    }
    if (t == null || t.isEmpty) return const PushStatus.failed('FCM gave no token');
    try {
      await api.register(
        token: t,
        deviceId: await messaging.deviceId(),
        platform: messaging.platform,
        language: language,
      );
      return const PushStatus.ok();
    } on ApiException catch (e) {
      return PushStatus.failed('Server ${e.statusCode ?? e.kind.name}: ${e.message}');
    } catch (e) {
      return PushStatus.failed('Server: $e');
    }
  }

  /// Sign-out. Both halves are best effort and independent: the server call
  /// fails when the session already expired, and deleting the token at FCM
  /// makes sure this phone stays quiet anyway.
  Future<void> unregister() async {
    if (!messaging.available) return;
    try {
      await api.unregister(await messaging.deviceId());
    } catch (_) {}
    try {
      await messaging.deleteToken();
    } catch (_) {}
  }
}

final pushMessagingProvider = Provider<PushMessaging>((ref) => FirebasePushMessaging());

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  return PushRegistrar(
    messaging: ref.watch(pushMessagingProvider),
    api: HttpStaffDevicesApi(ref.watch(apiClientProvider)),
  );
});
