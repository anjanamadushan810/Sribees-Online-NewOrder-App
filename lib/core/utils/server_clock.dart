import 'dart:io' show HttpDate;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now" according to the server, never the phone (a phone's clock can be
/// minutes or days off, which would make every "placed 5 min ago" wrong).
///
/// Each API response's `Date` header updates the offset; until the first
/// one arrives the device clock is used.
class ServerClock {
  Duration _offset = Duration.zero;
  bool _synced = false;

  bool get isSynced => _synced;

  DateTime now() => DateTime.now().toUtc().add(_offset);

  /// Feed a response `Date` header (RFC 1123). Ignores junk.
  void syncFromHeader(String? dateHeader, {DateTime? receivedAt}) {
    if (dateHeader == null || dateHeader.isEmpty) return;
    try {
      final server = HttpDate.parse(dateHeader).toUtc();
      final local = (receivedAt ?? DateTime.now()).toUtc();
      _offset = server.difference(local);
      _synced = true;
    } catch (_) {}
  }
}

final serverClockProvider = Provider<ServerClock>((ref) => ServerClock());

/// Sri Lanka has no daylight saving: Asia/Colombo is always UTC+05:30.
const colomboOffset = Duration(hours: 5, minutes: 30);

DateTime toColombo(DateTime utc) => utc.toUtc().add(colomboOffset);

/// Midnight (Colombo) of the given instant, as a `YYYY-MM-DD` string.
String colomboDate(DateTime utc) {
  final c = toColombo(utc);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${c.year}-${two(c.month)}-${two(c.day)}';
}
