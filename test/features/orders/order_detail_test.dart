import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sribees_new_orders/core/network/api_exceptions.dart';
import 'package:sribees_new_orders/core/providers/core_providers.dart';
import 'package:sribees_new_orders/core/utils/contact_links.dart';
import 'package:sribees_new_orders/features/auth/models/admin_user.dart';
import 'package:sribees_new_orders/features/auth/providers/auth_provider.dart';
import 'package:sribees_new_orders/features/orders/models/order_detail.dart';
import 'package:sribees_new_orders/features/orders/models/order_status.dart';
import 'package:sribees_new_orders/features/orders/pages/order_detail_page.dart';
import 'package:sribees_new_orders/features/orders/providers/orders_list_provider.dart';
import 'package:sribees_new_orders/main.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fakes.dart';

late MemoryStorage storage;
late FakeAuthRepository auth;
late FakeOrdersRepository orders;
late List<Uri> launched;

/// Signs in (from storage), then opens order 1 from the list.
Future<void> openOrder(WidgetTester tester, {Map<String, dynamic>? admin}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final user = AdminUser.fromJson(admin ?? adminJson());
  auth.loginResult = user;
  await storage.saveAccessToken('a');
  await storage.saveRefreshToken('r');
  await storage.saveUserData(jsonEncode(user.toJson()));
  orders.pages = {1: FakeOrdersRepository.pageOf([order('1')])};
  await tester.pumpWidget(ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(auth),
      ordersRepositoryProvider.overrideWithValue(orders),
      linkLauncherProvider.overrideWithValue((uri) async {
        launched.add(uri);
        return true;
      }),
    ],
    child: const SribeesNewOrdersApp(),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('SB-1'));
  await tester.pumpAndSettle();
}

