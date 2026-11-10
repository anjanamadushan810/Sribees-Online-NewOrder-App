import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exceptions.dart';
import '../models/order_detail.dart';
import '../repositories/orders_repository.dart';
import 'orders_list_provider.dart';

class OrderDetailState {
  final OrderDetail? order;
  final List<StatusAction> actions;
  final bool loading;
  final ApiErrorKind? error;

  /// Target status being applied right now (buttons disabled meanwhile).
  final String? applying;

  const OrderDetailState({
    this.order,
    this.actions = const [],
    this.loading = true,
    this.error,
    this.applying,
  });

  OrderDetailState copyWith({
    OrderDetail? order,
    List<StatusAction>? actions,
    bool? loading,
    ApiErrorKind? error,
    bool clearError = false,
    String? applying,
    bool clearApplying = false,
  }) =>
      OrderDetailState(
        order: order ?? this.order,
        actions: actions ?? this.actions,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        applying: clearApplying ? null : (applying ?? this.applying),
      );
}

/// Result of pressing a status button.
sealed class ApplyResult {
  const ApplyResult();
}

class Applied extends ApplyResult {
  const Applied();
}

class Refused extends ApplyResult {
  /// The server's reason (English), e.g. the state machine refusing a move
  /// another phone already made.
  final String message;
  final ApiErrorKind kind;
  const Refused(this.message, this.kind);
}

class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  OrderDetailNotifier(this._repo, this.orderId, {bool loadOnStart = true})
      : super(const OrderDetailState()) {
    if (loadOnStart) load();
  }

  final OrdersRepository _repo;
  final String orderId;

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _repo.detail(orderId),
        _repo.nextActions(orderId),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        order: results[0] as OrderDetail,
        actions: results[1] as List<StatusAction>,
        loading: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.kind);
    }
  }

  /// Apply a transition, then reload so the screen shows the server's truth
  /// (new status, new buttons, history line) whether it worked or not.
  Future<ApplyResult> apply(StatusAction action) async {
    if (state.applying != null) return const Refused('busy', ApiErrorKind.unknown);
    state = state.copyWith(applying: action.targetWire);
    try {
      await _repo.updateStatus(orderId, action.targetWire);
      await load();
      return const Applied();
    } on ApiException catch (e) {
      await load();
      return Refused(e.message, e.kind);
    } finally {
      if (mounted) state = state.copyWith(clearApplying: true);
    }
  }
}

final orderDetailProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, String>((ref, orderId) {
  return OrderDetailNotifier(ref.watch(ordersRepositoryProvider), orderId);
});
