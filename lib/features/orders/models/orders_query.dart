import '../../../core/utils/server_clock.dart';
import 'order_status.dart';

enum DateRangePreset { all, today, last7, last30 }

/// Everything the list is filtered by. The server applies all of it; branch
/// scope is decided by the server from the login, `branchId` only narrows an
/// unscoped admin's view.
class OrdersQuery {
  final String tabKey;
  final String? pillKey;
  final String search;
  final String? branchId;
  final DateRangePreset range;

  const OrdersQuery({
    this.tabKey = defaultTabKey,
    this.pillKey,
    this.search = '',
    this.branchId,
    this.range = DateRangePreset.all,
  });

  OrderTab get tab => tabByKey(tabKey);

  List<OrderStatus> get statuses {
    final pill = tab.pills.where((p) => p.key == pillKey);
    return pill.isNotEmpty ? pill.first.statuses : tab.statuses;
  }

  /// Query parameters for `GET /admin/orders`, dates in Asia/Colombo.
  Map<String, dynamic> toParams({required int page, required int limit, required DateTime nowUtc}) {
    final p = <String, dynamic>{'page': page, 'limit': limit};
    if (statuses.isNotEmpty) p['order_statuses'] = statuses.map((s) => s.wire).join(',');
    final q = search.trim();
    if (q.isNotEmpty) p['search'] = q;
    if (branchId != null) p['branch_id'] = branchId;
    final days = switch (range) {
      DateRangePreset.all => null,
      DateRangePreset.today => 0,
      DateRangePreset.last7 => 6,
      DateRangePreset.last30 => 29,
    };
    if (days != null) {
      p['from_date'] = colomboDate(nowUtc.subtract(Duration(days: days)));
      p['to_date'] = colomboDate(nowUtc);
    }
    return p;
  }

  OrdersQuery copyWith({
    String? tabKey,
    String? pillKey,
    bool clearPill = false,
    String? search,
    String? branchId,
    bool clearBranch = false,
    DateRangePreset? range,
  }) =>
      OrdersQuery(
        tabKey: tabKey ?? this.tabKey,
        pillKey: clearPill ? null : (pillKey ?? this.pillKey),
        search: search ?? this.search,
        branchId: clearBranch ? null : (branchId ?? this.branchId),
        range: range ?? this.range,
      );
}
