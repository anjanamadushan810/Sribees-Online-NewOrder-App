import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/auth_labels.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/pages/settings_page.dart';

/// Signed-in home. P1: a greeting and the way to Settings; the orders list
/// takes this place in P2.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final scope = user == null
        ? ''
        : user.isUnscoped
            ? t.allBranches
            : (auth.branch?.name ?? t.assignedBranch);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            key: const Key('open-settings'),
            tooltip: t.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              if (user != null)
                Text(t.hello(user.fullName),
                    key: const Key('home-hello'),
                    textAlign: TextAlign.center,
                    style: AppTypography.h2(color: AppColors.ink)),
              const SizedBox(height: 6),
              if (user != null)
                Text('${roleTitle(user, t)} · $scope',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: AppColors.inkSecondary)),
              const SizedBox(height: 24),
              Text(t.ordersComingSoon,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
