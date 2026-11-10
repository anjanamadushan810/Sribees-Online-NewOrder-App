import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Languages the app ships in. Sinhala is the default (owner, 2026-11-10).
const supportedLanguageCodes = ['si', 'en'];
const defaultLanguageCode = 'si';

/// The app's language, remembered on this device.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale(defaultLanguageCode)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(AppConstants.prefLanguage);
      if (code != null && supportedLanguageCodes.contains(code)) {
        state = Locale(code);
      }
    } catch (_) {
      // Unreadable preferences: stay on the default language.
    }
  }

  Future<void> setLanguage(String code) async {
    if (!supportedLanguageCodes.contains(code)) return;
    state = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefLanguage, code);
    } catch (_) {
      // The choice still applies for this session.
    }
  }

  Future<void> toggle() =>
      setLanguage(state.languageCode == 'si' ? 'en' : 'si');
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
