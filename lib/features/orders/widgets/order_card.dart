import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/order_status.dart';
import '../models/order_summary.dart';
import '../order_labels.dart';
import 'status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.nowUtc,
    required this.isNew,
    required this.showBranch,
    required this.onTap,
  });

  final OrderSummary order;
  final DateTime nowUtc;
  final bool isNew;
  final bool showBranch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final level = waitLevel(order.status, order.createdAt, nowUtc);
    final waitColor = switch (level) {
      2 => AppColors.error,
      1 => AppColors.warning,
      _ => AppColors.muted,
    };
    final waited = order.createdAt == null ? 0 : nowUtc.difference(order.createdAt!).inMinutes;

    return Card(
      key: Key('order-${order.orderId}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: level == 2
              ? AppColors.error.withValues(alpha: 0.5)
              : level == 1
                  ? AppColors.warning.withValues(alpha: 0.6)
                  : AppColors.border,
          width: level > 0 ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isNew) ...[
                    Container(
                      key: const Key('new-dot'),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: AppTypography.h3(color: AppColors.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(status: order.status, raw: order.rawStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.customerName?.isNotEmpty == true
                    ? order.customerName!
                    : (order.customerEmail ?? ''),
                style: AppTypography.bodyMedium(color: AppColors.inkSecondary),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Wrap, not Row: Sinhala labels are long and phones are narrow.
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(rupees(order.totalAmount),
                      style: AppTypography.bodyLarge(color: AppColors.ink)
                          .copyWith(fontWeight: FontWeight.w700)),
                  // An unpaid card order is not COD: its status chip already
                  // says "awaiting payment".
                  if (order.status != OrderStatus.awaitingPayment) _PaymentTag(order: order),
                  Text(t.itemCount(order.itemCount),
                      style: AppTypography.bodySmall(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _IconText(
                    icon: level > 0 ? Icons.timer_outlined : Icons.schedule_rounded,
                    color: waitColor,
                    text: level > 0 ? t.waitingTooLong(waited) : timeAgo(order.createdAt, nowUtc, t),
                    textKey: const Key('order-age'),
                    bold: level > 0,
                  ),
                  if (showBranch && order.branchName != null)
                    _IconText(
                      icon: Icons.storefront_outlined,
                      color: AppColors.muted,
                      text: order.branchName!,
                    ),
                  if (order.courierNotBooked)
                    _IconText(
                      key: const Key('courier-not-booked'),
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.error,
                      text: t.courierNotBooked,
                      bold: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.textKey,
    this.bold = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Key? textKey;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            key: textKey,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall(color: color)
                .copyWith(fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
          ),
        ),
      ],
    );
  }
}

class _PaymentTag extends StatelessWidget {
  const _PaymentTag({required this.order});
  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (text, fg, bg) = order.isPaid
        ? (t.paymentPaid, AppColors.success, AppColors.successBg)
        : order.isRefunded
            ? (t.paymentRefunded, AppColors.inkSecondary, AppColors.borderLight)
            : (t.paymentCod, AppColors.amberDark, AppColors.amberLight);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: AppTypography.badge(color: fg)),
    );
  }
}
