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
  String versionLabel(String version) {
    return 'සංස්කරණය $version';
  }

  @override
  String get languageName => 'සිංහල';

  @override
  String get switchLanguage => 'භාෂාව';

  @override
  String get signInSubtitle =>
      'Sribees admin web එකට ලොග් වෙන email එකයි මුරපදයයි මෙතන දාන්න.';

  @override
  String get emailLabel => 'Email ලිපිනය';

  @override
  String get passwordLabel => 'මුරපදය';

  @override
  String get showPassword => 'මුරපදය පෙන්වන්න';

  @override
  String get hidePassword => 'මුරපදය හංගන්න';

  @override
  String get signInButton => 'ලොග් වෙන්න';

  @override
  String get emailRequired => 'Email ලිපිනය දාන්න';

  @override
  String get emailInvalid => 'Email ලිපිනය හරි නෑ';

  @override
  String get passwordRequired => 'මුරපදය දාන්න';

  @override
  String get errInvalidCredentials =>
      'Email ලිපිනය හෝ මුරපදය වැරදියි, නැත්නම් මේ ගිණුම නවත්වලා.';

  @override
  String get errNoOrderAccess =>
      'මේ ගිණුමට orders බලන්න අවසර නෑ. Super admin කෙනෙක්ගෙන් Orders අවසරය ඉල්ලන්න.';

  @override
  String get errNoBranch =>
      'මේ ගිණුමට ශාඛාවක් දීලා නෑ. Super admin කෙනෙක්ට කියලා ශාඛාවක් දාගන්න.';

  @override
  String get errSessionExpired => 'ඔබ ලොග් අවුට් වුණා. ආයෙ ලොග් වෙන්න.';

  @override
  String get errOffline =>
      'Internet සම්බන්ධතාවය නෑ. Wi-Fi හෝ mobile data බලන්න.';

  @override
  String get errTimeout =>
      'Server එකෙන් උත්තරයක් එන්න පරක්කුයි. ආයෙ උත්සාහ කරන්න.';

  @override
  String get errServer => 'Server එකේ ගැටලුවක්. ටිකකින් ආයෙ උත්සාහ කරන්න.';

  @override
  String get errUnknown => 'මොකක්හරි වැරැද්දක් වුණා. ආයෙ උත්සාහ කරන්න.';

  @override
  String hello(String name) {
    return 'ආයුබෝවන්, $name';
  }

  @override
  String get ordersComingSoon => 'Orders ලැයිස්තුව ඊළඟ update එකෙන් එනවා.';

  @override
  String get settingsTitle => 'සැකසුම්';

  @override
  String get roleLabel => 'තනතුර';

  @override
  String get branchLabel => 'ශාඛාව';

  @override
  String get allBranches => 'සියලුම ශාඛා';

  @override
  String get assignedBranch => 'පවරපු ශාඛාව';

  @override
  String get roleSuperAdmin => 'සුපර් ඇඩ්මින්';

  @override
  String get roleBranchManager => 'ශාඛා කළමනාකරු';

  @override
  String get roleMarketingManager => 'අලෙවි කළමනාකරු';

  @override
  String get roleInventoryManager => 'තොග කළමනාකරු';

  @override
  String get roleCustomerSupport => 'පාරිභෝගික සහාය';

  @override
  String get roleStaff => 'කාර්ය මණ්ඩලය';

  @override
  String get roleUnknown => 'ඇඩ්මින්';

  @override
  String get aboutApp => 'App එක ගැන';

  @override
  String get signOut => 'ලොග් අවුට් වෙන්න';

  @override
  String get signOutConfirmTitle => 'ලොග් අවුට් වෙන්නද?';

  @override
  String get signOutConfirmBody =>
      'ආයෙ ලොග් වෙනකම් මේ phone එකට අලුත් order alerts එන්නේ නෑ.';

  @override
  String get cancel => 'එපා';
}
