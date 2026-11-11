import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import 'new_order_alert.dart';

/// Whether this phone may show alerts.
enum AlertPermission { granted, denied, notAsked, unavailable }

/// The phone's side of new-order alerts. An interface so tests run without
/// Firebase; [FirebasePushMessaging] is the real one.
abstract class PushMessaging {
  /// False when Firebase could not start (no config, tests): everything is a no-op.
  bool get available;

  Future<AlertPermission> permission();
  Future<AlertPermission> requestPermission();

  Future<String?> token();

  /// Drops this install's token at FCM: nothing reaches it any more, even if
  /// the server never heard about the sign-out.
  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  /// Alerts arriving while the app is open (the system draws nothing then).
  Stream<NewOrderAlert> get onForegroundAlert;

  /// Taps on an alert while the app was in the background.
  Stream<NewOrderAlert> get onAlertOpened;

  /// The alert whose tap launched the app from closed, once.
  Future<NewOrderAlert?> initialAlert();

  /// The same ringtone as the notification channel.
  Future<void> playAlertSound();

  /// A stable id for this install of the app (not the hardware).
  Future<String> deviceId();

  String get platform;
}

class FirebasePushMessaging implements PushMessaging {
  static const _channel = MethodChannel('sribees/alerts');

  /// Called once from main() before runApp.
  static Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('Firebase did not start: $e');
      return false;
    }
  }

  @override
  bool get available {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  static AlertPermission _map(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => AlertPermission.granted,
        AuthorizationStatus.notDetermined => AlertPermission.notAsked,
        // denied, deniedPermanently (and anything newer): the phone said no.
        _ => AlertPermission.denied,
      };

  @override
  Future<AlertPermission> permission() async {
    if (!available) return AlertPermission.unavailable;
    return _map((await _fm.getNotificationSettings()).authorizationStatus);
  }

  @override
  Future<AlertPermission> requestPermission() async {
    if (!available) return AlertPermission.unavailable;
    return _map((await _fm.requestPermission()).authorizationStatus);
  }

  @override
  Future<String?> token() async => available ? _fm.getToken() : null;

  @override
  Future<void> deleteToken() async {
    if (available) await _fm.deleteToken();
  }

  @override
  Stream<String> get onTokenRefresh => available ? _fm.onTokenRefresh : const Stream.empty();

  static Stream<NewOrderAlert> _alerts(Stream<RemoteMessage> s) =>
      s.map((m) => NewOrderAlert.fromData(m.data)).where((a) => a != null).cast<NewOrderAlert>();

  @override
  Stream<NewOrderAlert> get onForegroundAlert =>
      available ? _alerts(FirebaseMessaging.onMessage) : const Stream.empty();

  @override
  Stream<NewOrderAlert> get onAlertOpened =>
      available ? _alerts(FirebaseMessaging.onMessageOpenedApp) : const Stream.empty();

  @override
  Future<NewOrderAlert?> initialAlert() async {
    if (!available) return null;
    final m = await _fm.getInitialMessage();
    return m == null ? null : NewOrderAlert.fromData(m.data);
  }

  @override
  Future<void> playAlertSound() async {
    try {
      await _channel.invokeMethod<bool>('playNewOrderSound');
    } catch (_) {
      // No sound is better than a crash.
    }
  }

  @override
  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(AppConstants.prefDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final rnd = Random.secure();
    final id = 'sbno-${List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    await prefs.setString(AppConstants.prefDeviceId, id);
    return id;
  }

  @override
  String get platform {
    try {
      return Platform.isIOS ? 'ios' : 'android';
    } catch (_) {
      return 'android';
    }
  }
}
