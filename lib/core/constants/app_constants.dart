/// Global constants for Sribees New Orders.
class AppConstants {
  AppConstants._();

  static const String appName = 'Sribees New Orders';

  // Secure storage keys
  static const String keyAccessToken = 'sbno_access_token';
  static const String keyRefreshToken = 'sbno_refresh_token';
  static const String keyUserData = 'sbno_user_data';
  static const String keySelectedBranchId = 'sbno_selected_branch_id';
  static const String keySelectedBranchName = 'sbno_selected_branch_name';

  // Preferences
  static const String prefLanguage = 'sbno_language';

  // Network timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
