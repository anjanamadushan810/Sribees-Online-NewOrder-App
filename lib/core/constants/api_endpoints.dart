import '../config/app_env.dart';

/// API endpoints of the Sribees Online backend used by Sribees New Orders.
class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL for this build's flavor (dev or prod).
  static String get baseUrl => AppEnv.current.apiBaseUrl;

  // Auth
  static const String login = '/admin/auth/login';
  static const String me = '/admin/auth/profile';
  static const String refresh = '/admin/auth/refresh';
  static const String logout = '/admin/auth/logout';

  // Branches
  static const String branches = '/admin/branches';

  // Orders (same endpoints as the admin web Orders page)
  static const String orders = '/admin/orders';

  // This phone, for new-order alerts
  static const String staffPushTokens = '/admin/push-tokens';
}
