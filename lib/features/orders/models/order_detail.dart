import '../../../core/config/app_env.dart';
import 'courier_info.dart';
import 'order_status.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
DateTime? _t(Object? v) => v == null ? null : DateTime.tryParse(v.toString())?.toUtc();
String? _s(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// Product images arrive either absolute (old S3 rows) or as a relative
/// `/uploads/...` path: resolve the latter against this build's API host.
String? resolveMediaUrl(String? path, {String? apiBaseUrl}) {
  final p = path?.trim();
  if (p == null || p.isEmpty) return null;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  final base = Uri.parse(apiBaseUrl ?? AppEnv.current.apiBaseUrl);
  final origin = '${base.scheme}://${base.authority}';
  return p.startsWith('/') ? '$origin$p' : '$origin/$p';
}

class OrderItem {
  final String id;
  final String name;
  final String? variant;
  final String? sku;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.variant,
    this.sku,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: (j['order_item_id'] ?? '').toString(),
        name: (j['product_name'] ?? '').toString(),
        variant: _s(j['variant_name']),
        sku: _s(j['product_sku']),
        imageUrl: resolveMediaUrl(_s(j['product_image'])),
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: _d(j['unit_price']),
        subtotal: _d(j['subtotal']),
      );
}

class HistoryEntry {
  final OrderStatus? from;
  final OrderStatus to;
  final String toRaw;
  final String by;
  final String? note;
  final DateTime? at;

  const HistoryEntry({
    required this.to,
    required this.toRaw,
    required this.by,
    this.from,
    this.note,
    this.at,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        from: j['old_status'] == null ? null : OrderStatus.fromWire(j['old_status'].toString()),
        to: OrderStatus.fromWire(j['new_status']?.toString()),
        toRaw: (j['new_status'] ?? '').toString(),
        by: (j['changed_by'] ?? 'System').toString(),
        note: _s(j['notes']),
        at: _t(j['created_at']),
      );
}

class Pricing {
  final double subtotal;
  final double shipping;
  final double discount;
  final double wallet;
  final double total;

  const Pricing({
    this.subtotal = 0,
    this.shipping = 0,
    this.discount = 0,
    this.wallet = 0,
    this.total = 0,
  });

  factory Pricing.fromJson(Map<String, dynamic> j) => Pricing(
        subtotal: _d(j['subtotal']),
        shipping: _d(j['shipping_amount']),
        discount: _d(j['discount_amount']),
        wallet: _d(j['wallet_deduction']),
        total: _d(j['total_amount']),
      );
}

/// `GET /admin/orders/{id}` -> data (`_format_order_detail` + courier block).
class OrderDetail {
  final String orderId;
  final String orderNumber;
  final OrderStatus status;
  final String rawStatus;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? branchName;
  final DateTime? createdAt;
  final String? deliverySlotDate;
  final String? deliverySlotTime;
  final String? notes;

  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  final List<String> addressLines;

  final List<OrderItem> items;
  final Pricing pricing;
  final List<HistoryEntry> history;

  // Courier block (only what the branch acts on in P3)
  final bool isCod;
  final double codAmount;
  final bool branchPickupRegistered;
  final String? courierWaybill;
  final String? courierBookingStatus;

  /// The whole courier block (P6: pickup, tracking, label, COD collected).
  final CourierInfo? courier;

  const OrderDetail({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.rawStatus,
    this.paymentStatus,
    this.paymentMethod,
    this.branchName,
    this.createdAt,
    this.deliverySlotDate,
    this.deliverySlotTime,
    this.notes,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.addressLines = const [],
    this.items = const [],
    this.pricing = const Pricing(),
    this.history = const [],
    this.isCod = false,
    this.codAmount = 0,
    this.branchPickupRegistered = true,
    this.courierWaybill,
    this.courierBookingStatus,
    this.courier,
  });

  bool get isPaid => paymentStatus == 'paid';

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    final customer = j['customer'] is Map ? Map<String, dynamic>.from(j['customer']) : null;
    final addr = j['delivery_address'] is Map ? Map<String, dynamic>.from(j['delivery_address']) : null;
    final courier = j['courier'] is Map ? Map<String, dynamic>.from(j['courier']) : const {};
    final rawStatus = (j['status'] ?? '').toString();
    final method = _s(j['payment_method']);
    final cod = courier['payment_method'] == 'cod' || method?.toUpperCase() == 'COD';

    final lines = <String>[];
    if (addr != null) {
      for (final k in ['address_line1', 'address_line2']) {
        final v = _s(addr[k]);
        if (v != null) lines.add(v);
      }
      final city = [_s(addr['postal_city']), _s(addr['postal_code'])].whereType<String>().join(' ');
      if (city.isNotEmpty) lines.add(city);
      final region = [_s(addr['district']), _s(addr['province'])].whereType<String>().join(', ');
      if (region.isNotEmpty) lines.add(region);
    }

    final history = [
      if (j['history'] is List)
        for (final h in j['history'] as List)
          if (h is Map) HistoryEntry.fromJson(Map<String, dynamic>.from(h)),
    ]..sort((a, b) => (a.at ?? DateTime(0)).compareTo(b.at ?? DateTime(0)));

    return OrderDetail(
      orderId: (j['order_id'] ?? '').toString(),
      orderNumber: (j['order_number'] ?? '').toString(),
      status: OrderStatus.fromWire(rawStatus),
      rawStatus: rawStatus,
      paymentStatus: _s(j['payment_status']),
      paymentMethod: method,
      branchName: _s(j['branch_name']),
      createdAt: _t(j['created_at']),
      deliverySlotDate: _s(j['delivery_slot_date']),
      deliverySlotTime: _s(j['delivery_slot_time']),
      notes: _s(j['notes']),
      customerName: _s(customer?['full_name']),
      customerEmail: _s(customer?['email']),
      customerPhone: _s(customer?['phone']) ?? _s(j['customer_phone']),
      addressLines: lines,
      items: [
        if (j['items'] is List)
          for (final it in j['items'] as List)
            if (it is Map) OrderItem.fromJson(Map<String, dynamic>.from(it)),
      ],
      pricing: j['pricing'] is Map
          ? Pricing.fromJson(Map<String, dynamic>.from(j['pricing']))
          : const Pricing(),
      history: history,
      isCod: cod,
      codAmount: cod ? (_d(courier['cod_amount']) > 0 ? _d(courier['cod_amount']) : _d(j['pricing']?['total_amount'])) : 0,
      branchPickupRegistered: courier['branch_pickup_registered'] != false,
      courierWaybill: _s(courier['waybill']),
      courierBookingStatus: _s(courier['booking_status']),
      courier: j['courier'] is Map ? CourierInfo.fromJson(Map<String, dynamic>.from(courier)) : null,
    );
  }
}

/// One contextual button from `GET /admin/orders/{id}/next-statuses`.
class StatusAction {
  final String targetWire;
  final OrderStatus target;

  /// The server's English label (single source of truth; translated in UI).
  final String label;

  /// "primary" (happy path) or "danger" (cancel / failure path).
  final String kind;

  const StatusAction({
    required this.targetWire,
    required this.target,
    required this.label,
    required this.kind,
  });

  bool get isDanger => kind == 'danger';

  factory StatusAction.fromJson(Map<String, dynamic> j) {
    final wire = (j['status'] ?? '').toString();
    return StatusAction(
      targetWire: wire,
      target: OrderStatus.fromWire(wire),
      label: (j['label'] ?? wire).toString(),
      kind: (j['kind'] ?? 'primary').toString(),
    );
  }
}
