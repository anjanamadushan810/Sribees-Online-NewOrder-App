import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';

/// Sribees QR label numbers: 9 digits + a Luhn check digit (the same rule as Sribees
/// Supply). Null when [raw] is not one of our labels (a product barcode, a typo).
String? parseLabel(String raw) {
  final s = raw.replaceAll(RegExp(r'[\s\-]'), '');
  if (!RegExp(r'^[1-9]\d{9}$').hasMatch(s)) return null;
  var total = 0;
  final body = s.substring(0, 9);
  for (var i = 0; i < body.length; i++) {
    var d = int.parse(body[body.length - 1 - i]);
    if (i.isEven) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    total += d;
  }
  return (10 - total % 10) % 10 == int.parse(s[9]) ? s : null;
}

class PackLine {
  final String itemId;
  final String name;
  final String? variant;
  final int quantity;
  final int scannedUnits;
  final double scannedKg;
  final double? needKg;
  final List<String> labels;
  final bool done;

  const PackLine({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.scannedUnits,
    required this.scannedKg,
    required this.labels,
    required this.done,
    this.variant,
    this.needKg,
  });

  bool get byWeight => needKg != null;

  factory PackLine.fromJson(Map<String, dynamic> j) => PackLine(
        itemId: '${j['order_item_id']}',
        name: '${j['name'] ?? ''}',
        variant: j['variant']?.toString(),
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        scannedUnits: (j['scanned_units'] as num?)?.toInt() ?? 0,
        scannedKg: double.tryParse('${j['scanned_kg'] ?? 0}') ?? 0,
        needKg: j['need_kg'] == null ? null : double.tryParse('${j['need_kg']}'),
        labels: [for (final l in (j['labels'] as List? ?? const [])) '$l'],
        done: j['done'] == true,
      );
}

class PackProgress {
  final bool enabled;
  final bool complete;
  final List<PackLine> lines;
  const PackProgress({required this.enabled, required this.complete, required this.lines});

  factory PackProgress.fromJson(Map<String, dynamic> j) => PackProgress(
        enabled: j['enabled'] == true,
        complete: j['complete'] != false,
        lines: [
          for (final l in (j['lines'] as List? ?? const []))
            if (l is Map) PackLine.fromJson(Map<String, dynamic>.from(l)),
        ],
      );
}

class PackScanRepository {
  PackScanRepository(this.api);
  final ApiClient api;

  PackProgress _parse(dynamic body) => PackProgress.fromJson(
      Map<String, dynamic>.from((body is Map && body['data'] is Map) ? body['data'] : const {}));

  Future<PackProgress> progress(String orderId) async =>
      _parse((await api.get('${ApiEndpoints.orders}/$orderId/pack-scan')).data);

  Future<PackProgress> scan(String orderId, String itemId, String label, {String? weightKg}) async =>
      _parse((await api.post('${ApiEndpoints.orders}/$orderId/pack-scan', data: {
        'order_item_id': itemId,
        'label': label,
        'weight_kg': ?weightKg,
      })).data);

  Future<PackProgress> undo(String orderId, String label) async => _parse(
      (await api.post('${ApiEndpoints.orders}/$orderId/pack-scan/undo', data: {'label': label}))
          .data);
}

final packScanRepositoryProvider =
    Provider<PackScanRepository>((ref) => PackScanRepository(ref.watch(apiClientProvider)));
