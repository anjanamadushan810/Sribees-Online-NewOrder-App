import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/server_clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../alerts/alert_health_widgets.dart';
import '../../auth/models/branch.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/pages/settings_page.dart';
import '../models/order_status.dart';
import '../models/order_summary.dart';
import '../models/orders_query.dart';
import '../order_labels.dart';
import '../providers/orders_list_provider.dart';
import '../providers/seen_orders_provider.dart';
import '../widgets/order_card.dart';
import 'order_detail_page.dart';

/// Branches an unscoped admin can narrow to.
final branchesProvider = FutureProvider.autoDispose<List<Branch>>((ref) {
  return ref.watch(authRepositoryProvider).getBranches();
});

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  /// How often an open, visible list re-checks the server (catches a missed
  /// push; nothing runs in the background).
  static const autoRefresh = Duration(seconds: 60);

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> with WidgetsBindingObserver {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _searchDebounce;
  Timer? _refreshTimer;
  Timer? _ticker;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _refreshTimer = Timer.periodic(OrdersPage.autoRefresh, (_) => _autoRefresh());
    // Re-draw "x min ago" and the waiting colours.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _refreshTimer?.cancel();
    _ticker?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) ref.read(ordersListProvider.notifier).refresh();
  }

  void _autoRefresh() {
    final route = ModalRoute.of(context);
    if (!mounted || !_foreground || (route != null && !route.isCurrent)) return;
    ref.read(ordersListProvider.notifier).refresh();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      ref.read(ordersListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(ordersListProvider.notifier).setSearch(text);
    });
  }

  Future<void> _open(OrderSummary order) async {
    ref.read(seenOrdersProvider.notifier).markSeen(order.orderId);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.orderId, summary: order)),
    );
    if (mounted) ref.read(ordersListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final unscoped = user?.isUnscoped ?? false;
    final s = ref.watch(ordersListProvider);
    final seen = ref.watch(seenOrdersProvider);
    final now = ref.watch(serverClockProvider).now();
    final notifier = ref.read(ordersListProvider.notifier);

    final scopeName = unscoped ? t.allBranches : (auth.branch?.name ?? t.assignedBranch);
    final tab = s.query.tab;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.ordersTitle),
            Text(scopeName, style: AppTypography.bodySmall(color: AppColors.muted)),
          ],
        ),
        actions: [
          const AlertHealthButton(),
          IconButton(
            key: const Key('open-settings'),
            tooltip: t.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _TabStrip(
            selected: s.query.tabKey,
            counts: s.counts,
            onSelect: notifier.selectTab,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              key: const Key('orders-search'),
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: t.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          notifier.setSearch('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _RangeChip(value: s.query.range, onChanged: notifier.setRange),
                if (unscoped) ...[
                  const SizedBox(width: 8),
                  _BranchChip(selectedId: s.query.branchId, onChanged: notifier.setBranch),
                ],
                if (tab.pills.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 24, color: AppColors.border),
                  const SizedBox(width: 8),
                  _PillChip(
                    key: const Key('pill-all'),
                    label: t.pillAll,
                    count: tab.badge(s.counts),
                    selected: s.query.pillKey == null,
                    onTap: () => notifier.selectPill(null),
                  ),
                  for (final p in tab.pills) ...[
                    const SizedBox(width: 6),
                    _PillChip(
                      key: Key('pill-${p.key}'),
                      label: pillLabel(p, t),
                      count: sumCounts(s.counts, p.statuses),
                      selected: s.query.pillKey == p.key,
                      onTap: () => notifier.selectPill(p.key),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (s.error != null && s.orders.isNotEmpty)
            _Banner(text: '${errorLabel(s.error!, t)} ${t.showingSavedList}'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: _body(context, s, seen, now, unscoped),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, OrdersListState s, List<String> seen, DateTime now,
      bool unscoped) {
    final t = AppLocalizations.of(context);
    if (s.loading && s.orders.isEmpty) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (_, _) => const _SkeletonCard(),
      );
    }
    if (s.orders.isEmpty) {
      final message = s.error != null
          ? errorLabel(s.error!, t)
          : s.query.search.trim().isNotEmpty
              ? t.noOrdersForSearch(s.query.search.trim())
              : t.noOrdersHere;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(s.error != null ? Icons.cloud_off_rounded : Icons.inbox_outlined,
              size: 56, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(message,
              key: const Key('orders-empty'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge(color: AppColors.inkSecondary)),
          if (s.error != null) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                key: const Key('orders-retry'),
                onPressed: ref.read(ordersListProvider.notifier).refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t.retry),
              ),
            ),
          ],
        ],
      );
    }
    return ListView.separated(
      key: const Key('orders-list'),
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: s.orders.length + (s.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= s.orders.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }
        final o = s.orders[i];
        return OrderCard(
          order: o,
          nowUtc: now,
          isNew: o.status.isWaitingForBranch && !seen.contains(o.orderId),
          showBranch: unscoped,
          onTap: () => _open(o),
        );
      },
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.selected, required this.counts, required this.onSelect});

  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final tab in orderTabs)
            _TabButton(
              key: Key('tab-${tab.key}'),
              label: tabLabel(tab, t),
              count: tab.badge(counts),
              highlight: tab.key == 'new' || tab.key == 'returns',
              selected: tab.key == selected,
              onTap: () => onSelect(tab.key),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.count,
    required this.highlight,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool highlight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inkSecondary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(label,
                style: AppTypography.bodyMedium(color: color)
                    .copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: highlight ? AppColors.primary : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.badge(
                      color: highlight ? Colors.white : AppColors.inkSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label  $count'),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.primaryTint,
      labelStyle: AppTypography.bodySmall(
          color: selected ? AppColors.primary : AppColors.inkSecondary),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.value, required this.onChanged});

  final DateRangePreset value;
  final ValueChanged<DateRangePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopupMenuButton<DateRangePreset>(
      key: const Key('range-filter'),
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final r in DateRangePreset.values)
          PopupMenuItem(value: r, child: Text(rangeLabel(r, t))),
      ],
      child: Chip(
        avatar: const Icon(Icons.calendar_today_rounded, size: 16),
        label: Text(rangeLabel(value, t)),
        visualDensity: VisualDensity.compact,
        backgroundColor:
            value == DateRangePreset.all ? Colors.white : AppColors.primaryTint,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _BranchChip extends ConsumerWidget {
  const _BranchChip({required this.selectedId, required this.onChanged});

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final branches = ref.watch(branchesProvider).valueOrNull ?? const <Branch>[];
    final current = branches.where((b) => b.branchId == selectedId);
    final label = current.isEmpty ? t.allBranches : current.first.name;
    return PopupMenuButton<String>(
      key: const Key('branch-filter'),
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: '', child: Text(t.allBranches)),
        for (final b in branches) PopupMenuItem(value: b.branchId, child: Text(b.name)),
      ],
      child: Chip(
        avatar: const Icon(Icons.storefront_outlined, size: 16),
        label: Text(label),
        visualDensity: VisualDensity.compact,
        backgroundColor: selectedId == null ? Colors.white : AppColors.primaryTint,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('orders-stale-banner'),
      width: double.infinity,
      color: AppColors.warningBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
          width: w,
          height: 12,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bar(140), bar(200), bar(110)],
        ),
      ),
    );
  }
}
