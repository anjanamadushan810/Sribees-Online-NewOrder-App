/// Links that hand the customer's details to the phone's own apps.
class ContactLinks {
  ContactLinks._();

  /// Digits only, Sri Lankan numbers in international form (94XXXXXXXXX).
  /// "077 123 4567", "+94771234567", "0094771234567" and "771234567" all
  /// become "94771234567". Returns null when nothing usable is left.
  static String? internationalLk(String? phone) {
    if (phone == null) return null;
    var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return null;
    if (d.startsWith('0094')) d = d.substring(2);
    if (d.startsWith('94') && d.length == 11) return d;
    if (d.startsWith('0') && d.length == 10) return '94${d.substring(1)}';
    if (d.length == 9) return '94$d';
    return d.length >= 7 ? d : null;
  }

  static Uri? tel(String? phone) {
    final n = internationalLk(phone);
    return n == null ? null : Uri(scheme: 'tel', path: '+$n');
  }

  static Uri? whatsapp(String? phone) {
    final n = internationalLk(phone);
    return n == null ? null : Uri.https('wa.me', '/$n');
  }

  /// Google Maps search for the address text (works with or without the
  /// Maps app installed).
  static Uri? maps(List<String> addressLines) {
    final q = addressLines.where((l) => l.trim().isNotEmpty).join(', ');
    if (q.isEmpty) return null;
    return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': q});
  }
}
