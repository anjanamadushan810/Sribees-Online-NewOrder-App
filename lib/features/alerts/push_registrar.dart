import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
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

/// Tells the server which phone to ring, and stops it on sign-out.
class PushRegistrar {
  PushRegistrar({required this.messaging, required this.api});

  final PushMessaging messaging;
  final StaffDevicesApi api;

  /// Register this install for the signed-in admin. Safe to call again (token
  /// refresh, language change): the server upserts. Returns false when the
  /// phone cannot receive alerts (no Firebase, no permission, no token).
  Future<bool> register({required String language, String? token}) async {
    if (!messaging.available) return false;
    try {
      final t = token ?? await messaging.token();
      if (t == null || t.isEmpty) return false;
      await api.register(
        token: t,
        deviceId: await messaging.deviceId(),
        platform: messaging.platform,
        language: language,
      );
      return true;
    } catch (_) {
      // Offline or server trouble: the next resume / token refresh retries.
      return false;
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
