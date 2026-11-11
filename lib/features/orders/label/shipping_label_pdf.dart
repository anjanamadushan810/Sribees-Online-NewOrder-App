import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/courier_info.dart';

/// 4 x 6 in, the thermal label size; prints fine on A4 too. Same layout as
/// the admin web's ShippingLabel: destination first and largest (a sorter
/// reads it off a moving belt), the waybill as Code 128, COD boxed.
final PdfPageFormat labelFormat = PdfPageFormat(4 * PdfPageFormat.inch, 6 * PdfPageFormat.inch,
    marginAll: 0.15 * PdfPageFormat.inch);

String _money(double v) => 'Rs. ${NumberFormat('#,##0.00', 'en').format(v)}';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "10 Nov 2026" in Colombo time. Built by hand: DateFormat needs locale data
/// the app only loads for its UI language, and a label must never fail on it.
String labelDate(DateTime at) {
  final c = at.toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${c.day.toString().padLeft(2, '0')} ${_months[c.month - 1]} ${c.year}';
}

/// [fallback] fonts (e.g. Noto Sans Sinhala) cover a customer's name or
/// address written in Sinhala; without them those glyphs print as boxes.
Future<Uint8List> buildShippingLabelPdf(CourierLabel l, {List<pw.Font> fallback = const []}) async {
  final doc = pw.Document(
    title: 'Label ${l.waybillId}',
    theme: pw.ThemeData.withFont(fontFallback: fallback),
  );
  final booked = l.bookedAt == null ? '' : labelDate(l.bookedAt!);

  pw.Widget row(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 60, child: pw.Text(k, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
          pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 10))),
        ]),
      );

  doc.addPage(pw.Page(
    pageFormat: labelFormat,
    build: (ctx) => pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 2))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('SRIBEES EXPRESS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(l.orderNumber, style: const pw.TextStyle(fontSize: 9)),
              if (booked.isNotEmpty) pw.Text(booked, style: const pw.TextStyle(fontSize: 9)),
            ]),
          ]),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: l.waybillId,
            height: 56,
            drawText: true,
            textStyle: const pw.TextStyle(fontSize: 10),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: 1), bottom: pw.BorderSide(width: 1)),
          ),
          child: pw.Column(children: [
            pw.Text(l.destinationCity ?? l.destinationDistrict ?? '-',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
            if (l.destinationCity != null && l.destinationDistrict != null)
              pw.Text('${l.destinationDistrict} District', style: const pw.TextStyle(fontSize: 9)),
          ]),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('DELIVER TO', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text(l.recipientName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(l.recipientAddress, style: const pw.TextStyle(fontSize: 10)),
            pw.Text(l.recipientPhone, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
        ),
        if (l.isCod)
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
            child: pw.Column(children: [
              pw.Text('COLLECT ON DELIVERY', style: const pw.TextStyle(fontSize: 8, letterSpacing: 1)),
              pw.Text(_money(l.codAmount), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
        if (l.requiresHandoverCode)
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1, style: pw.BorderStyle.dashed)),
            child: pw.Center(
              child: pw.Text("RIDER MUST COLLECT THE CUSTOMER'S HANDOVER CODE",
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
          ),
        pw.SizedBox(height: 4),
        row('From', [l.senderName ?? '-', if (l.senderPhone != null) l.senderPhone!].join(' · ')),
        row('Weight', '${l.weightKg} kg'),
        row('Pieces', '${l.itemCount}'),
        row('Delivery', 'Rs. ${l.deliveryCharge}'),
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 3),
          decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1))),
          child: pw.Center(
            child: pw.Text('${l.waybillId} · not a proof of payment',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
          ),
        ),
      ]),
    ),
  ));
  return doc.save();
}
