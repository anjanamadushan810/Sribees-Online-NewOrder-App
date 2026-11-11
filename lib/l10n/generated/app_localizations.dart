import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sribees New Orders'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your branch\'s orders, the moment they arrive'**
  String get appTagline;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get switchLanguage;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the email and password you use on the Sribees admin web.'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is wrong, or this account is disabled.'**
  String get errInvalidCredentials;

  /// No description provided for @errNoOrderAccess.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t see orders. Ask a super admin for the Orders permission.'**
  String get errNoOrderAccess;

  /// No description provided for @errNoBranch.
  ///
  /// In en, this message translates to:
  /// **'This account has no branch assigned. Ask a super admin to assign one.'**
  String get errNoBranch;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'You were signed out. Please sign in again.'**
  String get errSessionExpired;

  /// No description provided for @errOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check Wi-Fi or mobile data.'**
  String get errOffline;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server is taking too long. Try again.'**
  String get errTimeout;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server. Try again shortly.'**
  String get errServer;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errUnknown;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String hello(String name);

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// No description provided for @actConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get actConfirmOrder;

  /// No description provided for @actCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get actCancelOrder;

  /// No description provided for @actStartPacking.
  ///
  /// In en, this message translates to:
  /// **'Start packing'**
  String get actStartPacking;

  /// No description provided for @actMarkPacked.
  ///
  /// In en, this message translates to:
  /// **'Mark as packed'**
  String get actMarkPacked;

  /// No description provided for @actReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for courier pickup'**
  String get actReadyForPickup;

  /// No description provided for @actMarkShipped.
  ///
  /// In en, this message translates to:
  /// **'Mark as shipped'**
  String get actMarkShipped;

  /// No description provided for @actOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get actOutForDelivery;

  /// No description provided for @actMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered'**
  String get actMarkDelivered;

  /// No description provided for @actDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery failed'**
  String get actDeliveryFailed;

  /// No description provided for @actReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule delivery'**
  String get actReschedule;

  /// No description provided for @actRto.
  ///
  /// In en, this message translates to:
  /// **'Return to hub (RTO)'**
  String get actRto;

  /// No description provided for @confirmMove.
  ///
  /// In en, this message translates to:
  /// **'Order {number} will become \"{status}\".'**
  String confirmMove(String number, String status);

  /// No description provided for @notifyNote.
  ///
  /// In en, this message translates to:
  /// **'The customer gets an automatic message.'**
  String get notifyNote;

  /// No description provided for @courierBookNote.
  ///
  /// In en, this message translates to:
  /// **'This books a SribeesExpress rider to collect the parcel.'**
  String get courierBookNote;

  /// No description provided for @cancelNote.
  ///
  /// In en, this message translates to:
  /// **'The order is cancelled and its stock goes back. The app can\'t undo this.'**
  String get cancelNote;

  /// No description provided for @pickupNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This branch isn\'t registered for SribeesExpress pickup, so the rider may go to another address.'**
  String get pickupNotRegistered;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @statusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status updated: {status}'**
  String statusChanged(String status);

  /// No description provided for @statusChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the status.'**
  String get statusChangeFailed;

  /// No description provided for @readOnlyInfo.
  ///
  /// In en, this message translates to:
  /// **'Your role can view this order but not change it.'**
  String get readOnlyInfo;

  /// No description provided for @noFurtherSteps.
  ///
  /// In en, this message translates to:
  /// **'No further steps from the app for this order.'**
  String get noFurtherSteps;

  /// No description provided for @secCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get secCustomer;

  /// No description provided for @secAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get secAddress;

  /// No description provided for @secItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get secItems;

  /// No description provided for @secPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get secPayment;

  /// No description provided for @secHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get secHistory;

  /// No description provided for @secNote.
  ///
  /// In en, this message translates to:
  /// **'Customer note'**
  String get secNote;

  /// No description provided for @secSlot.
  ///
  /// In en, this message translates to:
  /// **'Delivery slot'**
  String get secSlot;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @openMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openMaps;

  /// No description provided for @cannotOpen.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open that.'**
  String get cannotOpen;

  /// No description provided for @placedAt.
  ///
  /// In en, this message translates to:
  /// **'Placed {time}'**
  String placedAt(String time);

  /// No description provided for @qtyTimes.
  ///
  /// In en, this message translates to:
  /// **'{qty} × {price}'**
  String qtyTimes(int qty, String price);

  /// No description provided for @payCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get payCod;

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payCard;

  /// No description provided for @payWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get payWallet;

  /// No description provided for @payBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get payBank;

  /// No description provided for @codToCollect.
  ///
  /// In en, this message translates to:
  /// **'Cash to collect'**
  String get codToCollect;

  /// No description provided for @priceSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get priceSubtotal;

  /// No description provided for @priceDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get priceDelivery;

  /// No description provided for @priceDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get priceDiscount;

  /// No description provided for @priceWallet.
  ///
  /// In en, this message translates to:
  /// **'Paid from wallet'**
  String get priceWallet;

  /// No description provided for @priceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get priceTotal;

  /// No description provided for @orderLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this order.'**
  String get orderLoadFailed;

  /// No description provided for @orderOtherBranch.
  ///
  /// In en, this message translates to:
  /// **'This order belongs to another branch.'**
  String get orderOtherBranch;

  /// No description provided for @stepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get stepConfirmed;

  /// No description provided for @stepPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get stepPacking;

  /// No description provided for @stepPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get stepPacked;

  /// No description provided for @stepCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get stepCourier;

  /// No description provided for @stepOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get stepOnTheWay;

  /// No description provided for @stepDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stepDelivered;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tabNew;

  /// No description provided for @tabWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get tabWarehouse;

  /// No description provided for @tabLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get tabLogistics;

  /// No description provided for @tabDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get tabDelivered;

  /// No description provided for @tabReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get tabReturns;

  /// No description provided for @tabExceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get tabExceptions;

  /// No description provided for @pillAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pillAll;

  /// No description provided for @pillPackedReady.
  ///
  /// In en, this message translates to:
  /// **'Packed (ready)'**
  String get pillPackedReady;

  /// No description provided for @pillQc.
  ///
  /// In en, this message translates to:
  /// **'QC pending'**
  String get pillQc;

  /// No description provided for @statusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get statusAwaitingPayment;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get statusPacking;

  /// No description provided for @statusPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get statusPacked;

  /// No description provided for @statusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Awaiting courier'**
  String get statusReadyForPickup;

  /// No description provided for @statusHandedToCourier.
  ///
  /// In en, this message translates to:
  /// **'Handed to courier'**
  String get statusHandedToCourier;

  /// No description provided for @statusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get statusShipped;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get statusOutForDelivery;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery failed'**
  String get statusDeliveryFailed;

  /// No description provided for @statusRtoInitiated.
  ///
  /// In en, this message translates to:
  /// **'Returning to store'**
  String get statusRtoInitiated;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusReturnRequested.
  ///
  /// In en, this message translates to:
  /// **'Return requested'**
  String get statusReturnRequested;

  /// No description provided for @statusReturnApproved.
  ///
  /// In en, this message translates to:
  /// **'Return approved'**
  String get statusReturnApproved;

  /// No description provided for @statusReturnRejected.
  ///
  /// In en, this message translates to:
  /// **'Return rejected'**
  String get statusReturnRejected;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @paymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentPaid;

  /// No description provided for @paymentCod.
  ///
  /// In en, this message translates to:
  /// **'COD'**
  String get paymentCod;

  /// No description provided for @paymentRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentRefunded;

  /// No description provided for @courierNotBooked.
  ///
  /// In en, this message translates to:
  /// **'Not booked with SribeesExpress yet. It is booked when the order is marked ready for pickup.'**
  String get courierNotBooked;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @agoJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get agoJustNow;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String agoMinutes(int n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String agoHours(int n);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String agoDays(int n);

  /// No description provided for @waitingTooLong.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {minutes} min'**
  String waitingTooLong(int minutes);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Order no., customer name or email'**
  String get searchHint;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get rangeAll;

  /// No description provided for @rangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rangeToday;

  /// No description provided for @range7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get range7;

  /// No description provided for @range30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get range30;

  /// No description provided for @branchFilter.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchFilter;

  /// No description provided for @noOrdersHere.
  ///
  /// In en, this message translates to:
  /// **'No orders here'**
  String get noOrdersHere;

  /// No description provided for @noOrdersForSearch.
  ///
  /// In en, this message translates to:
  /// **'No orders match \"{query}\"'**
  String noOrdersForSearch(String query);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load orders.'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @showingSavedList.
  ///
  /// In en, this message translates to:
  /// **'Showing the last list loaded.'**
  String get showingSavedList;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @branchLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchLabel;

  /// No description provided for @allBranches.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get allBranches;

  /// No description provided for @assignedBranch.
  ///
  /// In en, this message translates to:
  /// **'Assigned branch'**
  String get assignedBranch;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @roleBranchManager.
  ///
  /// In en, this message translates to:
  /// **'Branch Manager'**
  String get roleBranchManager;

  /// No description provided for @roleMarketingManager.
  ///
  /// In en, this message translates to:
  /// **'Marketing Manager'**
  String get roleMarketingManager;

  /// No description provided for @roleInventoryManager.
  ///
  /// In en, this message translates to:
  /// **'Inventory Manager'**
  String get roleInventoryManager;

  /// No description provided for @roleCustomerSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer Support'**
  String get roleCustomerSupport;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @roleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleUnknown;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This phone won\'t get new-order alerts until you sign in again.'**
  String get signOutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @alertsPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ring for new orders?'**
  String get alertsPermissionTitle;

  /// No description provided for @alertsPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so this phone rings the moment a new order arrives for your branch.'**
  String get alertsPermissionBody;

  /// No description provided for @alertsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get alertsAllow;

  /// No description provided for @alertsNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get alertsNotNow;

  /// No description provided for @newOrderArrived.
  ///
  /// In en, this message translates to:
  /// **'New order #{orderNumber}'**
  String newOrderArrived(String orderNumber);

  /// No description provided for @newOrderArrivedNoNumber.
  ///
  /// In en, this message translates to:
  /// **'A new order arrived'**
  String get newOrderArrivedNoNumber;

  /// No description provided for @alertView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get alertView;

  /// No description provided for @alertsSection.
  ///
  /// In en, this message translates to:
  /// **'New-order alerts'**
  String get alertsSection;

  /// No description provided for @alertsOn.
  ///
  /// In en, this message translates to:
  /// **'On: this phone rings for new orders'**
  String get alertsOn;

  /// No description provided for @alertsOff.
  ///
  /// In en, this message translates to:
  /// **'Off: notifications are blocked for this app'**
  String get alertsOff;

  /// No description provided for @alertsOffHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications for Sribees New Orders in the phone\'s Settings.'**
  String get alertsOffHint;

  /// No description provided for @alertsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available in this build'**
  String get alertsUnavailable;

  /// No description provided for @alertsTestSound.
  ///
  /// In en, this message translates to:
  /// **'Test the sound'**
  String get alertsTestSound;

  /// No description provided for @secCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get secCourier;

  /// No description provided for @courierWaybill.
  ///
  /// In en, this message translates to:
  /// **'Waybill'**
  String get courierWaybill;

  /// No description provided for @courierStatus.
  ///
  /// In en, this message translates to:
  /// **'Courier status'**
  String get courierStatus;

  /// No description provided for @courierCollectFrom.
  ///
  /// In en, this message translates to:
  /// **'Collect from'**
  String get courierCollectFrom;

  /// No description provided for @courierRiderCollects.
  ///
  /// In en, this message translates to:
  /// **'Rider collects'**
  String get courierRiderCollects;

  /// No description provided for @courierPrepaid.
  ///
  /// In en, this message translates to:
  /// **'Paid: nothing to collect'**
  String get courierPrepaid;

  /// No description provided for @courierCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get courierCashCollected;

  /// No description provided for @courierCashNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not collected yet'**
  String get courierCashNotYet;

  /// No description provided for @courierShortfall.
  ///
  /// In en, this message translates to:
  /// **'not collected'**
  String get courierShortfall;

  /// No description provided for @courierHandover.
  ///
  /// In en, this message translates to:
  /// **'Handover code'**
  String get courierHandover;

  /// No description provided for @courierHandoverWaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting the customer\'s code'**
  String get courierHandoverWaiting;

  /// No description provided for @courierHandoverDone.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get courierHandoverDone;

  /// No description provided for @courierBookingFailed.
  ///
  /// In en, this message translates to:
  /// **'The pickup booking was refused. Try again, or check the order on the admin web.'**
  String get courierBookingFailed;

  /// No description provided for @courierRequestPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for courier pickup'**
  String get courierRequestPickup;

  /// No description provided for @courierRetryBooking.
  ///
  /// In en, this message translates to:
  /// **'Retry booking'**
  String get courierRetryBooking;

  /// No description provided for @courierRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh tracking'**
  String get courierRefresh;

  /// No description provided for @courierLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get courierLabel;

  /// No description provided for @courierLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping label'**
  String get courierLabelTitle;

  /// No description provided for @courierPickupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for courier pickup?'**
  String get courierPickupConfirmTitle;

  /// No description provided for @courierPickupConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'SribeesExpress will send a rider to collect this parcel.'**
  String get courierPickupConfirmBody;

  /// No description provided for @courierUnregisteredNote.
  ///
  /// In en, this message translates to:
  /// **'This branch is not registered as a pickup point, so the rider goes to the main account\'s address.'**
  String get courierUnregisteredNote;

  /// No description provided for @courierFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach SribeesExpress.'**
  String get courierFailed;

  /// No description provided for @trackBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked: awaiting rider'**
  String get trackBooked;

  /// No description provided for @trackPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get trackPickedUp;

  /// No description provided for @trackInTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get trackInTransit;

  /// No description provided for @trackOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get trackOutForDelivery;

  /// No description provided for @trackDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get trackDelivered;

  /// No description provided for @trackFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery failed'**
  String get trackFailed;

  /// No description provided for @trackReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned to us'**
  String get trackReturned;

  /// No description provided for @trackCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trackCancelled;

  /// No description provided for @trackNone.
  ///
  /// In en, this message translates to:
  /// **'Not tracked yet'**
  String get trackNone;

  /// No description provided for @labelLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'No label yet. This parcel has no waybill: request a pickup first.'**
  String get labelLoadFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
