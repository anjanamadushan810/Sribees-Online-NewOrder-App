import 'package:flutter/material.dart';

/// Order statuses as the backend spells them, in lifecycle order, with the
/// admin web's colours (ORDER_STATUS_META, Ant Design tag palette).
enum OrderStatus {
  awaitingPayment('awaiting_payment', _grey),
  pending('pending', _gold),
  confirmed('confirmed', _blue),
  processing('processing', _geekblue),
  packing('packing', _geekblue),
  packed('packed', _lime),
  readyForPickup('ready_for_pickup', _blue),
  handedToCourier('handed_to_courier', _cyan),
  shipped('shipped', _cyan),
  outForDelivery('out_for_delivery', _purple),
  delivered('delivered', _green),
  deliveryFailed('delivery_failed', _volcano),
  rtoInitiated('rto_initiated', _orange),
  cancelled('cancelled', _red),
  returnRequested('return_requested', _orange),
  returnApproved('return_approved', _gold),
  returnRejected('return_rejected', _red),
  refunded('refunded', _volcano),
  unknown('', _grey);

  const OrderStatus(this.wire, this.tone);

  final String wire;
  final StatusTone tone;

  static OrderStatus fromWire(String? v) => OrderStatus.values.firstWhere(
        (s) => s != OrderStatus.unknown && s.wire == v,
        orElse: () => OrderStatus.unknown,
      );

  /// Waiting for the branch to start: the "how long has this waited" clock
  /// turns amber, then red.
  bool get isWaitingForBranch => this == pending || this == confirmed;
}

class StatusTone {
  final Color fg;
  final Color bg;
  const StatusTone(this.fg, this.bg);
}

const _grey = StatusTone(Color(0xFF595959), Color(0xFFF5F5F5));
const _gold = StatusTone(Color(0xFFD48806), Color(0xFFFFFBE6));
const _blue = StatusTone(Color(0xFF0958D9), Color(0xFFE6F4FF));
const _geekblue = StatusTone(Color(0xFF1D39C4), Color(0xFFF0F5FF));
const _lime = StatusTone(Color(0xFF7CB305), Color(0xFFFCFFE6));
const _cyan = StatusTone(Color(0xFF08979C), Color(0xFFE6FFFB));
const _purple = StatusTone(Color(0xFF531DAB), Color(0xFFF9F0FF));
const _green = StatusTone(Color(0xFF389E0D), Color(0xFFF6FFED));
const _volcano = StatusTone(Color(0xFFD4380D), Color(0xFFFFF2E8));
const _orange = StatusTone(Color(0xFFD46B08), Color(0xFFFFF7E6));
const _red = StatusTone(Color(0xFFCF1322), Color(0xFFFFF1F0));

/// A sub-filter inside a tab (admin web "pill").
class OrderPill {
  final String key;
  final List<OrderStatus> statuses;
  const OrderPill(this.key, this.statuses);
}

/// A list tab, mirroring the admin web's ORDER_TABS exactly.
class OrderTab {
  final String key;

  /// Empty = every status ("All").
  final List<OrderStatus> statuses;

  /// When set, the badge counts only these (Returns counts open claims).
  final List<OrderStatus>? badgeStatuses;
  final List<OrderPill> pills;

  const OrderTab(this.key, this.statuses, {this.badgeStatuses, this.pills = const []});

  int badge(Map<String, int> counts) => sumCounts(counts, badgeStatuses ?? statuses);
}

int sumCounts(Map<String, int> counts, List<OrderStatus> statuses) {
  if (statuses.isEmpty) return counts.values.fold(0, (a, b) => a + b);
  return statuses.fold(0, (a, s) => a + (counts[s.wire] ?? 0));
}

const orderTabs = <OrderTab>[
  OrderTab('all', []),
  OrderTab('new', [OrderStatus.pending, OrderStatus.confirmed], pills: [
    OrderPill('pending', [OrderStatus.pending]),
    OrderPill('confirmed', [OrderStatus.confirmed]),
  ]),
  OrderTab('warehouse', [OrderStatus.processing, OrderStatus.packing, OrderStatus.packed], pills: [
    OrderPill('packing', [OrderStatus.processing, OrderStatus.packing]),
    OrderPill('packed', [OrderStatus.packed]),
  ]),
  OrderTab('logistics', [
    OrderStatus.readyForPickup,
    OrderStatus.handedToCourier,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
  ], pills: [
    OrderPill('awaiting', [OrderStatus.readyForPickup]),
    OrderPill('handed', [OrderStatus.handedToCourier]),
    OrderPill('shipped', [OrderStatus.shipped]),
    OrderPill('ofd', [OrderStatus.outForDelivery]),
  ]),
  OrderTab('delivered', [OrderStatus.delivered]),
  OrderTab('returns', [
    OrderStatus.returnRequested,
    OrderStatus.returnApproved,
    OrderStatus.returnRejected,
    OrderStatus.refunded,
  ], badgeStatuses: [
    OrderStatus.returnRequested,
    OrderStatus.returnApproved,
  ], pills: [
    OrderPill('requested', [OrderStatus.returnRequested]),
    OrderPill('qc', [OrderStatus.returnApproved]),
    OrderPill('rejected', [OrderStatus.returnRejected]),
    OrderPill('refunded', [OrderStatus.refunded]),
  ]),
  OrderTab('exceptions', [
    OrderStatus.cancelled,
    OrderStatus.deliveryFailed,
    OrderStatus.rtoInitiated,
  ], pills: [
    OrderPill('cancelled', [OrderStatus.cancelled]),
    OrderPill('failed', [OrderStatus.deliveryFailed]),
    OrderPill('rto', [OrderStatus.rtoInitiated]),
  ]),
];

/// The tab staff land on: orders waiting for them.
const defaultTabKey = 'new';

OrderTab tabByKey(String key) =>
    orderTabs.firstWhere((t) => t.key == key, orElse: () => orderTabs.first);
