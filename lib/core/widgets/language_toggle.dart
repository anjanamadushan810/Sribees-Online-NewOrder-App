import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';

/// One-tap Sinhala/English switch, labelled with the language in use.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return TextButton.icon(
      key: const Key('language-toggle'),
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      icon: const Icon(Icons.translate_rounded, size: 18),
      label: Text(t.languageName),
    );
  }
}
