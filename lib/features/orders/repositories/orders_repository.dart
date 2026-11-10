import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/server_clock.dart';
import '../models/order_summary.dart';
import '../models/orders_query.dart';

abstract class OrdersRepository {
  Future<OrdersPage> list(OrdersQuery query, {required int page, int limit = 20});
}

class HttpOrdersRepository implements OrdersRepository {
  final ApiClient apiClient;
  final ServerClock clock;

  HttpOrdersRepository({required this.apiClient, required this.clock});

  @override
  Future<OrdersPage> list(OrdersQuery query, {required int page, int limit = 20}) async {
    final response = await apiClient.get(
      ApiEndpoints.orders,
      queryParameters: query.toParams(page: page, limit: limit, nowUtc: clock.now()),
    );
    clock.syncFromHeader(response.headers.value('date'));

    final body = response.data;
    final data = (body is Map && body['data'] is Map) ? body['data'] as Map : const {};
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
}
