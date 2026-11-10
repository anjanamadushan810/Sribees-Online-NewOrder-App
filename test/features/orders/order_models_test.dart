import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/core/utils/server_clock.dart';
import 'package:sribees_new_orders/features/orders/models/order_status.dart';
import 'package:sribees_new_orders/features/orders/models/order_summary.dart';
import 'package:sribees_new_orders/features/orders/models/orders_query.dart';
import 'package:sribees_new_orders/features/orders/order_labels.dart';

import '../../helpers/order_fakes.dart';

void main() {
  group('tabs mirror the admin web ORDER_TABS', () {
    List<String> wires(String key) => tabByKey(key).statuses.map((s) => s.wire).toList();

    test('keys and order', () {
      expect(orderTabs.map((t) => t.key),
          ['all', 'new', 'warehouse', 'logistics', 'delivered', 'returns', 'exceptions']);
    });

    test('statuses per tab', () {
      expect(wires('all'), isEmpty);
      expect(wires('new'), ['pending', 'confirmed']);
      expect(wires('warehouse'), ['processing', 'packing', 'packed']);
      expect(wires('logistics'),
          ['ready_for_pickup', 'handed_to_courier', 'shipped', 'out_for_delivery']);
      expect(wires('delivered'), ['delivered']);
      expect(wires('returns'), ['return_requested', 'return_approved', 'return_rejected', 'refunded']);
      expect(wires('exceptions'), ['cancelled', 'delivery_failed', 'rto_initiated']);
    });

    test('Returns badge counts only open claims; All counts everything', () {
      const counts = {'return_requested': 2, 'return_approved': 1, 'refunded': 9, 'pending': 4};
      expect(tabByKey('returns').badge(counts), 3);
      expect(tabByKey('all').badge(counts), 16);
      expect(tabByKey('new').badge(counts), 4);
    });

    test('the default tab is New', () {
      expect(const OrdersQuery().tabKey, 'new');
    });
  });

  group('query parameters', () {
    final now = DateTime.utc(2026, 11, 10, 20, 0); // 01:30 on the 11th in Colombo

    test('tab statuses go as order_statuses; a pill narrows them', () {
      const q = OrdersQuery(tabKey: 'warehouse');
      expect(q.toParams(page: 1, limit: 20, nowUtc: now)['order_statuses'],
          'processing,packing,packed');
      final p = q.copyWith(pillKey: 'packing');
      expect(p.toParams(page: 1, limit: 20, nowUtc: now)['order_statuses'], 'processing,packing');
    });

    test('All sends no status filter and no dates', () {
      final p = const OrdersQuery(tabKey: 'all').toParams(page: 2, limit: 20, nowUtc: now);
      expect(p, {'page': 2, 'limit': 20});
    });

    test('search is trimmed; blank search is not sent', () {
      expect(const OrdersQuery(search: '  SB-12 ').toParams(page: 1, limit: 20, nowUtc: now)['search'],
          'SB-12');
      expect(const OrdersQuery(search: '   ')
          .toParams(page: 1, limit: 20, nowUtc: now)
          .containsKey('search'), isFalse);
    });

    test('dates are Colombo dates, not UTC or the phone zone', () {
      final today = const OrdersQuery(range: DateRangePreset.today)
          .toParams(page: 1, limit: 20, nowUtc: now);
      expect(today['from_date'], '2026-11-11');
      expect(today['to_date'], '2026-11-11');
      final week = const OrdersQuery(range: DateRangePreset.last7)
          .toParams(page: 1, limit: 20, nowUtc: now);
      expect(week['from_date'], '2026-11-05');
    });

    test('changing tab clears the pill', () {
      const q = OrdersQuery(tabKey: 'new', pillKey: 'pending');
      expect(q.copyWith(tabKey: 'warehouse', clearPill: true).pillKey, isNull);
    });
  });

  group('order row', () {
    test('parses the backend row', () {
      final o = OrderSummary.fromJson(orderJson('7', status: 'packed', payment: 'paid', total: 980.5));
      expect(o.status, OrderStatus.packed);
      expect(o.isPaid, isTrue);
      expect(o.totalAmount, 980.5);
      expect(o.createdAt!.isUtc, isTrue);
    });

    test('a status this app does not know stays visible as unknown', () {
      final o = OrderSummary.fromJson(orderJson('8', status: 'on_hold'));
      expect(o.status, OrderStatus.unknown);
      expect(o.rawStatus, 'on_hold');
    });

    test('"Courier not booked" = failed booking with no waybill (admin web rule)', () {
      expect(OrderSummary.fromJson(orderJson('1', booking: 'failed')).courierNotBooked, isTrue);
      expect(OrderSummary.fromJson(orderJson('2', booking: 'failed', waybill: 'W1')).courierNotBooked,
          isFalse);
      expect(OrderSummary.fromJson(orderJson('3', booking: 'booked')).courierNotBooked, isFalse);
    });
  });

  group('waiting time', () {
    final created = DateTime.utc(2026, 11, 10, 8, 0);
    test('amber after 15 min, red after 30, only while waiting for the branch', () {
      expect(waitLevel(OrderStatus.pending, created, created.add(const Duration(minutes: 10))), 0);
      expect(waitLevel(OrderStatus.pending, created, created.add(const Duration(minutes: 16))), 1);
      expect(waitLevel(OrderStatus.confirmed, created, created.add(const Duration(minutes: 31))), 2);
      expect(waitLevel(OrderStatus.packing, created, created.add(const Duration(hours: 5))), 0);
    });
  });

  group('server clock', () {
    test('uses the server Date header, not the phone clock', () {
      final c = ServerClock();
      final phone = DateTime.utc(2026, 11, 10, 8, 0, 0);
      c.syncFromHeader('Tue, 10 Nov 2026 08:10:00 GMT', receivedAt: phone);
      expect(c.isSynced, isTrue);
      final drift = c.now().difference(DateTime.now().toUtc());
      expect(drift.inMinutes, inInclusiveRange(9, 10));
    });

    test('ignores a missing or broken header', () {
      final c = ServerClock();
      c.syncFromHeader(null);
      c.syncFromHeader('yesterday-ish');
      expect(c.isSynced, isFalse);
    });

    test('Colombo date rolls over at 18:30 UTC', () {
      expect(colomboDate(DateTime.utc(2026, 11, 10, 18, 29)), '2026-11-10');
      expect(colomboDate(DateTime.utc(2026, 11, 10, 18, 30)), '2026-11-11');
    });
  });
}
