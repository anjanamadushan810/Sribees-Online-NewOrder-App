import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The INSTALLED build's version ("0.1.0+1"), read from the package, never
/// typed by hand: it must equal pubspec.yaml and the APK (owner rule).
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});
