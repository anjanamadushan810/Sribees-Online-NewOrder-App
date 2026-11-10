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
  String get ordersComingSoon => 'The orders list arrives in the next update.';

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
