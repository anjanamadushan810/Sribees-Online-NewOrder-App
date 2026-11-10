import 'package:flutter/services.dart' show appFlavor;

/// Which backend this build talks to, chosen by the Android product flavor
/// (`flutter build apk --flavor dev|prod`). The flavor is baked in at build
/// time, so a dev APK can never reach production by accident.
enum AppEnv {
  dev(
    label: 'DEV',
    apiBaseUrl: 'https://devapionline.sribees.com/api/v1',
  ),
  prod(
    label: '',
    apiBaseUrl: 'https://api.sribeesonline.com/api/v1',
  );

  const AppEnv({required this.label, required this.apiBaseUrl});

  /// Short badge shown next to the app name; empty for production.
  final String label;
  final String apiBaseUrl;

  bool get isProd => this == AppEnv.prod;

  /// Resolve a flavor name. Anything that is not exactly "prod" (including
  /// no flavor at all, as in `flutter test`) is dev: the safe side.
  static AppEnv fromFlavor(String? flavor) =>
      flavor == 'prod' ? AppEnv.prod : AppEnv.dev;

  static final AppEnv current = fromFlavor(appFlavor);
}
