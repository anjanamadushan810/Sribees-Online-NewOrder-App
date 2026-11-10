import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/server_clock.dart';
import '../models/order_summary.dart';
import '../models/orders_query.dart';
import '../repositories/orders_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return HttpOrdersRepository(
    apiClient: ref.watch(apiClientProvider),
    clock: ref.watch(serverClockProvider),
  );
});

class OrdersListState {
  final OrdersQuery query;
  final List<OrderSummary> orders;
  final Map<String, int> counts;
  final int page;
  final int totalPages;

  /// First load of this query (nothing to show yet).
  final bool loading;
  final bool loadingMore;

  /// Last load failed. Orders already on screen stay visible.
  final ApiErrorKind? error;

  const OrdersListState({
    this.query = const OrdersQuery(),
    this.orders = const [],
    this.counts = const {},
    this.page = 0,
    this.totalPages = 1,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => page < totalPages;

  OrdersListState copyWith({
    OrdersQuery? query,
    List<OrderSummary>? orders,
    Map<String, int>? counts,
    int? page,
    int? totalPages,
    bool? loading,
    bool? loadingMore,
    ApiErrorKind? error,
    bool clearError = false,
  }) =>
      OrdersListState(
        query: query ?? this.query,
        orders: orders ?? this.orders,
        counts: counts ?? this.counts,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}

/// The orders list: filters, paging and refresh. A response for a query the
/// user has already moved away from is dropped (generation counter).
class OrdersListNotifier extends StateNotifier<OrdersListState> {
  OrdersListNotifier(this._repo, {bool loadOnStart = true}) : super(const OrdersListState()) {
    if (loadOnStart) refresh();
  }

  final OrdersRepository _repo;
  static const pageSize = 20;
  int _generation = 0;

  Future<void> setQuery(OrdersQuery query) async {
    state = OrdersListState(query: query, counts: state.counts, loading: true);
    await refresh();
  }

  Future<void> selectTab(String tabKey) =>
      setQuery(state.query.copyWith(tabKey: tabKey, clearPill: true));

  Future<void> selectPill(String? pillKey) => setQuery(pillKey == null
      ? state.query.copyWith(clearPill: true)
      : state.query.copyWith(pillKey: pillKey));

  Future<void> setSearch(String text) => setQuery(state.query.copyWith(search: text));

  Future<void> setBranch(String? branchId) => setQuery(branchId == null
      ? state.query.copyWith(clearBranch: true)
      : state.query.copyWith(branchId: branchId));

  Future<void> setRange(DateRangePreset range) => setQuery(state.query.copyWith(range: range));

  /// Reload page 1 of the current query. Keeps what is on screen until the
  /// new page arrives, so a background refresh never blanks the list.
  Future<void> refresh() async {
    final gen = ++_generation;
    final query = state.query;
    try {
      final page = await _repo.list(query, page: 1, limit: pageSize);
      if (!mounted || gen != _generation) return;
      state = state.copyWith(
        orders: page.orders,
        counts: page.statusCounts,
        page: 1,
        totalPages: page.totalPages,
        loading: false,
        loadingMore: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(loading: false, error: e.kind);
    } catch (_) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(loading: false, error: ApiErrorKind.unknown);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final gen = _generation;
    final next = state.page + 1;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.list(state.query, page: next, limit: pageSize);
      if (!mounted || gen != _generation) return;
      // New orders arriving between pages shift rows down; skip repeats.
      final seen = {for (final o in state.orders) o.orderId};
      state = state.copyWith(
        orders: [...state.orders, ...page.orders.where((o) => !seen.contains(o.orderId))],
        counts: page.statusCounts,
        page: next,
        totalPages: page.totalPages,
        loadingMore: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!mounted || gen != _generation) return;
      state = state.copyWith(loadingMore: false, error: e.kind);
    }
  }
}

final ordersListProvider =
    StateNotifierProvider.autoDispose<OrdersListNotifier, OrdersListState>((ref) {
  return OrdersListNotifier(ref.watch(ordersRepositoryProvider));
});
