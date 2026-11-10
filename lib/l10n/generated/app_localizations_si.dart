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
  String get ordersTitle => 'Orders';

  @override
  String get orderDetailsComingSoon =>
      'Order එකේ සම්පූර්ණ විස්තර ඊළඟ update එකෙන් එනවා.';

  @override
  String get tabAll => 'සියල්ල';

  @override
  String get tabNew => 'අලුත්';

  @override
  String get tabWarehouse => 'ගබඩාව';

  @override
  String get tabLogistics => 'බෙදාහැරීම';

  @override
  String get tabDelivered => 'භාරදුන්';

  @override
  String get tabReturns => 'ආපසු';

  @override
  String get tabExceptions => 'ගැටලු';

  @override
  String get pillAll => 'සියල්ල';

  @override
  String get pillPackedReady => 'පැක් කළා (සූදානම්)';

  @override
  String get pillQc => 'QC බලන්න තියෙන';

  @override
  String get statusAwaitingPayment => 'ගෙවීම එනකම්';

  @override
  String get statusPending => 'පොරොත්තුවෙන්';

  @override
  String get statusConfirmed => 'තහවුරුයි';

  @override
  String get statusProcessing => 'සකසමින්';

  @override
  String get statusPacking => 'පැක් කරමින්';

  @override
  String get statusPacked => 'පැක් කළා';

  @override
  String get statusReadyForPickup => 'Courier එනකම්';

  @override
  String get statusHandedToCourier => 'Courier ට දුන්නා';

  @override
  String get statusShipped => 'යැව්වා';

  @override
  String get statusOutForDelivery => 'බෙදාහරිමින්';

  @override
  String get statusDelivered => 'භාරදුන්නා';

  @override
  String get statusDeliveryFailed => 'භාරදීම අසාර්ථකයි';

  @override
  String get statusRtoInitiated => 'ආපහු store එකට';

  @override
  String get statusCancelled => 'අවලංගුයි';

  @override
  String get statusReturnRequested => 'ආපසු දෙන්න ඉල්ලලා';

  @override
  String get statusReturnApproved => 'ආපසු දීම අනුමතයි';

  @override
  String get statusReturnRejected => 'ආපසු දීම නොපිළිගත්තා';

  @override
  String get statusRefunded => 'මුදල් ආපසු දුන්නා';

  @override
  String get paymentPaid => 'ගෙවලා';

  @override
  String get paymentCod => 'COD';

  @override
  String get paymentRefunded => 'මුදල් ආපසු';

  @override
  String get courierNotBooked => 'Courier book වෙලා නෑ';

  @override
  String get newBadge => 'අලුත්';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'භාණ්ඩ $count',
      one: 'භාණ්ඩ 1',
    );
    return '$_temp0';
  }

  @override
  String get agoJustNow => 'දැන්';

  @override
  String agoMinutes(int n) {
    return 'මිනිත්තු $nකට කලින්';
  }

  @override
  String agoHours(int n) {
    return 'පැය $nකට කලින්';
  }

  @override
  String agoDays(int n) {
    return 'දින $nකට කලින්';
  }

  @override
  String waitingTooLong(int minutes) {
    return 'මිනිත්තු $minutesක් බලන් ඉන්නවා';
  }

  @override
  String get searchHint => 'Order අංකය, පාරිභෝගිකයාගේ නම හෝ email';

  @override
  String get rangeAll => 'ඕනෑම දිනයක්';

  @override
  String get rangeToday => 'අද';

  @override
  String get range7 => 'පසුගිය දින 7';

  @override
  String get range30 => 'පසුගිය දින 30';

  @override
  String get branchFilter => 'ශාඛාව';

  @override
  String get noOrdersHere => 'මෙතන orders නෑ';

  @override
  String noOrdersForSearch(String query) {
    return '\"$query\" ට ගැළපෙන orders නෑ';
  }

  @override
  String get loadFailed => 'Orders load කරන්න බැරි වුණා.';

  @override
  String get retry => 'ආයෙ උත්සාහ කරන්න';

  @override
  String get showingSavedList => 'කලින් load කරපු ලැයිස්තුව පෙන්වනවා.';

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
