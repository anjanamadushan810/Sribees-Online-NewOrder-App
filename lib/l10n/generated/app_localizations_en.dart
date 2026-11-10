// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sribees New Orders';

  @override
  String get appTagline => 'Your branch\'s orders, the moment they arrive';

  @override
  String get setupReady => 'Setup is ready. Sign-in comes next.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get languageName => 'English';

  @override
  String get switchLanguage => 'Language';
}
