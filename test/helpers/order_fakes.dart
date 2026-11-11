import 'dart:async';

import 'package:sribees_new_orders/features/orders/models/courier_info.dart';
import 'package:sribees_new_orders/features/orders/models/order_detail.dart';
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

/// Shape of `GET /admin/orders/{id}` data on the development backend.
Map<String, dynamic> orderDetailJson(
  String id, {
  String status = 'pending',
  String method = 'COD',
  String payment = 'pending',
  bool pickupRegistered = true,
  String? phone = '0771234567',
}) =>
    {
      'order_id': id,
      'order_number': 'SB-$id',
      'status': status,
      'payment_status': payment,
      'payment_method': method,
      'branch_id': 'B-1',
      'branch_name': 'Matugama',
      'created_at': '2026-11-10T08:00:00+00:00',
      'delivery_slot_date': null,
      'delivery_slot_time': null,
      'notes': 'Ring the bell twice',
      'customer': {
        'user_id': 'U-$id',
        'full_name': 'Kamala Silva',
        'email': 'kamala@example.com',
        'phone': phone,
      },
      'delivery_address': {
        'address_line1': '12 Temple Road',
        'address_line2': null,
        'postal_city': 'Matugama',
        'district': 'Kalutara',
        'province': 'Western',
        'postal_code': '12100',
      },
      'items': [
        {
          'order_item_id': 'I-1',
          'product_id': 'P-1',
          'product_name': 'Anchor Milk Powder',
          'variant_name': '400g',
          'product_sku': 'SKU1',
          'product_image': '/uploads/products/p1.png',
          'quantity': 2,
          'unit_price': 500.0,
          'subtotal': 1000.0,
          'is_returnable': true,
        },
      ],
      'pricing': {
        'subtotal': 1000.0,
        'tax_amount': 0.0,
        'shipping_amount': 250.0,
        'discount_amount': 0.0,
        'wallet_deduction': 0.0,
        'cashback_earned': 0.0,
        'total_amount': 1250.0,
      },
      'history': [
        {
          'history_id': 'h1',
          'old_status': null,
          'new_status': 'pending',
          'changed_by': 'Customer',
          'notes': 'Order placed by customer',
          'created_at': '2026-11-10T08:00:00+00:00',
        },
      ],
      'courier': {
        'payment_method': method == 'COD' ? 'cod' : 'prepaid',
        'cod_amount': method == 'COD' ? 1250.0 : 0.0,
        'booking_status': null,
        'waybill': null,
        'can_request_pickup': false,
        'branch_pickup_registered': pickupRegistered,
      },
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

  // ---- detail / actions (P3) ----
  Map<String, dynamic> detailJson = orderDetailJson('1');
  List<Map<String, String>> actions = const [
    {'status': 'confirmed', 'label': 'Confirm Order', 'kind': 'primary'},
    {'status': 'cancelled', 'label': 'Cancel Order', 'kind': 'danger'},
  ];
  Object? detailError;
  Object? updateError;
  final updates = <String>[];

  /// After a successful update, what the server returns next.
  void Function(String status)? onUpdate;

  @override
  Future<OrderDetail> detail(String orderId) async {
    final e = detailError;
    if (e != null) throw e;
    return OrderDetail.fromJson(detailJson);
  }

  @override
  Future<List<StatusAction>> nextActions(String orderId) async =>
      [for (final a in actions) StatusAction.fromJson(a)];

  @override
  Future<void> updateStatus(String orderId, String targetStatus) async {
    updates.add(targetStatus);
    final e = updateError;
    if (e != null) throw e;
    onUpdate?.call(targetStatus);
  }

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

  // ---- courier (P6) ----
  final courierCalls = <String>[];
  Object? courierError;
  String courierMessage = 'Pickup requested';

  /// What the next detail load returns after a successful courier call.
  Map<String, dynamic>? detailAfterCourier;

  Map<String, dynamic> labelJson = {
    'waybill_id': 'SXP123456',
    'order_number': 'SB-1',
    'booked_at': '2026-11-10T08:00:00Z',
    'sender_name': 'Sribees Matugama',
    'sender_phone': '0341234567',
    'recipient_name': 'Kamal Silva',
    'recipient_phone': '0771234567',
    'recipient_address': '12 Temple Rd, Matugama',
    'destination_city': 'Matugama',
    'destination_district': 'Kalutara',
    'postal_code': '12100',
    'weight_kg': '1.20',
    'cod_amount': '1250.00',
    'is_cod': true,
    'delivery_charge': '250.00',
    'item_count': 3,
    'status_name': 'Booked',
    'requires_handover_code': false,
    'tracking_url': null,
  };
  Object? labelError;

  Future<String> _courier(String what) async {
    courierCalls.add(what);
    final e = courierError;
    if (e != null) throw e;
    if (detailAfterCourier != null) detailJson = detailAfterCourier!;
    return courierMessage;
  }

  @override
  Future<String> requestPickup(String orderId) => _courier('pickup');

  @override
  Future<String> refreshCourier(String orderId) => _courier('refresh');

  @override
  Future<CourierLabel> courierLabel(String orderId) async {
    final e = labelError;
    if (e != null) throw e;
    return CourierLabel.fromJson(labelJson);
  }
}
