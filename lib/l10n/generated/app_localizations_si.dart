// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appTitle => 'Sribees New Orders';

  @override
  String get appTagline => 'ඔබේ ශාඛාවේ ඇණවුම්, ආපු ගමන්ම';

  @override
  String get setupReady => 'සැකසුම සූදානම්. ඊළඟට ලොග් වීම.';

  @override
  String versionLabel(String version) {
    return 'සංස්කරණය $version';
  }

  @override
  String get languageName => 'සිංහල';

  @override
  String get switchLanguage => 'භාෂාව';
}