/// Scroll the order detail until [finder] is built and on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.descendant(
        of: find.byKey(const Key('order-detail')), matching: find.byType(Scrollable)).first,
  );
  // Built is not the same as tappable: lift it clear of the action bar.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    storage = MemoryStorage();
    auth = FakeAuthRepository(storage);
    orders = FakeOrdersRepository();
    launched = [];
  });

  group('model', () {
    test('parses the development backend detail shape', () {
      final d = OrderDetail.fromJson(orderDetailJson('1'));
      expect(d.status, OrderStatus.pending);
      expect(d.isCod, isTrue);
      expect(d.codAmount, 1250);
      expect(d.customerPhone, '0771234567');
      expect(d.addressLines, ['12 Temple Road', 'Matugama 12100', 'Kalutara, Western']);
      expect(d.items.single.variant, '400g');
      expect(d.pricing.shipping, 250);
    });

    test('relative product images resolve against the API host', () {
      expect(resolveMediaUrl('/uploads/p.png', apiBaseUrl: 'https://devapionline.sribees.com/api/v1'),
          'https://devapionline.sribees.com/uploads/p.png');
      expect(resolveMediaUrl('https://cdn.x/p.png'), 'https://cdn.x/p.png');
      expect(resolveMediaUrl(''), isNull);
    });

    test('a prepaid order has nothing to collect', () {
      final d = OrderDetail.fromJson(orderDetailJson('1', method: 'MARX_OTHER', payment: 'paid'));
      expect(d.isCod, isFalse);
      expect(d.codAmount, 0);
      expect(d.isPaid, isTrue);
    });
  });

  group('contact links', () {
    test('Sri Lankan numbers become 94XXXXXXXXX', () {
      expect(ContactLinks.internationalLk('077 123 4567'), '94771234567');
      expect(ContactLinks.internationalLk('+94771234567'), '94771234567');
      expect(ContactLinks.internationalLk('0094771234567'), '94771234567');
      expect(ContactLinks.internationalLk('771234567'), '94771234567');
      expect(ContactLinks.internationalLk(''), isNull);
      expect(ContactLinks.whatsapp('0771234567').toString(), 'https://wa.me/94771234567');
      expect(ContactLinks.tel('0771234567').toString(), 'tel:+94771234567');
    });
  });

  testWidgets('shows what the packer needs: COD cash, items with quantity, address, note',
      (tester) async {
    await openOrder(tester);
    expect(find.byKey(const Key('cod-amount')), findsOneWidget);
    expect(find.text('Rs 1,250.00'), findsWidgets);
    await scrollTo(tester, find.text('12 Temple Road'));
    await scrollTo(tester, find.text('Ring the bell twice'));
    await scrollTo(tester, find.text('Anchor Milk Powder'));
    expect(find.text('×2'), findsOneWidget);
  });

  testWidgets('call / WhatsApp / Maps hand off to the phone', (tester) async {
    await openOrder(tester);
    await tester.tap(find.byKey(const Key('call-customer')));
    await tester.tap(find.byKey(const Key('whatsapp-customer')));
    await scrollTo(tester, find.byKey(const Key('open-maps')));
    await tester.tap(find.byKey(const Key('open-maps')));
    await tester.pump();
    expect(launched.map((u) => u.scheme), ['tel', 'https', 'https']);
    expect(launched[1].host, 'wa.me');
    expect(launched[2].queryParameters['query'], contains('Temple Road'));
  });

  testWidgets('primary button -> confirm -> server called -> new status shown', (tester) async {
    orders.onUpdate = (s) {
      orders.detailJson = orderDetailJson('1', status: s);
      orders.actions = const [
        {'status': 'packing', 'label': 'Start Packing', 'kind': 'primary'},
        {'status': 'cancelled', 'label': 'Cancel Order', 'kind': 'danger'},
      ];
    };
    await openOrder(tester);

    await tester.tap(find.byKey(const Key('action-confirmed')));
    await tester.pumpAndSettle();
    expect(find.text('Order SB-1 "තහවුරුයි" වෙනවා.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-action')));
    await tester.pumpAndSettle();

    expect(orders.updates, ['confirmed']);
    expect(find.byKey(const Key('status-changed')), findsOneWidget);
    expect(find.byKey(const Key('action-packing')), findsOneWidget);
    expect(find.text('පැක් කරන්න පටන් ගන්න'), findsOneWidget);
  });

  testWidgets('backing out of the confirm sheet changes nothing', (tester) async {
    await openOrder(tester);
    await tester.tap(find.byKey(const Key('action-cancelled')));
    await tester.pumpAndSettle();
    expect(find.textContaining('stock එක ආපහු'), findsOneWidget);
    await tester.tap(find.text('එපා'));
    await tester.pumpAndSettle();
    expect(orders.updates, isEmpty);
  });

  testWidgets('"ready for pickup" warns that it books the courier', (tester) async {
    orders.detailJson = orderDetailJson('1', status: 'packed', pickupRegistered: false);
    orders.actions = const [
      {'status': 'ready_for_pickup', 'label': 'Ready for Courier Pickup', 'kind': 'primary'},
    ];
    await openOrder(tester);
    expect(find.byKey(const Key('pickup-not-registered')), findsOneWidget);
    await tester.tap(find.byKey(const Key('action-ready_for_pickup')));
    await tester.pumpAndSettle();
    expect(find.textContaining('SribeesExpress rider'), findsOneWidget);
    expect(find.textContaining('පණිවිඩයක් යනවා'), findsOneWidget);
  });

  testWidgets('server refuses (another phone moved it): reason shown, screen reloaded',
      (tester) async {
    orders.updateError = ApiException(
      message: "Cannot move an order from 'packing' to 'confirmed'.",
      statusCode: 400,
    );
    await openOrder(tester);
    await tester.tap(find.byKey(const Key('action-confirmed')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('status-failed')), findsOneWidget);
    expect(find.textContaining("from 'packing'"), findsOneWidget);
  });

  testWidgets('a role without orders:update sees no buttons, only a quiet ⓘ', (tester) async {
    await openOrder(tester, admin: adminJson(role: 'staff', perms: ['orders:read']));
    expect(find.byKey(const Key('action-confirmed')), findsNothing);
    expect(find.byKey(const Key('no-actions-info')), findsOneWidget);
    expect(find.textContaining('බලන්න විතරයි'), findsNothing); // hidden until tapped
    await tester.tap(find.byKey(const Key('no-actions-info')));
    await tester.pumpAndSettle();
    expect(find.textContaining('බලන්න විතරයි'), findsOneWidget);
  });

  testWidgets('another branch\'s order (403) says so, with no retry', (tester) async {
    orders.detailError = ApiException(message: 'x', statusCode: 403);
    await openOrder(tester);
    expect(find.text('මේ order එක වෙන ශාඛාවක එකක්.'), findsOneWidget);
    expect(find.text('ආයෙ උත්සාහ කරන්න'), findsNothing);
  });
}
