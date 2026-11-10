import 'dart:async';

import 'package:sribees_new_orders/features/orders/models/order_summary.dart';
import 'package:sribees_new_orders/features/orders/models/orders_query.dart';
import 'package:sribees_new_orders/features/orders/repositories/orders_repository.dart';

Map<String, dynamic> orderJson(
  String id, {
  String status = 'pending',
  String payment = 'pending',
  double total = 1250,
  int items = 3,
  DateTime? created,
  String branch = 'Matugama',
  String? booking,
  String? waybill,
}) =>
    {
      'order_id': id,
      'order_number': 'SB-$id',
      'user_id': 'U-$id',
      'customer_name': 'Customer $id',
      'customer_email': 'c$id@example.com',
      'branch_id': 'B-1',
      'branch_name': branch,
      'status': status,
      'payment_status': payment,
      'total_amount': total,
      'item_count': items,
      'created_at': (created ?? DateTime.utc(2026, 11, 10, 8)).toIso8601String(),
      'courier_booking_status': booking,
      'courier_waybill': waybill,
      'courier_tracking_status': null,
    };

OrderSummary order(String id, {String status = 'pending', DateTime? created}) =>
    OrderSummary.fromJson(orderJson(id, status: status, created: created));

/// Records every call; answers from [pages] keyed by page number.
class FakeOrdersRepository implements OrdersRepository {
  final calls = <({OrdersQuery query, int page})>[];
  Map<int, OrdersPage> pages = {};
  Object? error;

  /// When set, the next call waits for this before answering.
  Completer<void>? gate;

  static OrdersPage pageOf(List<OrderSummary> orders,
          {int page = 1, int totalPages = 1, Map<String, int>? counts}) =>
      OrdersPage(
        orders: orders,
        total: orders.length,
        page: page,
        totalPages: totalPages,
        statusCounts: counts ?? const {'pending': 2, 'confirmed': 1, 'delivered': 5},
      );

  @override
  Future<OrdersPage> list(OrdersQuery query, {required int page, int limit = 20}) async {
    calls.add((query: query, page: page));
    final g = gate;
    if (g != null) {
      gate = null;
      await g.future;
    }
    final e = error;
    if (e != null) throw e;
    return pages[page] ?? pageOf(const []);
  }
}
