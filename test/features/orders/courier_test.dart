import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sribees_new_orders/core/network/api_exceptions.dart';
import 'package:sribees_new_orders/core/providers/core_providers.dart';
import 'package:sribees_new_orders/features/auth/models/admin_user.dart';
import 'package:sribees_new_orders/features/auth/providers/auth_provider.dart';
import 'package:sribees_new_orders/features/orders/label/shipping_label_page.dart';
import 'package:sribees_new_orders/features/orders/label/shipping_label_pdf.dart';
import 'package:sribees_new_orders/features/orders/models/courier_info.dart';
import 'package:sribees_new_orders/features/orders/models/order_detail.dart';
import 'package:sribees_new_orders/features/orders/providers/orders_list_provider.dart';
import 'package:sribees_new_orders/main.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fakes.dart';

late MemoryStorage storage;
late FakeAuthRepository auth;
late FakeOrdersRepository orders;

/// The detail JSON with a courier block of our choosing.
Map<String, dynamic> withCourier(Map<String, dynamic> courier, {String status = 'packed'}) {
  final j = orderDetailJson('1', status: status);
  j['courier'] = {
    'payment_method': 'cod',
    'cod_amount': 1250.0,
    'booking_status': null,
    'shipment_id': null,
    'waybill': null,
    'tracking_status': null,
    'can_request_pickup': false,
    'can_refresh_tracking': false,
    'branch_pickup_registered': true,
    'handover_required': false,
    'cod_collected': false,
    'cod_collected_amount': null,
    ...courier,
  };
  return j;
}

const booked = {
  'shipment_id': 'SXP123456',
  'waybill': 'SXP123456',
  'booking_status': 'booked',
  'tracking_status': 'picked_up',
  'pickup_location_name': 'Matugama outlet',
  'can_refresh_tracking': true,
};

