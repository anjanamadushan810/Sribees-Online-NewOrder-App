import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sribees_new_orders/core/network/api_exceptions.dart';
import 'package:sribees_new_orders/core/providers/app_version_provider.dart';
import 'package:sribees_new_orders/core/providers/core_providers.dart';
import 'package:sribees_new_orders/core/utils/server_clock.dart';
import 'package:sribees_new_orders/features/auth/models/admin_user.dart';
import 'package:sribees_new_orders/features/auth/providers/auth_provider.dart';
import 'package:sribees_new_orders/features/orders/providers/orders_list_provider.dart';
import 'package:sribees_new_orders/main.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fakes.dart';

/// A clock fixed at 08:20 UTC on 10 Nov 2026.
class FixedClock extends ServerClock {
  @override
  DateTime now() => DateTime.utc(2026, 11, 10, 8, 20);
}

late MemoryStorage storage;
late FakeAuthRepository auth;
late FakeOrdersRepository orders;

Future<void> pumpSignedIn(WidgetTester tester, {Map<String, dynamic>? admin}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final user = AdminUser.fromJson(admin ?? adminJson());
  auth.loginResult = user;
  await storage.saveAccessToken('a');
  await storage.saveRefreshToken('r');
  await storage.saveUserData(jsonEncode(user.toJson()));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      appVersionProvider.overrideWith((ref) async => '0.3.0+3'),
      secureStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(auth),
      ordersRepositoryProvider.overrideWithValue(orders),
      serverClockProvider.overrideWithValue(FixedClock()),
    ],
    child: const SribeesNewOrdersApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    storage = MemoryStorage();
    auth = FakeAuthRepository(storage);
    orders = FakeOrdersRepository();
  });

  testWidgets('shows waiting orders with NEW dot, age, amount and badges', (tester) async {
    orders.pages = {
      1: FakeOrdersRepository.pageOf([
        order('1', created: DateTime.utc(2026, 11, 10, 8, 15)), // 5 min
        order('2', created: DateTime.utc(2026, 11, 10, 7, 40)), // 40 min -> red
      ]),
    };
    await pumpSignedIn(tester);

    expect(find.text('SB-1'), findsOneWidget);
    expect(find.text('Rs 1,250.00'), findsNWidgets(2));
    expect(find.text('මිනිත්තු 5කට කලින්'), findsOneWidget);
    expect(find.text('මිනිත්තු 40ක් බලන් ඉන්නවා'), findsOneWidget);
    expect(find.byKey(const Key('new-dot')), findsNWidgets(2));
    // New tab badge = pending + confirmed from status_counts
    expect(find.descendant(of: find.byKey(const Key('tab-new')), matching: find.text('3')),
        findsOneWidget);
  });

  testWidgets('opening an order clears its NEW dot on this phone', (tester) async {
    orders.pages = {1: FakeOrdersRepository.pageOf([order('1'), order('2')])};
    await pumpSignedIn(tester);
    await tester.tap(find.text('SB-1'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-dot')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('sbno_seen_orders'), ['1']);
  });

  testWidgets('tabs and pills ask the server for the right statuses', (tester) async {
    await pumpSignedIn(tester);
    await tester.tap(find.byKey(const Key('tab-warehouse')));
    await tester.pumpAndSettle();
    expect(orders.calls.last.query.statuses.map((s) => s.wire), ['processing', 'packing', 'packed']);
    await tester.ensureVisible(find.byKey(const Key('pill-packed')));
    await tester.tap(find.byKey(const Key('pill-packed')));
    await tester.pumpAndSettle();
    expect(orders.calls.last.query.statuses.map((s) => s.wire), ['packed']);
  });

  testWidgets('a branch manager gets no branch filter; a super admin does', (tester) async {
    await pumpSignedIn(tester);
    expect(find.byKey(const Key('branch-filter')), findsNothing);
  });

  testWidgets('super admin sees the branch filter and each card names its branch',
      (tester) async {
    auth.branches = const [matugama, kalutara];
    orders.pages = {1: FakeOrdersRepository.pageOf([order('1')])};
    await pumpSignedIn(tester, admin: adminJson(role: 'super_admin', branchId: null));
    expect(find.byKey(const Key('branch-filter')), findsOneWidget);
    expect(find.text('Matugama'), findsWidgets);

    await tester.tap(find.byKey(const Key('branch-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalutara').last);
    await tester.pumpAndSettle();
    expect(orders.calls.last.query.branchId, 'B-2');
  });

  testWidgets('empty tab says so', (tester) async {
    await pumpSignedIn(tester);
    expect(find.text('මෙතන orders නෑ'), findsOneWidget);
  });

  testWidgets('offline with nothing loaded: reason + retry', (tester) async {
    orders.error = ApiException(message: 'x', kind: ApiErrorKind.offline);
    await pumpSignedIn(tester);
    expect(find.textContaining('Internet සම්බන්ධතාවය නෑ'), findsOneWidget);
    orders.error = null;
    orders.pages = {1: FakeOrdersRepository.pageOf([order('9')])};
    await tester.tap(find.byKey(const Key('orders-retry')));
    await tester.pumpAndSettle();
    expect(find.text('SB-9'), findsOneWidget);
  });

  testWidgets('search waits for typing to stop, then asks the server once', (tester) async {
    await pumpSignedIn(tester);
    final before = orders.calls.length;
    await tester.enterText(find.byKey(const Key('orders-search')), 'SB-1');
    await tester.pump(const Duration(milliseconds: 200));
    expect(orders.calls.length, before);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(orders.calls.length, before + 1);
    expect(orders.calls.last.query.search, 'SB-1');
  });
}
