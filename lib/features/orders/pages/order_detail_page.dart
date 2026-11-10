import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/contact_links.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order_detail.dart';
import '../models/order_status.dart';
import '../models/order_summary.dart';
import '../order_labels.dart';
import '../providers/order_detail_provider.dart';
import '../widgets/status_chip.dart';

/// Hands a link to the phone's own app (dialer, WhatsApp, Maps); tests swap
/// it out.
typedef LinkLauncher = Future<bool> Function(Uri uri);

final linkLauncherProvider = Provider<LinkLauncher>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId, this.summary});

  final String orderId;

  /// What the list already knew, shown while the full order loads.
  final OrderSummary? summary;

  Future<void> _press(BuildContext context, WidgetRef ref, StatusAction action) async {
    final t = AppLocalizations.of(context);
    final order = ref.read(orderDetailProvider(orderId)).order;
    if (order == null) return;
    final targetName = action.target.label(t, raw: action.targetWire);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ConfirmSheet(
        title: actionLabel(action, t),
        lines: [
          t.confirmMove(order.orderNumber, targetName),
          if (action.target == OrderStatus.readyForPickup) t.courierBookNote,
          if (action.target == OrderStatus.cancelled) t.cancelNote,
          if (customerNotifiedStatuses.contains(action.target)) t.notifyNote,
        ],
        danger: action.isDanger,
      ),
    );
    if (ok != true || !context.mounted) return;

    final result = await ref.read(orderDetailProvider(orderId).notifier).apply(action);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (result) {
      case Applied():
        HapticFeedback.mediumImpact();
        messenger.showSnackBar(SnackBar(
          key: const Key('status-changed'),
          content: Text(t.statusChanged(targetName)),
          backgroundColor: AppColors.success,
        ));
      case Refused(:final message, :final kind):
        HapticFeedback.heavyImpact();
        // A 400 is the state machine explaining itself (often: another phone
        // already moved the order); show its words under ours.
        final why = kind == ApiErrorKind.conflict ? '\n$message' : '\n${errorLabel(kind, t)}';
        messenger.showSnackBar(SnackBar(
          key: const Key('status-failed'),
          content: Text('${t.statusChangeFailed}$why'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
        ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final s = ref.watch(orderDetailProvider(orderId));
    final canUpdate = ref.watch(authProvider.select((a) => a.user?.canUpdateOrders ?? false));
    final order = s.order;

    final title = order?.orderNumber ?? summary?.orderNumber ?? '';

    Widget body;
    if (order == null && s.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (order == null) {
      body = _LoadError(
        message: s.error == ApiErrorKind.forbidden
            ? t.orderOtherBranch
            : s.error == null
                ? t.orderLoadFailed
                : '${t.orderLoadFailed}\n${errorLabel(s.error!, t)}',
        onRetry: s.error == ApiErrorKind.forbidden
            ? null
            : ref.read(orderDetailProvider(orderId).notifier).load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: ref.read(orderDetailProvider(orderId).notifier).load,
        child: _DetailBody(order: order),
      );
    }

    // Read-only roles get no buttons; the server also returns none for them.
    final actions = canUpdate ? s.actions : const <StatusAction>[];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
      bottomNavigationBar: order == null
          ? null
          : _ActionBar(
              order: order,
              actions: actions,
              canUpdate: canUpdate,
              applying: s.applying,
              onPress: (a) => _press(context, ref, a),
            ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.order});
  final OrderDetail order;

  Future<void> _open(BuildContext context, WidgetRef ref, Uri? uri) async {
    if (uri == null) return;
    final ok = await ref.read(linkLauncherProvider)(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).cannotOpen)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final phone = order.customerPhone;

    return ListView(
      key: const Key('order-detail'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // Header
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusChip(status: order.status, raw: order.rawStatus),
                  const Spacer(),
                  if (order.branchName != null)
                    Text(order.branchName!, style: AppTypography.bodySmall(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 8),
              Text(t.placedAt(colomboDateTime(order.createdAt, locale)),
                  style: AppTypography.bodyMedium(color: AppColors.inkSecondary)),
              const SizedBox(height: 14),
              _Stepper(status: order.status),
            ],
          ),
        ),

        // Payment first: COD cash is what the packer must not get wrong.
        _Section(
          title: t.secPayment,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(paymentMethodLabel(order.paymentMethod, t),
                  style: AppTypography.bodyLarge(color: AppColors.ink)),
              if (order.isCod) ...[
                const SizedBox(height: 8),
                Container(
                  key: const Key('cod-amount'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.codToCollect,
                          style: AppTypography.bodySmall(color: AppColors.amberDark)),
                      Text(rupees(order.codAmount),
                          style: AppTypography.priceBig(color: AppColors.ink)),
                    ],
                  ),
                ),
              ] else if (order.isPaid) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(t.paymentPaid, style: AppTypography.bodyMedium(color: AppColors.success)),
                ]),
              ],
            ],
          ),
        ),

        // Customer
        _Section(
          title: t.secCustomer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.customerName ?? order.customerEmail ?? '',
                  style: AppTypography.h3(color: AppColors.ink)),
              if (phone != null) ...[
                const SizedBox(height: 2),
                Text(phone, style: AppTypography.bodyMedium(color: AppColors.inkSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('call-customer'),
                        onPressed: () => _open(context, ref, ContactLinks.tel(phone)),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(t.call),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('whatsapp-customer'),
                        onPressed: () => _open(context, ref, ContactLinks.whatsapp(phone)),
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(t.whatsapp),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Address + slot + note
        if (order.addressLines.isNotEmpty)
          _Section(
            title: t.secAddress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final l in order.addressLines)
                  Text(l, style: AppTypography.bodyMedium(color: AppColors.ink)),
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const Key('open-maps'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => _open(context, ref, ContactLinks.maps(order.addressLines)),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(t.openMaps),
                ),
              ],
            ),
          ),
        if (order.deliverySlotDate != null || order.deliverySlotTime != null)
          _Section(
            title: t.secSlot,
            child: Text(
              [order.deliverySlotDate, order.deliverySlotTime].whereType<String>().join('  ·  '),
              style: AppTypography.bodyMedium(color: AppColors.ink),
            ),
          ),
        if (order.notes != null)
          _Section(
            title: t.secNote,
            child: Text(order.notes!, style: AppTypography.bodyMedium(color: AppColors.ink)),
          ),

        // Items
        _Section(
          title: '${t.secItems} (${order.items.length})',
          child: Column(
            children: [
              for (final it in order.items) _ItemRow(item: it),
              const Divider(height: 24),
              _PriceRow(t.priceSubtotal, order.pricing.subtotal),
              if (order.pricing.shipping > 0) _PriceRow(t.priceDelivery, order.pricing.shipping),
              if (order.pricing.discount > 0)
                _PriceRow(t.priceDiscount, -order.pricing.discount),
              if (order.pricing.wallet > 0) _PriceRow(t.priceWallet, -order.pricing.wallet),
              const SizedBox(height: 4),
              _PriceRow(t.priceTotal, order.pricing.total, bold: true),
            ],
          ),
        ),

        // History
        if (order.history.isNotEmpty)
          _Section(
            title: t.secHistory,
            child: Column(
              children: [
                for (final h in order.history.reversed)
                  _HistoryRow(entry: h, locale: locale),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: AppTypography.bodySmall(color: AppColors.muted)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 52,
              height: 52,
              color: AppColors.borderLight,
              child: item.imageUrl == null
                  ? const Icon(Icons.image_outlined, color: AppColors.muted)
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported_outlined, color: AppColors.muted),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.bodyMedium(color: AppColors.ink)),
                if (item.variant != null)
                  Text(item.variant!, style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
                const SizedBox(height: 2),
                Text(t.qtyTimes(item.quantity, rupees(item.unitPrice)),
                    style: AppTypography.bodySmall(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity big and boxed: it is what the packer counts.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('×${item.quantity}', style: AppTypography.h3(color: AppColors.primary)),
              ),
              const SizedBox(height: 4),
              Text(rupees(item.subtotal), style: AppTypography.bodySmall(color: AppColors.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount, {this.bold = false});
  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = (bold ? AppTypography.bodyLarge : AppTypography.bodyMedium)(
            color: bold ? AppColors.ink : AppColors.inkSecondary)
        .copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.normal);
    final text = amount < 0 ? '- ${rupees(-amount)}' : rupees(amount);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(text, style: style)]),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.locale});
  final HistoryEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: entry.to.tone.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.to.label(t, raw: entry.toRaw),
                    style: AppTypography.bodyMedium(color: AppColors.ink)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('${colomboDateTime(entry.at, locale)}  ·  ${entry.by}',
                    style: AppTypography.bodySmall(color: AppColors.muted)),
                if (entry.note != null)
                  Text(entry.note!, style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Six plain steps of the happy path. Off-path statuses (cancelled, failed,
/// returns) show only their chip above.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.status});
  final OrderStatus status;

  static int? _index(OrderStatus s) => switch (s) {
        OrderStatus.pending => -1,
        OrderStatus.confirmed => 0,
        OrderStatus.processing || OrderStatus.packing => 1,
        OrderStatus.packed => 2,
        OrderStatus.readyForPickup => 3,
        OrderStatus.handedToCourier || OrderStatus.shipped || OrderStatus.outForDelivery => 4,
        OrderStatus.delivered => 5,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final at = _index(status);
    if (at == null) return const SizedBox.shrink();
    final labels = [
      t.stepConfirmed,
      t.stepPacking,
      t.stepPacked,
      t.stepCourier,
      t.stepOnTheWay,
      t.stepDelivered,
    ];
    return Row(
      key: const Key('order-stepper'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                          height: 3,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= at ? AppColors.primary : AppColors.border)),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= at ? AppColors.primary : Colors.white,
                        border: Border.all(
                            color: i <= at ? AppColors.primary : AppColors.border, width: 2),
                      ),
                    ),
                    Expanded(
                      child: Container(
                          height: 3,
                          color: i == labels.length - 1
                              ? Colors.transparent
                              : (i < at ? AppColors.primary : AppColors.border)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppTypography.bodySmall(
                            color: i <= at ? AppColors.ink : AppColors.muted)
                        .copyWith(fontSize: 10, fontWeight: i == at ? FontWeight.w700 : null)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.order,
    required this.actions,
    required this.canUpdate,
    required this.applying,
    required this.onPress,
  });

  final OrderDetail order;
  final List<StatusAction> actions;
  final bool canUpdate;
  final String? applying;
  final ValueChanged<StatusAction> onPress;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primary = actions.where((a) => !a.isDanger).toList();
    final danger = actions.where((a) => a.isDanger).toList();
    final busy = applying != null;

    if (actions.isEmpty) {
      // Quiet ⓘ instead of a warning line (owner's UX tone).
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoIcon(
                key: const Key('no-actions-info'),
                message: canUpdate ? t.noFurtherSteps : t.readOnlyInfo,
              ),
            ],
          ),
        ),
      );
    }

    Widget spinnerOr(StatusAction a, Widget child) => applying == a.targetWire
        ? const SizedBox(
            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
        : child;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in primary)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          key: Key('action-${a.targetWire}'),
                          onPressed: busy ? null : () => onPress(a),
                          child: spinnerOr(a, Text(actionLabel(a, t))),
                        ),
                      ),
                    ),
                    if (a.target == OrderStatus.readyForPickup && !order.branchPickupRegistered)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _InfoIcon(
                          key: const Key('pickup-not-registered'),
                          message: t.pickupNotRegistered,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
              ),
            for (final a in danger)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  key: Key('action-${a.targetWire}'),
                  onPressed: busy ? null : () => onPress(a),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: spinnerOr(a, Text(actionLabel(a, t))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small ⓘ that shows its message only when tapped.
class _InfoIcon extends StatelessWidget {
  const _InfoIcon({super.key, required this.message, this.color = AppColors.muted});
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: message,
      icon: Icon(Icons.info_outline_rounded, color: color),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.title, required this.lines, required this.danger});
  final String title;
  final List<String> lines;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h2(color: danger ? AppColors.error : AppColors.ink)),
            const SizedBox(height: 12),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l, style: AppTypography.bodyMedium(color: AppColors.inkSecondary)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(t.cancel),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      key: const Key('confirm-action'),
                      style: danger
                          ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                          : null,
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(t.yes),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, this.onRetry});
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message,
                key: const Key('order-load-error'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge(color: AppColors.inkSecondary)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
