import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/core/config/app_env.dart';

void main() {
  test('only the exact "prod" flavor reaches production', () {
    expect(AppEnv.fromFlavor('prod'), AppEnv.prod);
    expect(AppEnv.fromFlavor('dev'), AppEnv.dev);
    expect(AppEnv.fromFlavor(null), AppEnv.dev);
    expect(AppEnv.fromFlavor('Prod'), AppEnv.dev);
    expect(AppEnv.fromFlavor(''), AppEnv.dev);
  });

  test('each flavor points at its own backend', () {
    expect(AppEnv.prod.apiBaseUrl, 'https://api.sribeesonline.com/api/v1');
    expect(AppEnv.dev.apiBaseUrl, 'https://devapionline.sribees.com/api/v1');
  });
}
