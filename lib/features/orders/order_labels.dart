import 'package:intl/intl.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/utils/server_clock.dart';
import '../../l10n/generated/app_localizations.dart';
import 'models/order_detail.dart';
import 'models/order_status.dart';
import 'models/orders_query.dart';

extension OrderStatusLabel on OrderStatus {
  String label(AppLocalizations t, {String raw = ''}) => switch (this) {
        OrderStatus.awaitingPayment => t.statusAwaitingPayment,
        OrderStatus.pending => t.statusPending,
        OrderStatus.confirmed => t.statusConfirmed,
        OrderStatus.processing => t.statusProcessing,
        OrderStatus.packing => t.statusPacking,
        OrderStatus.packed => t.statusPacked,
        OrderStatus.readyForPickup => t.statusReadyForPickup,
        OrderStatus.handedToCourier => t.statusHandedToCourier,
        OrderStatus.shipped => t.statusShipped,
        OrderStatus.outForDelivery => t.statusOutForDelivery,
        OrderStatus.delivered => t.statusDelivered,
        OrderStatus.deliveryFailed => t.statusDeliveryFailed,
        OrderStatus.rtoInitiated => t.statusRtoInitiated,
        OrderStatus.cancelled => t.statusCancelled,
        OrderStatus.returnRequested => t.statusReturnRequested,
        OrderStatus.returnApproved => t.statusReturnApproved,
        OrderStatus.returnRejected => t.statusReturnRejected,
        OrderStatus.refunded => t.statusRefunded,
        // A status this app version does not know yet: show the server's word.
        OrderStatus.unknown => raw.replaceAll('_', ' '),
      };
}

String tabLabel(OrderTab tab, AppLocalizations t) => switch (tab.key) {
      'all' => t.tabAll,
      'new' => t.tabNew,
      'warehouse' => t.tabWarehouse,
      'logistics' => t.tabLogistics,
      'delivered' => t.tabDelivered,
      'returns' => t.tabReturns,
      'exceptions' => t.tabExceptions,
      _ => tab.key,
    };

String pillLabel(OrderPill pill, AppLocalizations t) => switch (pill.key) {
      'packed' => t.pillPackedReady,
      'qc' => t.pillQc,
      // Every other pill is exactly one status: use its name.
      _ => pill.statuses.first.label(t),
    };

String rangeLabel(DateRangePreset r, AppLocalizations t) => switch (r) {
      DateRangePreset.all => t.rangeAll,
      DateRangePreset.today => t.rangeToday,
      DateRangePreset.last7 => t.range7,
      DateRangePreset.last30 => t.range30,
    };

String errorLabel(ApiErrorKind kind, AppLocalizations t) => switch (kind) {
      ApiErrorKind.offline => t.errOffline,
      ApiErrorKind.timeout => t.errTimeout,
      ApiErrorKind.server => t.errServer,
      ApiErrorKind.unauthorized => t.errSessionExpired,
      ApiErrorKind.forbidden => t.errNoOrderAccess,
      _ => t.loadFailed,
    };

/// The server's button label, translated. Keyed by the server's English
/// label (the workflow's single source of truth); unknown labels show as-is.
String actionLabel(StatusAction a, AppLocalizations t) => switch (a.label) {
      'Confirm Order' => t.actConfirmOrder,
      'Cancel Order' => t.actCancelOrder,
      'Start Packing' => t.actStartPacking,
      'Mark as Packed' => t.actMarkPacked,
      'Ready for Courier Pickup' => t.actReadyForPickup,
      'Mark as Shipped' => t.actMarkShipped,
      'Out for Delivery' => t.actOutForDelivery,
      'Mark as Delivered' => t.actMarkDelivered,
      'Delivery Failed' => t.actDeliveryFailed,
      'Reschedule Delivery' => t.actReschedule,
      'Return to Hub / RTO' => t.actRto,
      _ => a.label,
    };

/// Statuses whose transition texts the customer (backend _NOTIFY_STATUSES).
const customerNotifiedStatuses = {
  OrderStatus.readyForPickup,
  OrderStatus.handedToCourier,
  OrderStatus.shipped,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
  OrderStatus.deliveryFailed,
};

String paymentMethodLabel(String? method, AppLocalizations t) => switch (method?.toUpperCase()) {
      'COD' => t.payCod,
      'WALLET' => t.payWallet,
      'MARX_OTHER' || 'MARX_AMEX' => t.payCard,
      'MARX_BANK' => t.payBank,
      null => '',
      _ => method!,
    };

/// "11 Nov, 2:35 PM" in Asia/Colombo, month names in the app language.
String colomboDateTime(DateTime? utc, String locale) {
  if (utc == null) return '';
  return DateFormat('d MMM, h:mm a', locale).format(toColombo(utc));
}

/// "Rs 1,250.00"
String rupees(double amount) => 'Rs ${NumberFormat('#,##0.00', 'en').format(amount)}';

String timeAgo(DateTime? createdUtc, DateTime nowUtc, AppLocalizations t) {
  if (createdUtc == null) return '';
  final d = nowUtc.difference(createdUtc);
  if (d.inMinutes < 1) return t.agoJustNow;
  if (d.inMinutes < 60) return t.agoMinutes(d.inMinutes);
  if (d.inHours < 24) return t.agoHours(d.inHours);
  return t.agoDays(d.inDays);
}

/// How urgent a waiting order looks: 0 calm, 1 amber (>15 min), 2 red (>30).
int waitLevel(OrderStatus status, DateTime? createdUtc, DateTime nowUtc) {
  if (!status.isWaitingForBranch || createdUtc == null) return 0;
  final m = nowUtc.difference(createdUtc).inMinutes;
  if (m > 30) return 2;
  if (m > 15) return 1;
  return 0;
}
