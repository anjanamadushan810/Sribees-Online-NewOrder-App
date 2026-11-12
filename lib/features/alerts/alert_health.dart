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
    this.canAskAgain = true,
  });

  /// Android will still show its "allow notifications?" question. False after
  /// a second "no", and always before Android 13 (it never asks there).
  final bool canAskAgain;

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
        canAskAgain: m['canAskAgain'] != false,
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

/// "On කරන්න" for notifications: ask from inside the app. When Android no
/// longer shows the question (it remembers a second "no"; phones before
/// Android 13 never ask) open this app's notification page instead. Two
/// signs that no question was shown, either is enough:
///  * the answer came back faster than a person can read it ([instant]);
///  * Android now says it will not ask again (`canAskAgain` false) -- this
///    also covers a slow phone where the instant "no" took longer.
/// A first "no" from the dialog leaves `canAskAgain` true and is respected.
Future<void> turnOnNotifications(
  PushMessaging messaging, {
  Duration instant = const Duration(milliseconds: 700),
}) async {
  final watch = Stopwatch()..start();
  final answer = await messaging.requestPermission();
  if (answer == AlertPermission.granted) return;
  final fast = watch.elapsed < instant;
  var willAsk = true;
  try {
    willAsk = (await messaging.health()).canAskAgain;
  } catch (_) {}
  if (fast || !willAsk) await messaging.openNotificationSettings();
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
