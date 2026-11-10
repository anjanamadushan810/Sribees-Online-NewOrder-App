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
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get languageName => 'English';

  @override
  String get switchLanguage => 'Language';

  @override
  String get signInSubtitle =>
      'Use the email and password you use on the Sribees admin web.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'That doesn\'t look like an email address';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get errInvalidCredentials =>
      'Email or password is wrong, or this account is disabled.';

  @override
  String get errNoOrderAccess =>
      'This account can\'t see orders. Ask a super admin for the Orders permission.';

  @override
  String get errNoBranch =>
      'This account has no branch assigned. Ask a super admin to assign one.';

  @override
  String get errSessionExpired => 'You were signed out. Please sign in again.';

  @override
  String get errOffline =>
      'No internet connection. Check Wi-Fi or mobile data.';

  @override
  String get errTimeout => 'The server is taking too long. Try again.';

  @override
  String get errServer =>
      'Something went wrong on the server. Try again shortly.';

  @override
  String get errUnknown => 'Something went wrong. Try again.';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get ordersTitle => 'Orders';

  @override
  String get orderDetailsComingSoon =>
      'Full order details arrive in the next update.';

  @override
  String get tabAll => 'All';

  @override
  String get tabNew => 'New';

  @override
  String get tabWarehouse => 'Warehouse';

  @override
  String get tabLogistics => 'Logistics';

  @override
  String get tabDelivered => 'Delivered';

  @override
  String get tabReturns => 'Returns';

  @override
  String get tabExceptions => 'Exceptions';

  @override
  String get pillAll => 'All';

  @override
  String get pillPackedReady => 'Packed (ready)';

  @override
  String get pillQc => 'QC pending';

  @override
  String get statusAwaitingPayment => 'Awaiting payment';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusPacking => 'Packing';

  @override
  String get statusPacked => 'Packed';

  @override
  String get statusReadyForPickup => 'Awaiting courier';

  @override
  String get statusHandedToCourier => 'Handed to courier';

  @override
  String get statusShipped => 'Shipped';

  @override
  String get statusOutForDelivery => 'Out for delivery';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusDeliveryFailed => 'Delivery failed';

  @override
  String get statusRtoInitiated => 'Returning to store';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusReturnRequested => 'Return requested';

  @override
  String get statusReturnApproved => 'Return approved';

  @override
  String get statusReturnRejected => 'Return rejected';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get paymentPaid => 'Paid';

  @override
  String get paymentCod => 'COD';

  @override
  String get paymentRefunded => 'Refunded';

  @override
  String get courierNotBooked => 'Courier not booked';

  @override
  String get newBadge => 'NEW';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get agoJustNow => 'just now';

  @override
  String agoMinutes(int n) {
    return '$n min ago';
  }

  @override
  String agoHours(int n) {
    return '$n h ago';
  }

  @override
  String agoDays(int n) {
    return '$n d ago';
  }

  @override
  String waitingTooLong(int minutes) {
    return 'Waiting for $minutes min';
  }

  @override
  String get searchHint => 'Order no., customer name or email';

  @override
  String get rangeAll => 'Any date';

  @override
  String get rangeToday => 'Today';

  @override
  String get range7 => 'Last 7 days';

  @override
  String get range30 => 'Last 30 days';

  @override
  String get branchFilter => 'Branch';

  @override
  String get noOrdersHere => 'No orders here';

  @override
  String noOrdersForSearch(String query) {
    return 'No orders match \"$query\"';
  }

  @override
  String get loadFailed => 'Couldn\'t load orders.';

  @override
  String get retry => 'Try again';

  @override
  String get showingSavedList => 'Showing the last list loaded.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get roleLabel => 'Role';

  @override
  String get branchLabel => 'Branch';

  @override
  String get allBranches => 'All branches';

  @override
  String get assignedBranch => 'Assigned branch';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get roleBranchManager => 'Branch Manager';

  @override
  String get roleMarketingManager => 'Marketing Manager';

  @override
  String get roleInventoryManager => 'Inventory Manager';

  @override
  String get roleCustomerSupport => 'Customer Support';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleUnknown => 'Admin';

  @override
  String get aboutApp => 'About';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'This phone won\'t get new-order alerts until you sign in again.';

  @override
  String get cancel => 'Cancel';
}
