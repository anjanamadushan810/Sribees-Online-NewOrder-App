import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import 'alert_health.dart';
import 'push_alerts_host.dart';
import 'push_registrar.dart';

/// Every reason this phone stays quiet, rebuilt when either side changes.
class _Problems extends ConsumerWidget {
  const _Problems({required this.builder});

  final Widget Function(BuildContext context, List<AlertProblem> problems, PushStatus server) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(alertHealthProvider).valueOrNull;
    return ValueListenableBuilder<PushStatus>(
      valueListenable: ref.read(pushRegistrarProvider).status,
      builder: (context, server, _) => builder(context, alertProblems(health, server), server),
    );
  }
}

/// The quiet 🔕 in the Orders app bar: shown only while this phone would not
/// ring (owner tone: an icon, not a warning line). Tap: what is wrong + fixes.
class AlertHealthButton extends StatelessWidget {
  const AlertHealthButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Problems(
      builder: (context, problems, _) {
        if (problems.isEmpty) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        return IconButton(
          key: const Key('alerts-off-icon'),
          tooltip: t.alertsQuietTitle,
          icon: const Icon(Icons.notifications_off_outlined),
          color: AppColors.error,
          onPressed: () => showAlertFixSheet(context),
        );
      },
    );
  }
}

Future<void> showAlertFixSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _Problems(
          builder: (context, problems, _) {
            final t = AppLocalizations.of(context);
            return Column(
              key: const Key('alerts-fix-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  problems.isEmpty ? t.alertsAllGood : t.alertsQuietTitle,
                  key: const Key('alerts-sheet-title'),
                  style: AppTypography.h3(color: problems.isEmpty ? AppColors.success : AppColors.ink),
                ),
                const SizedBox(height: 8),
                const AlertProblemsList(),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// One row per problem with its own fix button, first to fix first. Used by
/// the sheet and by the Settings card.
class AlertProblemsList extends ConsumerStatefulWidget {
  const AlertProblemsList({super.key});

  @override
  ConsumerState<AlertProblemsList> createState() => _AlertProblemsListState();
}

class _AlertProblemsListState extends ConsumerState<AlertProblemsList> {
  /// A fix still running: its button is disabled and shows a spinner, so a
  /// second tap cannot start a second retry loop.
  final _busy = <AlertProblem>{};

  Future<void> _fix(AlertProblem p) async {
    if (_busy.contains(p)) return;
    // Taken before any await: the row may be gone when the fix finishes (the
    // problem got solved and Settings dropped the list) -- `ref` would throw.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy.add(p));
    try {
      await fixAlertProblem(
        p,
        messaging: container.read(pushMessagingProvider),
        registrar: container.read(pushRegistrarProvider),
        language: container.read(localeProvider).languageCode,
      );
    } finally {
      container.invalidate(alertHealthProvider);
      container.invalidate(alertPermissionProvider);
      if (mounted) setState(() => _busy.remove(p));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Problems(
      builder: (context, problems, server) {
        final t = AppLocalizations.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in problems)
              Padding(
                key: Key('alerts-problem-${p.name}'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(_icon(p), color: AppColors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title(t, p), style: AppTypography.bodyMedium(color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(
                            p == AlertProblem.serverFailed ? (server.reason ?? '') : _how(t, p),
                            style: AppTypography.bodySmall(color: AppColors.muted),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            key: Key('alerts-fix-${p.name}'),
                            onPressed: _busy.contains(p) ? null : () => _fix(p),
                            child: _busy.contains(p)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_action(t, p)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static IconData _icon(AlertProblem p) => switch (p) {
        AlertProblem.notificationsOff => Icons.notifications_off_outlined,
        AlertProblem.channelOff => Icons.notifications_paused_outlined,
        AlertProblem.channelSilent => Icons.volume_off_outlined,
        AlertProblem.batteryRestricted => Icons.battery_alert_outlined,
        AlertProblem.serverFailed => Icons.cloud_off_outlined,
      };

  static String _title(AppLocalizations t, AlertProblem p) => switch (p) {
        AlertProblem.notificationsOff => t.problemNotificationsOff,
        AlertProblem.channelOff => t.problemChannelOff,
        AlertProblem.channelSilent => t.problemChannelSilent,
        AlertProblem.batteryRestricted => t.problemBattery,
        AlertProblem.serverFailed => t.problemServer,
      };

  static String _how(AppLocalizations t, AlertProblem p) => switch (p) {
        AlertProblem.notificationsOff => t.problemNotificationsOffHow,
        AlertProblem.channelOff => t.problemChannelOffHow,
        AlertProblem.channelSilent => t.problemChannelSilentHow,
        AlertProblem.batteryRestricted => t.problemBatteryHow,
        AlertProblem.serverFailed => '',
      };

  static String _action(AppLocalizations t, AlertProblem p) => switch (p) {
        AlertProblem.notificationsOff => t.alertsTurnOn,
        AlertProblem.serverFailed => t.alertsRetry,
        _ => t.alertsOpenSettings,
      };
}
