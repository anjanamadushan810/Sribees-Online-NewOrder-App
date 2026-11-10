import 'package:intl/intl.dart';

/// Formatting utilities for Sribees Price
class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  /// Format decimal/double amount to 'Rs. 1,250.00'
  static String formatCurrency(num? amount) {
    if (amount == null) return 'Rs. 0.00';
    return _currencyFormat.format(amount);
  }

  /// Alias for formatCurrency
  static String formatLkr(num? amount) => formatCurrency(amount);

  /// Format round figures without decimals e.g. 'Rs. 1,250'
  static String formatCompactCurrency(num? amount) {
    if (amount == null) return 'Rs. 0';
    return _compactCurrency.format(amount);
  }

  /// Format date time into friendly local time string (e.g. 'Oct 24, 01:15 PM')
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MMM d, hh:mm a').format(dateTime.toLocal());
  }

  /// Format short date string (e.g. 'Oct 24, 2026')
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MMM d, yyyy').format(dateTime.toLocal());
  }
}
