import 'dart:async';

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
    current = answer;
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
}

/// Records what the app told the server.
class FakeStaffDevicesApi implements StaffDevicesApi {
  final registered = <Map<String, String>>[];
  final unregistered = <String>[];
  Object? failWith;

  @override
  Future<void> register({
    required String token,
    required String deviceId,
    required String platform,
    required String language,
  }) async {
    if (failWith != null) throw failWith!;
    registered.add({'token': token, 'device_id': deviceId, 'platform': platform, 'language': language});
  }

  @override
  Future<void> unregister(String deviceId) async {
    if (failWith != null) throw failWith!;
    unregistered.add(deviceId);
  }
}
