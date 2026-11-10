import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/order_summary.dart';
import '../order_labels.dart';
import '../widgets/status_chip.dart';

/// P2 stand-in: shows what the list knows. P3 replaces it with the full
/// order and its actions.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.summary});

  final OrderSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(summary.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [StatusChip(status: summary.status, raw: summary.rawStatus)]),
          const SizedBox(height: 16),
          Text(summary.customerName ?? summary.customerEmail ?? '',
              style: AppTypography.h3(color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('${rupees(summary.totalAmount)} · ${t.itemCount(summary.itemCount)}',
              style: AppTypography.bodyLarge(color: AppColors.inkSecondary)),
          const SizedBox(height: 32),
          Text(t.orderDetailsComingSoon,
              style: AppTypography.bodyMedium(color: AppColors.muted)),
        ],
      ),
    );
  }
}
