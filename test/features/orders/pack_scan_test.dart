import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/features/orders/pack_scan/pack_scan_repository.dart';

void main() {
  test('label numbers use the same check digit as Sribees Supply', () {
    expect(parseLabel('1000001238'), '1000001238'); // Supply make_number(100000123)
    expect(parseLabel('1000 0012-38'), '1000001238');
    expect(parseLabel('1000001239'), isNull);
    expect(parseLabel('4791234567890'), isNull); // a product barcode
  });

  test('progress from the server', () {
    final p = PackProgress.fromJson({
      'enabled': true,
      'complete': false,
      'lines': [
        {'order_item_id': 'a', 'name': 'Soap', 'quantity': 2, 'scanned_units': 1,
         'scanned_kg': '0', 'need_kg': null, 'labels': ['1000001238'], 'done': false},
        {'order_item_id': 'b', 'name': 'Rice', 'quantity': 2, 'scanned_units': 0,
         'scanned_kg': '1.000', 'need_kg': '1.000', 'labels': [], 'done': true},
      ],
    });
    expect(p.enabled, isTrue);
    expect(p.complete, isFalse);
    expect(p.lines.first.byWeight, isFalse);
    expect(p.lines.last.byWeight, isTrue);
    expect(p.lines.last.needKg, 1.0);
    expect(PackProgress.fromJson({'enabled': false}).complete, isTrue);
    final loose = PackLine.fromJson({'order_item_id': 'c', 'by_weight': true, 'need_kg': null,
                                     'no_scan': false});
    expect(loose.byWeight, isTrue);
    expect(PackLine.fromJson({'order_item_id': 'd', 'no_scan': true}).noScan, isTrue);
  });
}
