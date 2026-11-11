import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/courier_info.dart';
import '../providers/orders_list_provider.dart';
import 'shipping_label_pdf.dart';

final courierLabelProvider = FutureProvider.autoDispose.family<CourierLabel, String>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).courierLabel(orderId);
});

/// Fonts for Sinhala names/addresses on the label. Fetched once; offline it
/// falls back to the built-in font rather than failing the label.
Future<List<pw.Font>> _labelFallbackFonts() async {
  try {
    return [await PdfGoogleFonts.notoSansSinhalaRegular()];
  } catch (_) {
    return const [];
  }
}

/// The parcel's label as a 4x6in PDF with the system print and share
/// buttons (printer, WhatsApp, Bluetooth printer apps, save to Files).
class ShippingLabelPage extends ConsumerWidget {
  const ShippingLabelPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final label = ref.watch(courierLabelProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(t.courierLabelTitle)),
      body: label.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              t.labelLoadFailed,
              key: const Key('label-error'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(color: AppColors.muted),
            ),
          ),
        ),
        data: (l) => PdfPreview(
          key: const Key('label-preview'),
          build: (_) async => buildShippingLabelPdf(l, fallback: await _labelFallbackFonts()),
          initialPageFormat: labelFormat,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName: 'label-${l.waybillId}.pdf',
        ),
      ),
    );
  }
}
