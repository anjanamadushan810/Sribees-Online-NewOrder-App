import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../orders/pages/order_detail_page.dart';
import '../orders/providers/orders_list_provider.dart';
import 'new_order_alert.dart';
import 'push_messaging.dart';
import 'push_registrar.dart';

/// Whether this phone may ring, for Settings.
final alertPermissionProvider = FutureProvider.autoDispose<AlertPermission>((ref) {
  return ref.watch(pushMessagingProvider).permission();
});

/// Lives above the signed-in screens: registers this phone for new-order
/// alerts, keeps that registration current, and reacts to alerts.
///
/// * app closed / in background: the system draws the push with the
///   new_orders channel's ringtone; a tap opens that order here.
/// * app open: FCM draws nothing, so this plays the ringtone, refreshes the
///   list and shows a bar with "View".
class PushAlertsHost extends ConsumerStatefulWidget {
  const PushAlertsHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushAlertsHost> createState() => _PushAlertsHostState();
}

class _PushAlertsHostState extends ConsumerState<PushAlertsHost> {
  final _subs = <StreamSubscription>[];
  AppLifecycleListener? _lifecycle;
  bool _started = false;

  PushMessaging get _messaging => ref.read(pushMessagingProvider);
  PushRegistrar get _registrar => ref.read(pushRegistrarProvider);
  String get _language => ref.read(localeProvider).languageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_started || !mounted || !_messaging.available) return;
    _started = true;

    if (await _messaging.permission() == AlertPermission.notAsked && mounted) {
      final yes = await _askWhy();
      if (yes == true) await _messaging.requestPermission();
      ref.invalidate(alertPermissionProvider);
    }
    if (!mounted) return;
    await _registrar.register(language: _language);

    _subs.add(_messaging.onTokenRefresh.listen(
      (t) => _registrar.register(language: _language, token: t),
    ));
    _subs.add(_messaging.onForegroundAlert.listen(_onForeground));
    _subs.add(_messaging.onAlertOpened.listen(_open));
    // Back from the phone's Settings, or after a spell offline: renew.
    _lifecycle = AppLifecycleListener(onResume: () {
      ref.invalidate(alertPermissionProvider);
      _registrar.register(language: _language);
    });

    final initial = await _messaging.initialAlert();
    if (initial != null) _open(initial);
  }

  Future<bool?> _askWhy() {
    final t = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: Text(t.alertsPermissionTitle),
        content: Text(t.alertsPermissionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.alertsNotNow)),
          FilledButton(
            key: const Key('alerts-allow'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.alertsAllow),
          ),
        ],
      ),
    );
  }

  void _onForeground(NewOrderAlert alert) {
    if (!mounted) return;
    _messaging.playAlertSound();
    HapticFeedback.heavyImpact();
    ref.read(ordersListProvider.notifier).refresh();
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const Key('new-order-bar'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        content: Text(alert.orderNumber.isEmpty
            ? t.newOrderArrivedNoNumber
            : t.newOrderArrived(alert.orderNumber)),
        action: SnackBarAction(label: t.alertView, onPressed: () => _open(alert)),
      ));
  }

  void _open(NewOrderAlert alert) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: alert.orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Language change: the server writes the next alert in the new language.
    ref.listen<Locale>(localeProvider, (prev, next) {
      if (_started && prev?.languageCode != next.languageCode) {
        _registrar.register(language: next.languageCode);
      }
    });
    return widget.child;
  }
}
