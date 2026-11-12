import 'dart:async';

import 'package:sribees_new_orders/features/alerts/alert_health.dart';
import 'package:sribees_new_orders/features/alerts/new_order_alert.dart';
import 'package:sribees_new_orders/features/alerts/push_messaging.dart';
import 'package:sribees_new_orders/features/alerts/push_registrar.dart';

/// Firebase without Firebase: scriptable permission, token and alert streams.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.available = true});

  @override
  bool available;

  AlertPermission current = AlertPermission.notAsked;
  AlertPermission answer = AlertPermission.granted;
  String? currentToken = 'fcm-token-1';
  int requestCalls = 0;
  int deleteTokenCalls = 0;
  int soundCalls = 0;
  NewOrderAlert? launchAlert;

  final tokenRefresh = StreamController<String>.broadcast();
  final foreground = StreamController<NewOrderAlert>.broadcast();
  final opened = StreamController<NewOrderAlert>.broadcast();

  @override
  Future<AlertPermission> permission() async => available ? current : AlertPermission.unavailable;

  @override
  Future<AlertPermission> requestPermission() async {
    requestCalls++;
    if (answerDelay > Duration.zero) await Future<void>.delayed(answerDelay);
    current = answer;
    if (answer == AlertPermission.granted) {
      currentHealth = AlertHealth(
        notificationsOn: true,
        channel: currentHealth.channel,
        backgroundRestricted: currentHealth.backgroundRestricted,
        model: currentHealth.model,
      );
    }
    return current;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
    currentToken = null;
  }

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<NewOrderAlert> get onForegroundAlert => foreground.stream;

  @override
  Stream<NewOrderAlert> get onAlertOpened => opened.stream;

  @override
  Future<NewOrderAlert?> initialAlert() async {
    final a = launchAlert;
    launchAlert = null;
    return a;
  }

  @override
  Future<void> playAlertSound() async => soundCalls++;

  @override
  Future<String> deviceId() async => 'device-1';

  @override
  String get platform => 'android';

  /// What the phone reports (P9); healthy unless a test changes it.
  AlertHealth currentHealth = const AlertHealth(
    notificationsOn: true,
    channel: ChannelState.on,
    backgroundRestricted: false,
    model: 'Fake Phone 1',
  );
  /// Which Settings pages the app opened, in order.
  final openedSettings = <String>[];

  /// How long the "allow notifications?" answer takes. Zero = Android did not
  /// show the question at all.
  Duration answerDelay = Duration.zero;

  @override
  Future<AlertHealth> health() async => currentHealth;

  @override
  Future<void> openNotificationSettings() async => openedSettings.add('notifications');

  @override
  Future<void> openChannelSettings() async => openedSettings.add('channel');

  @override
  Future<void> openBatterySettings() async => openedSettings.add('battery');
}

/// Records what the app told the server.
class FakeStaffDevicesApi implements StaffDevicesApi {
  final registered = <Map<String, String>>[];
  /// The health + version sent with each registration, in the same order.
  final extras = <Map<String, Object?>>[];
  final unregistered = <String>[];
  Object? failWith;

  @override
  Future<void> register({
    required String token,
    required String deviceId,
    required String platform,
    required String language,
    Map<String, Object?> extra = const {},
  }) async {
    if (failWith != null) throw failWith!;
    registered.add({'token': token, 'device_id': deviceId, 'platform': platform, 'language': language});
    extras.add(extra);
  }

  @override
  Future<void> unregister(String deviceId) async {
    if (failWith != null) throw failWith!;
    unregistered.add(deviceId);
  }
}
