import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sribees_new_orders/core/network/api_exceptions.dart';
import 'package:sribees_new_orders/core/providers/app_version_provider.dart';
import 'package:sribees_new_orders/core/providers/core_providers.dart';
import 'package:sribees_new_orders/features/alerts/alert_health.dart';
import 'package:sribees_new_orders/features/alerts/new_order_alert.dart';
import 'package:sribees_new_orders/features/alerts/push_messaging.dart';
import 'package:sribees_new_orders/features/alerts/push_registrar.dart';
import 'package:sribees_new_orders/features/auth/providers/auth_provider.dart';
import 'package:sribees_new_orders/features/orders/pages/order_detail_page.dart';
import 'package:sribees_new_orders/features/orders/providers/orders_list_provider.dart';
import 'package:sribees_new_orders/main.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fakes.dart';
import '../../helpers/push_fakes.dart';

void main() {
  group('the push payload', () {
    test('a new-order push becomes an alert', () {
      final a = NewOrderAlert.fromData(
          {'type': 'new_order', 'order_id': 'O-1', 'order_number': 'SB-1', 'branch_id': 'B-1'});
      expect(a!.orderId, 'O-1');
      expect(a.orderNumber, 'SB-1');
      expect(a.branchId, 'B-1');
    });

    test('anything else is ignored', () {
      expect(NewOrderAlert.fromData({'type': 'campaign', 'order_id': 'O-1'}), isNull);
      expect(NewOrderAlert.fromData({'type': 'new_order'}), isNull);
      expect(NewOrderAlert.fromData({'type': 'new_order', 'order_id': 'O-1', 'branch_id': ''})!.branchId,
          isNull);
    });
  });

  group('PushRegistrar', () {
    late FakePushMessaging messaging;
    late FakeStaffDevicesApi api;
    late PushRegistrar registrar;

    setUp(() {
      messaging = FakePushMessaging();
      api = FakeStaffDevicesApi();
      registrar = PushRegistrar(messaging: messaging, api: api, retryDelays: const []);
    });

    test('registers token, install id, platform and language', () async {
      expect(await registrar.register(language: 'si'), isTrue);
      expect(api.registered.single,
          {'token': 'fcm-token-1', 'device_id': 'device-1', 'platform': 'android', 'language': 'si'});
    });

    test('a refreshed token is sent as given', () async {
      await registrar.register(language: 'en', token: 'fcm-token-2');
      expect(api.registered.single['token'], 'fcm-token-2');
    });

    test('no token or no Firebase: nothing is sent', () async {
      messaging.currentToken = null;
      expect(await registrar.register(language: 'si'), isFalse);
      messaging
        ..currentToken = 'x'
        ..available = false;
      expect(await registrar.register(language: 'si'), isFalse);
      expect(api.registered, isEmpty);
    });

    test('offline is not a crash', () async {
      api.failWith = ApiException(message: 'offline', kind: ApiErrorKind.offline);
      expect(await registrar.register(language: 'si'), isFalse);
    });

    test('sign-out deletes the FCM token even when the server call fails', () async {
      api.failWith = ApiException(message: 'expired', statusCode: 401, kind: ApiErrorKind.unauthorized);
      await registrar.unregister();
      expect(messaging.deleteTokenCalls, 1);
    });

    test('a failure is retried and its reason kept for Settings', () async {
      final flaky = _FlakyApi(failures: 2);
      final r = PushRegistrar(
        messaging: messaging,
        api: flaky,
        retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
      );
      expect(await r.register(language: 'si'), isTrue);
      expect(flaky.calls, 3);
      expect(r.status.value.ok, isTrue);

      final dead = PushRegistrar(messaging: messaging, api: _FlakyApi(failures: 99), retryDelays: const []);
      expect(await dead.register(language: 'si'), isFalse);
      expect(dead.status.value.ok, isFalse);
      expect(dead.status.value.reason, contains('Server 503'));
    });

    test('no FCM token is reported, not swallowed', () async {
      messaging.currentToken = null;
      await registrar.register(language: 'si');
      expect(registrar.status.value.reason, 'FCM gave no token');
    });

    test('each registration says whether the phone can ring, and its version', () async {
      final r = PushRegistrar(
        messaging: messaging,
        api: api,
        retryDelays: const [],
        appVersion: () async => '0.8.0+9',
      );
      messaging.currentHealth = const AlertHealth(
        notificationsOn: true,
        channel: ChannelState.off,
        backgroundRestricted: false,
        model: 'Samsung SM-A155F',
      );
      await r.register(language: 'si');
      expect(api.extras.single, {
        'notifications_on': true,
        'channel_state': 'off',
        'background_restricted': false,
        'device_model': 'Samsung SM-A155F',
        'app_version': '0.8.0+9',
      });
    });

    test('sign-out tells the server which install stops', () async {
      await registrar.unregister();
      expect(api.unregistered, ['device-1']);
      expect(messaging.deleteTokenCalls, 1);
    });
  });

  group('turning notifications back on (P9)', () {
    test('Android shows its question and they allow: no Settings trip', () async {
      final m = FakePushMessaging()
        ..current = AlertPermission.denied
        ..answer = AlertPermission.granted
        ..answerDelay = const Duration(milliseconds: 900);
      await turnOnNotifications(m);
      expect(m.requestCalls, 1);
      expect(m.openedSettings, isEmpty);
    });

    test('Android will not ask any more (instant no): open the app\'s notification page', () async {
      final m = FakePushMessaging()
        ..current = AlertPermission.denied
        ..answer = AlertPermission.denied;
      await turnOnNotifications(m);
      expect(m.openedSettings, ['notifications']);
    });

    test('a real "no" from the dialog is respected', () async {
      final m = FakePushMessaging()
        ..current = AlertPermission.denied
        ..answer = AlertPermission.denied
        ..answerDelay = const Duration(milliseconds: 900);
      await turnOnNotifications(m);
      expect(m.openedSettings, isEmpty);
    });

    test('problems come first-to-fix first, the server last', () {
      const h = AlertHealth(notificationsOn: false, channel: ChannelState.silent, backgroundRestricted: true);
      expect(alertProblems(h, const PushStatus.failed('x')), [
        AlertProblem.notificationsOff,
        AlertProblem.channelSilent,
        AlertProblem.batteryRestricted,
        AlertProblem.serverFailed,
      ]);
      expect(alertProblems(AlertHealth.healthy, const PushStatus.unknown()), isEmpty);
    });

    test('the native answer is read safely', () {
      final h = AlertHealth.fromMap(
          {'notifications': true, 'channel': 'silent', 'backgroundRestricted': true, 'model': 'X 1'});
      expect(h.channel, ChannelState.silent);
      expect(h.backgroundRestricted, isTrue);
      expect(AlertHealth.fromMap({}).problems, isEmpty, reason: 'unknown keys never invent a problem');
    });
  });

  group('sign-out stops alerts', () {
    test('manual logout and an expired session both run the hook', () async {
      final storage = MemoryStorage();
      var calls = 0;
      final n = AuthNotifier(
        repository: FakeAuthRepository(storage),
        storage: storage,
        onSignOut: () async => calls++,
        restoreOnStart: false,
      );
      await n.login('a@b.lk', 'pw');
      await n.logout();
      await n.sessionExpired();
      expect(calls, 2);
    });

    test('a failing hook never blocks the sign-out', () async {
      final storage = MemoryStorage();
      final n = AuthNotifier(
        repository: FakeAuthRepository(storage),
        storage: storage,
        onSignOut: () async => throw StateError('boom'),
        restoreOnStart: false,
      );
      await n.login('a@b.lk', 'pw');
      await n.logout();
      expect(storage.data, isEmpty);
    });
  });

  group('in the app', () {
    late MemoryStorage storage;
    late FakePushMessaging messaging;
    late FakeStaffDevicesApi api;
    late FakeOrdersRepository ordersRepo;

    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({});
      storage = MemoryStorage();
      messaging = FakePushMessaging();
      api = FakeStaffDevicesApi();
      ordersRepo = FakeOrdersRepository();
    });

    Future<void> pumpSignedIn(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appVersionProvider.overrideWith((ref) async => '0.5.0+5'),
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(storage)),
          ordersRepositoryProvider.overrideWithValue(ordersRepo),
          pushRegistrarProvider.overrideWithValue(PushRegistrar(messaging: messaging, api: api, retryDelays: const [])),
          pushMessagingProvider.overrideWithValue(messaging),
        ],
        child: const SribeesNewOrdersApp(),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('login-email')), 'nimal@sribees.lk');
      await tester.enterText(find.byKey(const Key('login-password')), 'pw');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('first sign-in explains, asks, then registers in Sinhala', (tester) async {
      await pumpSignedIn(tester);
      expect(find.byKey(const Key('alerts-allow')), findsOneWidget);
      expect(api.registered, isEmpty, reason: 'nothing is sent before the user answers');
      await tester.tap(find.byKey(const Key('alerts-allow')));
      await tester.pumpAndSettle();
      expect(messaging.requestCalls, 1);
      expect(api.registered.single['language'], 'si');
    });

    testWidgets('already allowed: no dialog, straight to registering', (tester) async {
      messaging.current = messaging.answer;
      await pumpSignedIn(tester);
      expect(find.byKey(const Key('alerts-allow')), findsNothing);
      expect(api.registered, hasLength(1));
    });

    testWidgets('an order while the app is open rings, refreshes and offers View', (tester) async {
      messaging.current = messaging.answer;
      await pumpSignedIn(tester);
      final listsBefore = ordersRepo.calls.length;

      messaging.foreground.add(const NewOrderAlert(orderId: 'O-9', orderNumber: 'SB-9'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(messaging.soundCalls, 1);
      expect(ordersRepo.calls.length, greaterThan(listsBefore));
      expect(find.byKey(const Key('new-order-bar')), findsOneWidget);
      expect(find.textContaining('SB-9'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1)); // the bar finishes sliding in
      await tester.tap(find.text('බලන්න'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailPage), findsOneWidget);
    });

    testWidgets('tapping a notification opens that order', (tester) async {
      messaging.current = messaging.answer;
      await pumpSignedIn(tester);
      messaging.opened.add(const NewOrderAlert(orderId: 'O-7', orderNumber: 'SB-7'));
      await tester.pumpAndSettle();
      final page = tester.widget<OrderDetailPage>(find.byType(OrderDetailPage));
      expect(page.orderId, 'O-7');
    });

    testWidgets('a token refresh re-registers the new token', (tester) async {
      messaging.current = messaging.answer;
      await pumpSignedIn(tester);
      messaging.tokenRefresh.add('fcm-token-2');
      await tester.pumpAndSettle();
      expect(api.registered.last['token'], 'fcm-token-2');
    });

    testWidgets('switching to English re-registers so alerts come in English', (tester) async {
      messaging.current = messaging.answer;
      await pumpSignedIn(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('alerts-status')), findsOneWidget);
      await tester.tap(find.byKey(const Key('lang-en')));
      await tester.pumpAndSettle();
      expect(api.registered.last['language'], 'en');
    });

    testWidgets('Settings: blocked alerts get a Turn on button, and the sound can be tested',
        (tester) async {
      messaging
        ..current = AlertPermission.denied
        ..answer = AlertPermission.denied
        ..currentHealth = const AlertHealth(
            notificationsOn: false, channel: ChannelState.on, backgroundRestricted: false);
      await pumpSignedIn(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('alerts-fix-notificationsOff')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('alerts-test-sound')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alerts-test-sound')));
      await tester.pump();
      expect(messaging.soundCalls, 1);
    });

    testWidgets('Settings says when the server does not know this phone, and retries', (tester) async {
      messaging.current = messaging.answer;
      api.failWith = ApiException(message: 'Service unavailable', statusCode: 503, kind: ApiErrorKind.server);
      await pumpSignedIn(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.textContaining('Server 503'), findsOneWidget);
      api.failWith = null;
      final retry = find.byKey(const Key('alerts-fix-serverFailed'));
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(api.registered, isNotEmpty);
      expect(find.byKey(const Key('alerts-fix-serverFailed')), findsNothing);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets('a healthy phone shows no 🔕 in the Orders bar', (tester) async {
      messaging.current = messaging.answer;
      await pumpSignedIn(tester);
      expect(find.byKey(const Key('alerts-off-icon')), findsNothing);
    });

    testWidgets('"Not now", then 🔕 → On කරන්න asks again and the icon goes', (tester) async {
      // A fresh install: notifications not allowed yet.
      messaging.currentHealth = const AlertHealth(
          notificationsOn: false, channel: ChannelState.on, backgroundRestricted: false);
      await pumpSignedIn(tester);
      // First run: the staff member taps "පස්සේ".
      await tester.tap(find.text('පස්සේ'));
      await tester.pumpAndSettle();
      expect(messaging.requestCalls, 0);
      expect(find.byKey(const Key('alerts-off-icon')), findsOneWidget);

      await tester.tap(find.byKey(const Key('alerts-off-icon')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('alerts-fix-sheet')), findsOneWidget);
      // Android shows its question and they allow.
      await tester.tap(find.byKey(const Key('alerts-fix-notificationsOff')));
      await tester.pumpAndSettle();
      expect(messaging.requestCalls, 1);
      expect(messaging.openedSettings, isEmpty, reason: 'the dialog answered, no Settings trip');
      expect(find.text('හරි: අලුත් order එකකට මේ phone එක නාද වෙනවා'), findsOneWidget);
      Navigator.of(tester.element(find.byKey(const Key('alerts-fix-sheet')))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('alerts-off-icon')), findsNothing);
      expect(api.extras.last['notifications_on'], isTrue, reason: 'the server hears it can ring');
    });

    testWidgets('channel silent and battery restricted each open their own Settings page',
        (tester) async {
      messaging
        ..current = messaging.answer
        ..currentHealth = const AlertHealth(
            notificationsOn: true, channel: ChannelState.silent, backgroundRestricted: true);
      await pumpSignedIn(tester);
      await tester.tap(find.byKey(const Key('alerts-off-icon')));
      await tester.pumpAndSettle();
      // First to fix first.
      final channelY = tester.getTopLeft(find.byKey(const Key('alerts-problem-channelSilent'))).dy;
      final batteryY = tester.getTopLeft(find.byKey(const Key('alerts-problem-batteryRestricted'))).dy;
      expect(channelY, lessThan(batteryY));

      await tester.tap(find.byKey(const Key('alerts-fix-channelSilent')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alerts-fix-batteryRestricted')));
      await tester.pumpAndSettle();
      expect(messaging.openedSettings, ['channel', 'battery']);
      expect(api.extras.last['channel_state'], 'silent');
      expect(api.extras.last['background_restricted'], isTrue);
    });

    testWidgets('signing out stops this phone', (tester) async {
      messaging.current = messaging.answer;
      await pumpSignedIn(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('signout')), 200,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('signout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('signout-confirm')));
      await tester.pumpAndSettle();
      expect(api.unregistered, ['device-1']);
      expect(messaging.deleteTokenCalls, 1);
    });
  });
}

class _FlakyApi implements StaffDevicesApi {
  _FlakyApi({required this.failures});
  int failures;
  int calls = 0;

  @override
  Future<void> register({
    required String token,
    required String deviceId,
    required String platform,
    required String language,
    Map<String, Object?> extra = const {},
  }) async {
    calls++;
    if (failures-- > 0) {
      throw ApiException(message: 'Service unavailable', statusCode: 503, kind: ApiErrorKind.server);
    }
  }

  @override
  Future<void> unregister(String deviceId) async {}
}
