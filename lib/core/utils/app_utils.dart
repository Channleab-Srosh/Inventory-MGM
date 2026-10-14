import 'package:intl/intl.dart';

/// Utility helpers used across the app
class AppUtils {
  /// Format a double as currency
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format a DateTime to "Jan 15, 2025"
  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  /// Format a DateTime to "Jan 15, 2025 · 10:30 AM"
  static String formatDateTime(DateTime date) =>
      DateFormat('MMM d, yyyy · h:mm a').format(date);

  /// Format a DateTime to relative like "2 hours ago"
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// Format a DateTime to time only "10:30 AM"
  static String formatTime(DateTime date) =>
      DateFormat('h:mm a').format(date);

  /// Format number with commas: 1,234
  static String formatNumber(int n) => NumberFormat('#,##0').format(n);
}
