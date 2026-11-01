import 'dart:math' as math;
import 'package:intl/intl.dart';

/// Utility helpers used across the app
class AppUtils {
  /// Format a double as currency
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Generate a secure random password (minimum 10 chars with uppercase, lowercase, digits, and special characters)
  static String generateRandomPassword({int length = 10}) {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const digits = '23456789';
    const special = '!@#\$%&*';
    const all = upper + lower + digits + special;

    final rnd = math.Random.secure();
    final chars = <String>[
      upper[rnd.nextInt(upper.length)],
      lower[rnd.nextInt(lower.length)],
      digits[rnd.nextInt(digits.length)],
      special[rnd.nextInt(special.length)],
    ];
    for (int i = 4; i < length; i++) {
      chars.add(all[rnd.nextInt(all.length)]);
    }
    chars.shuffle(rnd);
    return chars.join();
  }

  /// Format a DateTime to "Jan 15, 2025"
  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date.toLocal());

  /// Format a DateTime to "Jan 15, 2025 · 10:30 AM"
  static String formatDateTime(DateTime date) =>
      DateFormat('MMM d, yyyy · h:mm a').format(date.toLocal());

  /// Format a DateTime to relative like "2 hours ago"
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// Format a DateTime to time only "10:30 AM"
  static String formatTime(DateTime date) =>
      DateFormat('h:mm a').format(date.toLocal());

  /// Format number with commas: 1,234
  static String formatNumber(int n) => NumberFormat('#,##0').format(n);
}
