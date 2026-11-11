import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/providers/app_version_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../alerts/push_alerts_host.dart';
import '../../alerts/push_messaging.dart';
import '../../alerts/push_registrar.dart';
import '../../auth/auth_labels.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.signOutConfirmTitle),
        content: Text(t.signOutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(
            key: const Key('signout-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.signOut),
          ),
        ],
      ),
    );
    if (yes == true) {
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final locale = ref.watch(localeProvider);
    final version = ref.watch(appVersionProvider).valueOrNull ?? '…';
    final env = AppEnv.current;

    final branchText = user == null
        ? ''
        : user.isUnscoped
            ? t.allBranches
            : (auth.branch?.name ?? t.assignedBranch);

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryTint,
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: AppTypography.h2(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName,
                                  key: const Key('settings-name'),
                                  style: AppTypography.h3(color: AppColors.ink)),
                              Text(user.email,
                                  style: AppTypography.bodySmall(color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: t.roleLabel,
                      value: roleTitle(user, t),
                      valueKey: const Key('settings-role'),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.storefront_outlined,
                      label: t.branchLabel,
                      value: branchText,
                      valueKey: const Key('settings-branch'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(t.switchLanguage),
                ),
                RadioGroup<String>(
                  groupValue: locale.languageCode,
                  onChanged: (v) {
                    if (v != null) ref.read(localeProvider.notifier).setLanguage(v);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        key: Key('lang-si'),
                        value: 'si',
                        title: Text('සිංහල'),
                      ),
                      RadioListTile<String>(
                        key: Key('lang-en'),
                        value: 'en',
                        title: Text('English'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _AlertsCard(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(t.aboutApp),
              subtitle: Text(
                [t.versionLabel(version), if (!env.isProd) env.label].join('  ·  '),
                key: const Key('settings-version'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const Key('signout'),
              onPressed: () => _confirmSignOut(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(t.signOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTypography.bodyMedium(color: AppColors.muted)),
        Expanded(
          child: Text(value,
              key: valueKey,
              style: AppTypography.bodyMedium(color: AppColors.ink)),
        ),
      ],
    );
  }
}

/// Whether this phone rings, and a way to hear the ringtone. When alerts are
/// blocked the how-to sits behind a quiet ⓘ, not a warning line (owner tone).
class _AlertsCard extends ConsumerWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final permission = ref.watch(alertPermissionProvider).valueOrNull;
    final messaging = ref.watch(pushMessagingProvider);

    final (String status, bool off) = switch (permission) {
      AlertPermission.granted => (t.alertsOn, false),
      AlertPermission.denied || AlertPermission.notAsked => (t.alertsOff, true),
      AlertPermission.unavailable => (t.alertsUnavailable, true),
      null => ('…', false),
    };

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              off ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
              color: off ? AppColors.muted : AppColors.primary,
            ),
            title: Text(t.alertsSection),
            subtitle: Text(status, key: const Key('alerts-status')),
            trailing: off && permission != AlertPermission.unavailable
                ? IconButton(
                    key: const Key('alerts-info'),
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    color: AppColors.muted,
                    tooltip: t.alertsOffHint,
                    onPressed: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(t.alertsOffHint))),
                  )
                : null,
          ),
          ValueListenableBuilder<PushStatus>(
            valueListenable: ref.read(pushRegistrarProvider).status,
            builder: (context, s, _) => !s.known
                ? const SizedBox.shrink()
                : ListTile(
                    key: const Key('alerts-server'),
                    leading: Icon(
                      s.ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                      color: s.ok ? AppColors.success : AppColors.error,
                    ),
                    title: Text(s.ok ? t.alertsServerOk : t.alertsServerFailed),
                    subtitle: s.ok || s.reason == null
                        ? null
                        : Text(s.reason!, key: const Key('alerts-server-reason'),
                            style: AppTypography.bodySmall(color: AppColors.muted)),
                    trailing: s.ok
                        ? null
                        : TextButton(
                            key: const Key('alerts-retry'),
                            onPressed: () => ref.read(pushRegistrarProvider).register(
                                  language: ref.read(localeProvider).languageCode,
                                ),
                            child: Text(t.alertsRetry),
                          ),
                  ),
          ),
          if (messaging.available)
            ListTile(
              key: const Key('alerts-test-sound'),
              leading: const Icon(Icons.volume_up_outlined),
              title: Text(t.alertsTestSound),
              onTap: () => ref.read(pushRegistrarProvider).messaging.playAlertSound(),
            ),
        ],
      ),
    );
  }
}