Future<void> openOrder(WidgetTester tester, {Map<String, dynamic>? admin}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final user = AdminUser.fromJson(admin ?? adminJson());
  auth.loginResult = user;
  await storage.saveAccessToken('a');
  await storage.saveRefreshToken('r');
  await storage.saveUserData(jsonEncode(user.toJson()));
  orders.pages = {1: FakeOrdersRepository.pageOf([order('1', status: 'packed')])};
  orders.actions = const [];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(auth),
      ordersRepositoryProvider.overrideWithValue(orders),
    ],
    child: const SribeesNewOrdersApp(),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('SB-1'));
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.descendant(
        of: find.byKey(const Key('order-detail')), matching: find.byType(Scrollable)).first,
  );
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
  });

  group('model', () {
    test('reads the courier block the way the admin web does', () {
      final d = OrderDetail.fromJson(withCourier({
        ...booked,
        'cod_collected': true,
        'cod_collected_amount': 1250.0,
        'handover_required': true,
        'handover_verified': false,
        'failure_note': 'Customer not home',
      }));
      final c = d.courier!;
      expect(c.booked, isTrue);
      expect(c.isCod, isTrue);
      expect(c.codAmount, 1250);
      expect(c.trackingStatus, 'picked_up');
      expect(c.codCollected, isTrue);
      expect(c.handoverRequired, isTrue);
      expect(c.handoverVerified, isFalse);
      expect(c.canRefreshTracking, isTrue);
      expect(c.canRequestPickup, isFalse);
      expect(c.failureNote, 'Customer not home');
    });

    test('the label parses and renders to a PDF', () async {
      final l = CourierLabel.fromJson(FakeOrdersRepository().labelJson);
      expect(l.waybillId, 'SXP123456');
      expect(l.isCod, isTrue);
      expect(l.codAmount, 1250);
      final bytes = await buildShippingLabelPdf(l);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test("the label date is Colombo's, whatever the phone says", () {
      // 20:00 UTC is already the next day in Colombo (+05:30).
      expect(labelDate(DateTime.utc(2026, 11, 10, 20)), '11 Nov 2026');
      expect(labelDate(DateTime.utc(2026, 1, 5, 3)), '05 Jan 2026');
    });
  });

  group('on the order screen', () {
    testWidgets('packed, not booked: request pickup after a confirm that shows the COD', (tester) async {
      orders.detailJson = withCourier({'can_request_pickup': true});
      orders.detailAfterCourier = withCourier(booked, status: 'ready_for_pickup');
      await openOrder(tester);
      await scrollTo(tester, find.byKey(const Key('courier-request-pickup')));
      expect(find.byKey(const Key('courier-label')), findsNothing, reason: 'no waybill, no label');

      await tester.tap(find.byKey(const Key('courier-request-pickup')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rs. 1,250.00'), findsWidgets);
      await tester.tap(find.byKey(const Key('courier-pickup-confirm')));
      await tester.pumpAndSettle();

      expect(orders.courierCalls, ['pickup']);
      expect(find.byKey(const Key('courier-ok')), findsOneWidget);
      await scrollTo(tester, find.byKey(const Key('courier-waybill')));
      expect(find.text('SXP123456'), findsOneWidget);
    });

    testWidgets('a refused booking shows the server\'s reason', (tester) async {
      orders.detailJson = withCourier({'can_request_pickup': true});
      orders.courierError = ApiException(
        message: 'Payment has not been received for this order.',
        statusCode: 400,
        kind: ApiErrorKind.conflict,
      );
      await openOrder(tester);
      await scrollTo(tester, find.byKey(const Key('courier-request-pickup')));
      await tester.tap(find.byKey(const Key('courier-request-pickup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('courier-pickup-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('courier-failed')), findsOneWidget);
      expect(find.text('Payment has not been received for this order.'), findsOneWidget);
    });

    testWidgets('booked: waybill, tracking in Sinhala, refresh, label', (tester) async {
      orders.detailJson = withCourier(booked, status: 'ready_for_pickup');
      await openOrder(tester);
      await scrollTo(tester, find.byKey(const Key('courier-tracking')));
      expect(find.text('Rider අරගෙන ගියා'), findsOneWidget);
      expect(find.text('Matugama outlet'), findsOneWidget);

      await scrollTo(tester, find.byKey(const Key('courier-refresh')));
      await tester.tap(find.byKey(const Key('courier-refresh')));
      await tester.pumpAndSettle();
      expect(orders.courierCalls, ['refresh']);

      orders.labelError = ApiException(message: 'no label', statusCode: 404, kind: ApiErrorKind.notFound);
      await scrollTo(tester, find.byKey(const Key('courier-label')));
      await tester.tap(find.byKey(const Key('courier-label')));
      await tester.pumpAndSettle();
      expect(find.byType(ShippingLabelPage), findsOneWidget);
      expect(find.byKey(const Key('label-error')), findsOneWidget);
    });

    testWidgets('COD collected shows the amount the rider took', (tester) async {
      orders.detailJson = withCourier(
        {...booked, 'tracking_status': 'delivered', 'cod_collected': true, 'cod_collected_amount': 1250.0},
        status: 'delivered',
      );
      await openOrder(tester);
      await scrollTo(tester, find.byKey(const Key('courier-cod-collected')));
      final text = tester.widget<Text>(find.byKey(const Key('courier-cod-collected'))).data;
      expect(text, 'Rs. 1,250.00');
    });

    testWidgets('a read-only role sees the shipment and label, but no buttons that change it', (tester) async {
      orders.detailJson = withCourier({...booked, 'can_request_pickup': true}, status: 'ready_for_pickup');
      await openOrder(tester, admin: adminJson(role: 'customer_support', perms: const ['orders:read']));
      await scrollTo(tester, find.byKey(const Key('courier-label')));
      expect(find.byKey(const Key('courier-request-pickup')), findsNothing);
      expect(find.byKey(const Key('courier-refresh')), findsNothing);
    });
  });
}
