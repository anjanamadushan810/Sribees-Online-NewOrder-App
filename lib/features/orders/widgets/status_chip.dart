import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/order_status.dart';
import '../order_labels.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.raw = ''});

  final OrderStatus status;
  final String raw;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.tone.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.tone.fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label(t, raw: raw),
        style: AppTypography.badge(color: status.tone.fg),
      ),
    );
  }
}
