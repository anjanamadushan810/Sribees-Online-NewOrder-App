import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sribees_new_orders/core/providers/app_version_provider.dart';
import 'package:sribees_new_orders/core/providers/core_providers.dart';
import 'package:sribees_new_orders/features/auth/models/admin_user.dart';
import 'package:sribees_new_orders/features/auth/providers/auth_provider.dart';
import 'package:sribees_new_orders/main.dart';

import 'helpers/fakes.dart';

late MemoryStorage storage;
late FakeAuthRepository repo;

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '0.2.0+2'),
        secureStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repo),
      ],
      child: const SribeesNewOrdersApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester, {String password = 'pw'}) async {
  await tester.enterText(find.byKey(const Key('login-email')), 'nimal@sribees.lk');
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    storage = MemoryStorage();
    repo = FakeAuthRepository(storage);
  });

  testWidgets('opens on the Sinhala login screen; DEV ribbon on test builds', (tester) async {
    await pumpApp(tester);
    expect(find.text('ලොග් වෙන්න'), findsOneWidget);
    expect(find.byType(Banner), findsOneWidget);
  });

  testWidgets('empty form shows both field errors and calls nothing', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email ලිපිනය දාන්න'), findsOneWidget);
    expect(find.text('මුරපදය දාන්න'), findsOneWidget);
    expect(repo.lastEmail, isNull);
  });

  testWidgets('a malformed email is caught before the server', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('login-email')), 'nimal');
    await tester.enterText(find.byKey(const Key('login-password')), 'pw');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email ලිපිනය හරි නෑ'), findsOneWidget);
    expect(repo.lastEmail, isNull);
  });

  testWidgets('wrong password shows the Sinhala reason and clears the password', (tester) async {
    repo.loginResult = apiError(401);
    await pumpApp(tester);
    await signIn(tester, password: 'bad');
    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.textContaining('මුරපදය වැරදියි'), findsOneWidget);
    final pw = tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('login-password')), matching: find.byType(EditableText)));
    expect(pw.controller.text, isEmpty);
  });

  testWidgets('password eye toggles visibility', (tester) async {
    await pumpApp(tester);
    EditableText field() => tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('login-password')), matching: find.byType(EditableText)));
    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('login-password-toggle')));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('branch manager: login -> home -> settings shows role + branch -> sign out',
      (tester) async {
    await pumpApp(tester);
    await signIn(tester);

    expect(find.text('ආයුබෝවන්, Nimal Perera'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('settings-role'))).data, 'ශාඛා කළමනාකරු');
    expect(tester.widget<Text>(find.byKey(const Key('settings-branch'))).data, 'Matugama');
    expect(find.textContaining('සංස්කරණය 0.2.0+2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('signout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signout-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(repo.logoutCalls, 1);
    expect(storage.data, isEmpty);
  });

  testWidgets('super admin sees "all branches"', (tester) async {
    repo.loginResult = AdminUser.fromJson(adminJson(role: 'super_admin', branchId: null));
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('settings-branch'))).data, 'සියලුම ශාඛා');
  });

  testWidgets('switching to English in Settings changes the whole app', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('settings-role'))).data, 'Branch Manager');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sbno_language'), 'en');
  });

  testWidgets('language button on the login screen switches to English', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('language-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });
}
