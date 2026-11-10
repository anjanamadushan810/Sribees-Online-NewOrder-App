import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orders opened on THIS phone, so a waiting order keeps its NEW dot until
/// someone here has looked at it. Newest first, capped.
class SeenOrdersNotifier extends StateNotifier<List<String>> {
  SeenOrdersNotifier() : super(const []) {
    _load();
  }

  static const prefKey = 'sbno_seen_orders';
  static const cap = 300;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(prefKey) ?? const [];
      // Keep anything marked while loading.
      state = [...state, ...saved.where((id) => !state.contains(id))].take(cap).toList();
    } catch (_) {}
  }

  bool isSeen(String orderId) => state.contains(orderId);

  Future<void> markSeen(String orderId) async {
    if (state.isNotEmpty && state.first == orderId) return;
    state = [orderId, ...state.where((id) => id != orderId)].take(cap).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefKey, state);
    } catch (_) {}
  }
}

final seenOrdersProvider =
    StateNotifierProvider<SeenOrdersNotifier, List<String>>((ref) => SeenOrdersNotifier());
