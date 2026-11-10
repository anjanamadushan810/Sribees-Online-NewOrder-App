import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/core/network/api_exceptions.dart';
import 'package:sribees_new_orders/features/orders/providers/orders_list_provider.dart';

import '../../helpers/order_fakes.dart';

void main() {
  late FakeOrdersRepository repo;
  OrdersListNotifier make() => OrdersListNotifier(repo, loadOnStart: false);

  setUp(() => repo = FakeOrdersRepository());

  test('refresh loads page 1 with counts', () async {
    repo.pages = {1: FakeOrdersRepository.pageOf([order('1'), order('2')], totalPages: 2)};
    final n = make();
    await n.refresh();
    expect(n.state.loading, isFalse);
    expect(n.state.orders.map((o) => o.orderId), ['1', '2']);
    expect(n.state.counts['pending'], 2);
    expect(n.state.hasMore, isTrue);
  });

  test('loadMore appends page 2 and skips rows that shifted down', () async {
    repo.pages = {
      1: FakeOrdersRepository.pageOf([order('3'), order('2')], totalPages: 2),
      2: FakeOrdersRepository.pageOf([order('2'), order('1')], page: 2, totalPages: 2),
    };
    final n = make();
    await n.refresh();
    await n.loadMore();
    expect(n.state.orders.map((o) => o.orderId), ['3', '2', '1']);
    expect(n.state.hasMore, isFalse);
    await n.loadMore(); // nothing more
    expect(repo.calls.length, 2);
  });

  test('switching tab asks the server for that tab, page 1', () async {
    final n = make();
    await n.selectTab('warehouse');
    expect(repo.calls.last.query.tabKey, 'warehouse');
    expect(repo.calls.last.page, 1);
  });

  test('a slow answer for an old tab never overwrites the new tab', () async {
    repo.pages = {1: FakeOrdersRepository.pageOf([order('old')])};
    final n = make();
    final slow = Completer<void>();
    repo.gate = slow;
    final first = n.selectTab('delivered');
    repo.pages = {1: FakeOrdersRepository.pageOf([order('new')])};
    await n.selectTab('new');
    slow.complete();
    await first;
    expect(n.state.query.tabKey, 'new');
    expect(n.state.orders.single.orderId, 'new');
  });

  test('a failed refresh keeps the orders on screen and records why', () async {
    repo.pages = {1: FakeOrdersRepository.pageOf([order('1')])};
    final n = make();
    await n.refresh();
    repo.error = ApiException(message: 'x', kind: ApiErrorKind.offline);
    await n.refresh();
    expect(n.state.orders.single.orderId, '1');
    expect(n.state.error, ApiErrorKind.offline);
    repo.error = null;
    await n.refresh();
    expect(n.state.error, isNull);
  });
}
