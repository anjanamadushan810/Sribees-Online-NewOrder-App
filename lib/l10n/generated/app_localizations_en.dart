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
  String get actConfirmOrder => 'Confirm order';

  @override
  String get actCancelOrder => 'Cancel order';

  @override
  String get actStartPacking => 'Start packing';

  @override
  String get actMarkPacked => 'Mark as packed';

  @override
  String get actReadyForPickup => 'Ready for courier pickup';

  @override
  String get actMarkShipped => 'Mark as shipped';

  @override
  String get actOutForDelivery => 'Out for delivery';

  @override
  String get actMarkDelivered => 'Mark as delivered';

  @override
  String get actDeliveryFailed => 'Delivery failed';

  @override
  String get actReschedule => 'Reschedule delivery';

  @override
  String get actRto => 'Return to hub (RTO)';

  @override
  String confirmMove(String number, String status) {
    return 'Order $number will become \"$status\".';
  }

  @override
  String get notifyNote => 'The customer gets an automatic message.';

  @override
  String get courierBookNote =>
      'This books a SribeesExpress rider to collect the parcel.';

  @override
  String get cancelNote =>
      'The order is cancelled and its stock goes back. The app can\'t undo this.';

  @override
  String get pickupNotRegistered =>
      'This branch isn\'t registered for SribeesExpress pickup, so the rider may go to another address.';

  @override
  String get yes => 'Yes';

  @override
  String statusChanged(String status) {
    return 'Status updated: $status';
  }

  @override
  String get statusChangeFailed => 'Couldn\'t change the status.';

  @override
  String get readOnlyInfo => 'Your role can view this order but not change it.';

  @override
  String get noFurtherSteps => 'No further steps from the app for this order.';

  @override
  String get secCustomer => 'Customer';

  @override
  String get secAddress => 'Delivery address';

  @override
  String get secItems => 'Items';

  @override
  String get secPayment => 'Payment';

  @override
  String get secHistory => 'History';

  @override
  String get secNote => 'Customer note';

  @override
  String get secSlot => 'Delivery slot';

  @override
  String get call => 'Call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get openMaps => 'Open in Maps';

  @override
  String get cannotOpen => 'No app on this phone can open that.';

  @override
  String placedAt(String time) {
    return 'Placed $time';
  }

  @override
  String qtyTimes(int qty, String price) {
    return '$qty × $price';
  }

  @override
  String get payCod => 'Cash on delivery';

  @override
  String get payCard => 'Card';

  @override
  String get payWallet => 'Wallet';

  @override
  String get payBank => 'Bank transfer';

  @override
  String get codToCollect => 'Cash to collect';

  @override
  String get priceSubtotal => 'Items';

  @override
  String get priceDelivery => 'Delivery';

  @override
  String get priceDiscount => 'Discount';

  @override
  String get priceWallet => 'Paid from wallet';

  @override
  String get priceTotal => 'Total';

  @override
  String get orderLoadFailed => 'Couldn\'t load this order.';

  @override
  String get orderOtherBranch => 'This order belongs to another branch.';

  @override
  String get stepConfirmed => 'Confirmed';

  @override
  String get stepPacking => 'Packing';

  @override
  String get stepPacked => 'Packed';

  @override
  String get stepCourier => 'Courier';

  @override
  String get stepOnTheWay => 'On the way';

  @override
  String get stepDelivered => 'Delivered';

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
  String get courierNotBooked =>
      'Not booked with SribeesExpress yet. It is booked when the order is marked ready for pickup.';

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

  @override
  String get alertsPermissionTitle => 'Ring for new orders?';

  @override
  String get alertsPermissionBody =>
      'Allow notifications so this phone rings the moment a new order arrives for your branch.';

  @override
  String get alertsAllow => 'Allow';

  @override
  String get alertsNotNow => 'Not now';

  @override
  String newOrderArrived(String orderNumber) {
    return 'New order #$orderNumber';
  }

  @override
  String get newOrderArrivedNoNumber => 'A new order arrived';

  @override
  String get alertView => 'View';

  @override
  String get alertsSection => 'New-order alerts';

  @override
  String get alertsOn => 'On: this phone rings for new orders';

  @override
  String get alertsOff => 'Off: notifications are blocked for this app';

  @override
  String get alertsOffHint =>
      'Turn on notifications for Sribees New Orders in the phone\'s Settings.';

  @override
  String get alertsUnavailable => 'Not available in this build';

  @override
  String get alertsTestSound => 'Test the sound';

  @override
  String get secCourier => 'Courier';

  @override
  String get courierWaybill => 'Waybill';

  @override
  String get courierStatus => 'Courier status';

  @override
  String get courierCollectFrom => 'Collect from';

  @override
  String get courierRiderCollects => 'Rider collects';

  @override
  String get courierPrepaid => 'Paid: nothing to collect';

  @override
  String get courierCashCollected => 'Cash collected';

  @override
  String get courierCashNotYet => 'Not collected yet';

  @override
  String get courierShortfall => 'not collected';

  @override
  String get courierHandover => 'Handover code';

  @override
  String get courierHandoverWaiting => 'Awaiting the customer\'s code';

  @override
  String get courierHandoverDone => 'Verified';

  @override
  String get courierBookingFailed =>
      'The pickup booking was refused. Try again, or check the order on the admin web.';

  @override
  String get courierRequestPickup => 'Ready for courier pickup';

  @override
  String get courierRetryBooking => 'Retry booking';

  @override
  String get courierRefresh => 'Refresh tracking';

  @override
  String get courierLabel => 'Label';

  @override
  String get courierLabelTitle => 'Shipping label';

  @override
  String get courierPickupConfirmTitle => 'Ready for courier pickup?';

  @override
  String get courierPickupConfirmBody =>
      'SribeesExpress will send a rider to collect this parcel.';

  @override
  String get courierUnregisteredNote =>
      'This branch is not registered as a pickup point, so the rider goes to the main account\'s address.';

  @override
  String get courierFailed => 'Could not reach SribeesExpress.';

  @override
  String get trackBooked => 'Booked: awaiting rider';

  @override
  String get trackPickedUp => 'Picked up';

  @override
  String get trackInTransit => 'In transit';

  @override
  String get trackOutForDelivery => 'Out for delivery';

  @override
  String get trackDelivered => 'Delivered';

  @override
  String get trackFailed => 'Delivery failed';

  @override
  String get trackReturned => 'Returned to us';

  @override
  String get trackCancelled => 'Cancelled';

  @override
  String get trackNone => 'Not tracked yet';

  @override
  String get labelLoadFailed =>
      'No label yet. This parcel has no waybill: request a pickup first.';
}
