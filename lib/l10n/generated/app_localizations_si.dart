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
  String get actConfirmOrder => 'Order එක තහවුරු කරන්න';

  @override
  String get actCancelOrder => 'Order එක අවලංගු කරන්න';

  @override
  String get actStartPacking => 'පැක් කරන්න පටන් ගන්න';

  @override
  String get actMarkPacked => 'පැක් කළා';

  @override
  String get actReadyForPickup => 'Courier ට ගන්න සූදානම්';

  @override
  String get actMarkShipped => 'යැව්වා';

  @override
  String get actOutForDelivery => 'බෙදාහරින්න පිටත් කළා';

  @override
  String get actMarkDelivered => 'භාරදුන්නා';

  @override
  String get actDeliveryFailed => 'භාරදීම අසාර්ථකයි';

  @override
  String get actReschedule => 'ආයෙ බෙදාහරින්න';

  @override
  String get actRto => 'Hub එකට ආපහු (RTO)';

  @override
  String confirmMove(String number, String status) {
    return 'Order $number \"$status\" වෙනවා.';
  }

  @override
  String get notifyNote => 'Customer ට ඉබේම පණිවිඩයක් යනවා.';

  @override
  String get courierBookNote =>
      'මේකෙන් parcel එක ගන්න SribeesExpress rider කෙනෙක් book වෙනවා.';

  @override
  String get cancelNote =>
      'Order එක අවලංගු වෙලා stock එක ආපහු එකතු වෙනවා. App එකෙන් මේක ආපහු හරවන්න බෑ.';

  @override
  String get pickupNotRegistered =>
      'මේ ශාඛාව SribeesExpress pickup සඳහා register කරලා නෑ. Rider වෙන ලිපිනයකට යන්න පුළුවන්.';

  @override
  String get yes => 'ඔව්';

  @override
  String statusChanged(String status) {
    return 'Status එක වෙනස් කළා: $status';
  }

  @override
  String get statusChangeFailed => 'Status එක වෙනස් කරන්න බැරි වුණා.';

  @override
  String get readOnlyInfo => 'ඔබේ තනතුරට මේ order එක බලන්න විතරයි පුළුවන්.';

  @override
  String get noFurtherSteps => 'මේ order එකට app එකෙන් කරන්න තව පියවර නෑ.';

  @override
  String get secCustomer => 'පාරිභෝගිකයා';

  @override
  String get secAddress => 'බෙදාහරින ලිපිනය';

  @override
  String get secItems => 'භාණ්ඩ';

  @override
  String get secPayment => 'ගෙවීම';

  @override
  String get secHistory => 'ඉතිහාසය';

  @override
  String get secNote => 'Customer ගේ සටහන';

  @override
  String get secSlot => 'බෙදාහරින වේලාව';

  @override
  String get call => 'Call කරන්න';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get openMaps => 'Map එකේ බලන්න';

  @override
  String get cannotOpen => 'මේ phone එකේ ඒක open කරන්න app එකක් නෑ.';

  @override
  String placedAt(String time) {
    return 'Order කළේ $time';
  }

  @override
  String qtyTimes(int qty, String price) {
    return '$qty × $price';
  }

  @override
  String get payCod => 'භාරදෙද්දී මුදල් (COD)';

  @override
  String get payCard => 'Card';

  @override
  String get payWallet => 'Wallet';

  @override
  String get payBank => 'බැංකු මාරුව';

  @override
  String get codToCollect => 'එකතු කරගන්න ඕනේ මුදල';

  @override
  String get priceSubtotal => 'භාණ්ඩ';

  @override
  String get priceDelivery => 'Delivery ගාස්තුව';

  @override
  String get priceDiscount => 'වට්ටම';

  @override
  String get priceWallet => 'Wallet එකෙන් ගෙව්වා';

  @override
  String get priceTotal => 'මුළු මුදල';

  @override
  String get orderLoadFailed => 'මේ order එක load කරන්න බැරි වුණා.';

  @override
  String get orderOtherBranch => 'මේ order එක වෙන ශාඛාවක එකක්.';

  @override
  String get stepConfirmed => 'තහවුරුයි';

  @override
  String get stepPacking => 'පැක් කරමින්';

  @override
  String get stepPacked => 'පැක් කළා';

  @override
  String get stepCourier => 'Courier';

  @override
  String get stepOnTheWay => 'එන ගමන්';

  @override
  String get stepDelivered => 'භාරදුන්නා';

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
  String get courierNotBooked =>
      'තාම SribeesExpress එකේ book කරලා නැහැ. Order එක pickup එකට ලෑස්තියි කියලා දැම්මම book වෙනවා.';

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

  @override
  String get alertsPermissionTitle => 'අලුත් order එකකට phone එක නාද වෙන්නද?';

  @override
  String get alertsPermissionBody =>
      'ඔබේ branch එකට අලුත් order එකක් ආපු ගමන් මේ phone එක නාද වෙන්න notifications වලට ඉඩ දෙන්න.';

  @override
  String get alertsAllow => 'ඉඩ දෙන්න';

  @override
  String get alertsNotNow => 'පස්සේ';

  @override
  String newOrderArrived(String orderNumber) {
    return 'අලුත් order එකක් #$orderNumber';
  }

  @override
  String get newOrderArrivedNoNumber => 'අලුත් order එකක් ආවා';

  @override
  String get alertView => 'බලන්න';

  @override
  String get alertsSection => 'අලුත් order alerts';

  @override
  String get alertsOn => 'ON: අලුත් order එකකට මේ phone එක නාද වෙනවා';

  @override
  String get alertsOff => 'OFF: මේ app එකට notifications නවත්වලා';

  @override
  String get alertsOffHint =>
      'Phone එකේ Settings වලින් Sribees New Orders app එකට notifications on කරන්න.';

  @override
  String get alertsUnavailable => 'මේ build එකේ නැහැ';

  @override
  String get alertsTestSound => 'Sound එක අහලා බලන්න';

  @override
  String get secCourier => 'Courier';

  @override
  String get courierWaybill => 'Waybill';

  @override
  String get courierStatus => 'Courier තත්ත්වය';

  @override
  String get courierCollectFrom => 'ගන්න තැන';

  @override
  String get courierRiderCollects => 'Rider ගන්න මුදල';

  @override
  String get courierPrepaid => 'ගෙවලා ඉවරයි: ගන්න දෙයක් නැහැ';

  @override
  String get courierCashCollected => 'මුදල් ලැබුණා';

  @override
  String get courierCashNotYet => 'තාම ලැබිලා නැහැ';

  @override
  String get courierShortfall => 'ලැබුණේ නැහැ';

  @override
  String get courierHandover => 'Handover code';

  @override
  String get courierHandoverWaiting => 'Customer ගේ code එක එනකම්';

  @override
  String get courierHandoverDone => 'තහවුරුයි';

  @override
  String get courierBookingFailed =>
      'Pickup booking එක ප්‍රතික්ෂේප වුණා. ආයේ උත්සාහ කරන්න, නැත්නම් admin web එකේ බලන්න.';

  @override
  String get courierRequestPickup => 'Courier pickup එකට ලෑස්තියි';

  @override
  String get courierRetryBooking => 'ආයේ book කරන්න';

  @override
  String get courierRefresh => 'Tracking අලුත් කරන්න';

  @override
  String get courierLabel => 'Label';

  @override
  String get courierLabelTitle => 'Shipping label';

  @override
  String get courierPickupConfirmTitle => 'Courier pickup එකට ලෑස්තිද?';

  @override
  String get courierPickupConfirmBody =>
      'මේ parcel එක ගන්න SribeesExpress rider කෙනෙක් එවනවා.';

  @override
  String get courierUnregisteredNote =>
      'මේ branch එක pickup point එකක් විදියට register කරලා නැති නිසා rider යන්නේ ප්‍රධාන account එකේ ලිපිනයට.';

  @override
  String get courierFailed => 'SribeesExpress එකට සම්බන්ධ වෙන්න බැරි වුණා.';

  @override
  String get trackBooked => 'Book කළා: rider එනකම්';

  @override
  String get trackPickedUp => 'Rider අරගෙන ගියා';

  @override
  String get trackInTransit => 'ගමනේ';

  @override
  String get trackOutForDelivery => 'Deliver කරන්න ගිහින්';

  @override
  String get trackDelivered => 'Deliver කළා';

  @override
  String get trackFailed => 'Delivery අසාර්ථකයි';

  @override
  String get trackReturned => 'ආපහු ආවා';

  @override
  String get trackCancelled => 'අවලංගුයි';

  @override
  String get trackNone => 'තාම track වෙලා නැහැ';

  @override
  String get labelLoadFailed =>
      'තාම label එකක් නැහැ. Waybill එකක් නැහැ: මුලින්ම pickup එකක් ඉල්ලන්න.';

  @override
  String get alertsServerOk => 'සම්බන්ධයි: server එක මේ phone එක දන්නවා';

  @override
  String get alertsServerFailed => 'සම්බන්ධ නැහැ: මේ phone එක නාද වෙන්නේ නැහැ';

  @override
  String get alertsRetry => 'ආයේ උත්සාහ කරන්න';
}
