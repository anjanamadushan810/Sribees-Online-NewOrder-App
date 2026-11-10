import 'order_status.dart';

/// One row of `GET /admin/orders` (`_format_order_row` on the backend).
class OrderSummary {
  final String orderId;
  final String orderNumber;
  final String? customerName;
  final String? customerEmail;
  final String? branchId;
  final String? branchName;
  final OrderStatus status;
  final String rawStatus;
  final String? paymentStatus;
  final double totalAmount;
  final int itemCount;
  final DateTime? createdAt; // UTC
  final String? courierBookingStatus;
  final String? courierWaybill;

  const OrderSummary({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.rawStatus,
    required this.totalAmount,
    required this.itemCount,
    this.customerName,
    this.customerEmail,
    this.branchId,
    this.branchName,
    this.paymentStatus,
    this.createdAt,
    this.courierBookingStatus,
    this.courierWaybill,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isRefunded => paymentStatus == 'refunded';

  /// Same rule as the admin web's red "Not booked" tag: the courier refused
  /// the booking and no waybill exists, so no rider is coming.
  bool get courierNotBooked =>
      courierBookingStatus == 'failed' && (courierWaybill == null || courierWaybill!.isEmpty);

  factory OrderSummary.fromJson(Map<String, dynamic> j) {
    final raw = (j['status'] ?? '').toString();
    return OrderSummary(
      orderId: (j['order_id'] ?? '').toString(),
      orderNumber: (j['order_number'] ?? '').toString(),
      customerName: j['customer_name']?.toString(),
      customerEmail: j['customer_email']?.toString(),
      branchId: j['branch_id']?.toString(),
      branchName: j['branch_name']?.toString(),
      status: OrderStatus.fromWire(raw),
      rawStatus: raw,
      paymentStatus: j['payment_status']?.toString(),
      totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0,
      itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString())?.toUtc(),
      courierBookingStatus: j['courier_booking_status']?.toString(),
      courierWaybill: j['courier_waybill']?.toString(),
    );
  }
}

class OrdersPage {
  final List<OrderSummary> orders;
  final int total;
  final int page;
  final int totalPages;
  final Map<String, int> statusCounts;

  const OrdersPage({
    required this.orders,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.statusCounts,
  });
}
