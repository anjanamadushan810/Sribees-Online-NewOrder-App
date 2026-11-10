import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/server_clock.dart';
import '../models/order_detail.dart';
import '../models/order_summary.dart';
import '../models/orders_query.dart';

abstract class OrdersRepository {
  Future<OrdersPage> list(OrdersQuery query, {required int page, int limit = 20});

  Future<OrderDetail> detail(String orderId);

  /// The buttons this admin may press now (empty for read-only roles).
  Future<List<StatusAction>> nextActions(String orderId);

  /// Standard transition through the server's state machine. Returns the
  /// updated order (without the courier block, so callers reload).
  Future<void> updateStatus(String orderId, String targetStatus);
}

class HttpOrdersRepository implements OrdersRepository {
  final ApiClient apiClient;
  final ServerClock clock;

  HttpOrdersRepository({required this.apiClient, required this.clock});

  Map _data(dynamic body) => (body is Map && body['data'] is Map) ? body['data'] as Map : const {};

  @override
  Future<OrdersPage> list(OrdersQuery query, {required int page, int limit = 20}) async {
    final response = await apiClient.get(
      ApiEndpoints.orders,
      queryParameters: query.toParams(page: page, limit: limit, nowUtc: clock.now()),
    );
    clock.syncFromHeader(response.headers.value('date'));

    final data = _data(response.data);
    final rows = data['orders'];
    final pagination = data['pagination'] is Map ? data['pagination'] as Map : const {};
    final counts = <String, int>{};
    if (data['status_counts'] is Map) {
      (data['status_counts'] as Map).forEach((k, v) {
        if (v is num) counts[k.toString()] = v.toInt();
      });
    }
    return OrdersPage(
      orders: [
        if (rows is List)
          for (final r in rows)
            if (r is Map) OrderSummary.fromJson(Map<String, dynamic>.from(r)),
      ],
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      page: (pagination['page'] as num?)?.toInt() ?? page,
      totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
      statusCounts: counts,
    );
  }

  @override
  Future<OrderDetail> detail(String orderId) async {
    final response = await apiClient.get('${ApiEndpoints.orders}/$orderId');
    clock.syncFromHeader(response.headers.value('date'));
    return OrderDetail.fromJson(Map<String, dynamic>.from(_data(response.data)));
  }

  @override
  Future<List<StatusAction>> nextActions(String orderId) async {
    final response = await apiClient.get('${ApiEndpoints.orders}/$orderId/next-statuses');
    final actions = _data(response.data)['actions'];
    return [
      if (actions is List)
        for (final a in actions)
          if (a is Map) StatusAction.fromJson(Map<String, dynamic>.from(a)),
    ];
  }

  @override
  Future<void> updateStatus(String orderId, String targetStatus) async {
    await apiClient.patch(
      '${ApiEndpoints.orders}/$orderId/status',
      data: {'status': targetStatus},
    );
  }
}
