import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../label/shipping_label_page.dart';
import '../models/courier_info.dart';
import '../models/order_detail.dart';
import '../models/order_status.dart';
import '../providers/order_detail_provider.dart';
import '../providers/orders_list_provider.dart';

String _money(double v) => 'Rs. ${NumberFormat('#,##0.00', 'en').format(v)}';

String trackingLabel(String? status, AppLocalizations t) => switch (status) {
      null => t.trackNone,
      'booked' => t.trackBooked,
      'picked_up' => t.trackPickedUp,
      'in_transit' => t.trackInTransit,
      'out_for_delivery' => t.trackOutForDelivery,
      'delivered' => t.trackDelivered,
      'failed' => t.trackFailed,
      'returned' => t.trackReturned,
      'cancelled' => t.trackCancelled,
      _ => status.replaceAll('_', ' '),
    };

/// The SribeesExpress side of an order, as the admin web's CourierPanel shows
/// it: waybill, tracking, where the rider collects, COD collected, and the
/// pickup / refresh / label buttons. The server decides which buttons exist
/// (`can_request_pickup`, `can_refresh_tracking`); orders:update gates them here
/// too so a read-only role sees none.
class CourierSection extends ConsumerWidget {
  const CourierSection({super.key, required this.order});

  final OrderDetail order;

  static const _pickupKey = 'courier:pickup';
  static const _refreshKey = 'courier:refresh';

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<String> Function(String) call,
    String key,
  ) async {
    final t = AppLocalizations.of(context);
    final (result, message) =
        await ref.read(orderDetailProvider(order.orderId).notifier).courier(call, key);
    if (!context.mounted) return;
    final ok = result is Applied;
    HapticFeedback.mediumImpact();
    // The server's reason (payment not in, what SribeesExpress said) is the
    // only thing that tells the manager what to fix, so it is shown as is.
    final fallback = (result is Refused && result.kind != ApiErrorKind.conflict) ? t.courierFailed : '';
    final text = message.isNotEmpty ? message : fallback;
    if (text.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: Key(ok ? 'courier-ok' : 'courier-failed'),
        content: Text(text),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    if (ok) ref.read(ordersListProvider.notifier).refresh();
  }

  Future<void> _confirmPickup(BuildContext context, WidgetRef ref, CourierInfo c) async {
    final t = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.courierPickupConfirmTitle),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.courierPickupConfirmBody),
          const SizedBox(height: 8),
          Text(
            c.isCod ? '${t.courierRiderCollects}: ${_money(c.codAmount)}' : t.courierPrepaid,
            style: AppTypography.bodyMedium(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700),
          ),
          if (!c.branchPickupRegistered) ...[
            const SizedBox(height: 8),
            Text(t.courierUnregisteredNote, style: AppTypography.bodySmall(color: AppColors.muted)),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(
            key: const Key('courier-pickup-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.courierRequestPickup),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      final repo = ref.read(ordersRepositoryProvider);
      await _run(context, ref, repo.requestPickup, _pickupKey);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = order.courier;
    if (c == null) return const SizedBox.shrink();
    final canUpdate = ref.watch(authProvider.select((a) => a.user?.canUpdateOrders ?? false));
    final applying = ref.watch(orderDetailProvider(order.orderId).select((s) => s.applying));
    final busy = applying != null;

    Widget kv(String k, Widget v) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(k, style: AppTypography.bodySmall(color: AppColors.muted))),
            Expanded(child: v),
          ]),
        );
    Text val(String s, {Key? key, Color? color, bool bold = false}) => Text(
          s,
          key: key,
          style: AppTypography.bodyMedium(color: color ?? AppColors.ink)
              .copyWith(fontWeight: bold ? FontWeight.w700 : null),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (c.bookingFailed && !c.booked)
        Container(
          key: const Key('courier-booking-failed'),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(t.courierBookingFailed, style: AppTypography.bodySmall(color: AppColors.error)),
        ),
      kv(
        c.isCod ? t.courierRiderCollects : '',
        val(c.isCod ? _money(c.codAmount) : t.courierPrepaid, bold: c.isCod, key: const Key('courier-payment')),
      ),
      if (c.booked) ...[
        kv(t.courierWaybill, SelectableText(c.waybill ?? c.shipmentId ?? '', key: const Key('courier-waybill'))),
        kv(t.courierStatus, val(trackingLabel(c.trackingStatus, t), key: const Key('courier-tracking'))),
        if (c.failureNote != null) kv('', val(c.failureNote!, color: AppColors.muted)),
        if (c.pickupLocationName != null) kv(t.courierCollectFrom, val(c.pickupLocationName!)),
        if (c.handoverRequired)
          kv(
            t.courierHandover,
            val(c.handoverVerified == true ? t.courierHandoverDone : t.courierHandoverWaiting,
                color: c.handoverVerified == true ? AppColors.success : AppColors.muted),
          ),
        if (c.isCod && (c.codCollected || c.codCollectedAmount != null))
          kv(
            t.courierCashCollected,
            val(
              c.codCollected
                  ? _money(c.codCollectedAmount ?? c.codAmount)
                  : t.courierCashNotYet,
              key: const Key('courier-cod-collected'),
              color: c.codCollected ? AppColors.success : AppColors.muted,
              bold: c.codCollected,
            ),
          ),
        if ((c.codShortfall ?? 0) > 0)
          kv('', val('${_money(c.codShortfall!)} ${t.courierShortfall}', color: AppColors.error)),
      ] else
        Text(t.courierNotBooked, style: AppTypography.bodySmall(color: AppColors.muted)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (canUpdate && c.canRequestPickup)
          FilledButton.icon(
            key: const Key('courier-request-pickup'),
            onPressed: busy ? null : () => _confirmPickup(context, ref, c),
            icon: applying == _pickupKey
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.local_shipping_outlined),
            label: Text(order.status == OrderStatus.packed ? t.courierRequestPickup : t.courierRetryBooking),
          ),
        if (canUpdate && c.canRefreshTracking)
          OutlinedButton.icon(
            key: const Key('courier-refresh'),
            onPressed: busy
                ? null
                : () => _run(context, ref, ref.read(ordersRepositoryProvider).refreshCourier, _refreshKey),
            icon: applying == _refreshKey
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            label: Text(t.courierRefresh),
          ),
        if (c.booked)
          OutlinedButton.icon(
            key: const Key('courier-label'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ShippingLabelPage(orderId: order.orderId)),
            ),
            icon: const Icon(Icons.print_outlined),
            label: Text(t.courierLabel),
          ),
      ]),
    ]);
  }
}
