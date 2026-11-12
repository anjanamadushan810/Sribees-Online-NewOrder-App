import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_messaging.dart';
import 'push_registrar.dart';

/// The New orders channel as the phone has it.
enum ChannelState { on, silent, off }

/// Why this phone would not ring, in the order they are fixed.
enum AlertProblem { notificationsOff, channelOff, channelSilent, batteryRestricted, serverFailed }

/// What the phone says about its ability to ring (P9).
class AlertHealth {
  const AlertHealth({
    required this.notificationsOn,
    required this.channel,
    required this.backgroundRestricted,
    this.model,
  });

  static const healthy = AlertHealth(
    notificationsOn: true,
    channel: ChannelState.on,
    backgroundRestricted: false,
  );

  /// The app may post notifications at all.
  final bool notificationsOn;

  /// The New orders channel: on, silent (no sound / no pop-up) or off.
  final ChannelState channel;

  /// The phone's battery settings stop the app in the background.
  final bool backgroundRestricted;

  /// "Samsung SM-A155F", for the owner's Staff phones list.
  final String? model;

  factory AlertHealth.fromMap(Map<Object?, Object?> m) => AlertHealth(
        notificationsOn: m['notifications'] != false,
        channel: switch (m['channel']) {
          'off' => ChannelState.off,
          'silent' => ChannelState.silent,
          _ => ChannelState.on,
        },
        backgroundRestricted: m['backgroundRestricted'] == true,
        model: m['model'] as String?,
      );

  /// The phone's own problems, first to fix first.
  List<AlertProblem> get problems => [
        if (!notificationsOn) AlertProblem.notificationsOff,
        if (channel == ChannelState.off) AlertProblem.channelOff,
        if (channel == ChannelState.silent) AlertProblem.channelSilent,
        if (backgroundRestricted) AlertProblem.batteryRestricted,
      ];

  /// What the server stores for the owner's Staff phones list.
  Map<String, Object?> toServer() => {
        'notifications_on': notificationsOn,
        'channel_state': channel.name,
        'background_restricted': backgroundRestricted,
        if (model != null && model!.isNotEmpty) 'device_model': model,
      };
}

/// This phone's health; null when Firebase never started (nothing to fix
/// from here). Refreshed on resume, after a fix and after registering.
final alertHealthProvider = FutureProvider.autoDispose<AlertHealth?>((ref) async {
  final messaging = ref.watch(pushMessagingProvider);
  if (!messaging.available) return null;
  return messaging.health();
});

/// Every reason this phone would stay quiet, including the server not knowing it.
List<AlertProblem> alertProblems(AlertHealth? health, PushStatus server) => [
      ...?health?.problems,
      if (server.known && !server.ok) AlertProblem.serverFailed,
    ];

/// "On කරන්න" for notifications: ask from inside the app; when Android no
/// longer shows the question (it remembers a "no", and phones before Android
/// 13 never ask) the answer comes back at once -- then open this app's
/// notification page instead. A real "no" from the dialog takes the person
/// longer than [instant], and is respected.
Future<void> turnOnNotifications(
  PushMessaging messaging, {
  Duration instant = const Duration(milliseconds: 700),
}) async {
  final watch = Stopwatch()..start();
  final answer = await messaging.requestPermission();
  if (answer == AlertPermission.granted) return;
  if (watch.elapsed < instant) await messaging.openNotificationSettings();
}

/// The fix button for one problem.
Future<void> fixAlertProblem(
  AlertProblem problem, {
  required PushMessaging messaging,
  required PushRegistrar registrar,
  required String language,
}) async {
  switch (problem) {
    case AlertProblem.notificationsOff:
      await turnOnNotifications(messaging);
    case AlertProblem.channelOff:
    case AlertProblem.channelSilent:
      await messaging.openChannelSettings();
    case AlertProblem.batteryRestricted:
      await messaging.openBatterySettings();
    case AlertProblem.serverFailed:
      break;
  }
  // Tell the server where this phone stands now (also the server retry).
  await registrar.register(language: language);
}
