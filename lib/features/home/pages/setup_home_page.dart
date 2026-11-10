import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_version_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';

/// P0 placeholder: proves the build, flavor, icon, language and version
/// wiring. Replaced by the login gate in P1.
class SetupHomePage extends ConsumerWidget {
  const SetupHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  key: const Key('language-toggle'),
                  onPressed: () => ref.read(localeProvider.notifier).toggle(),
                  icon: const Icon(Icons.translate_rounded, size: 18),
                  label: Text(t.languageName),
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 112,
                  height: 112,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.appTitle,
                textAlign: TextAlign.center,
                style: AppTypography.h1(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                t.appTagline,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.setupReady,
                        style: AppTypography.bodyMedium(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                t.versionLabel(version.valueOrNull ?? '…'),
                key: const Key('app-version'),
                style: AppTypography.bodySmall(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
