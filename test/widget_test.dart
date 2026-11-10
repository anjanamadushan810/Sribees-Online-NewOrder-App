import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sribees_new_orders/core/providers/app_version_provider.dart';
import 'package:sribees_new_orders/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '0.1.0+1'),
      ],
      child: const SribeesNewOrdersApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens in Sinhala and shows the installed version', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Sribees New Orders'), findsOneWidget);
    expect(find.text('ඔබේ ශාඛාවේ ඇණවුම්, ආපු ගමන්ම'), findsOneWidget);
    expect(find.text('සංස්කරණය 0.1.0+1'), findsOneWidget);
  });

  testWidgets('language button switches to English and remembers it', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('language-toggle')));
    await tester.pumpAndSettle();

    expect(find.text("Your branch's orders, the moment they arrive"), findsOneWidget);
    expect(find.text('Version 0.1.0+1'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sbno_language'), 'en');
  });

  testWidgets('a test build is the dev flavor and wears the DEV ribbon', (tester) async {
    await _pumpApp(tester);
    expect(find.byType(Banner), findsOneWidget);
  });
}
