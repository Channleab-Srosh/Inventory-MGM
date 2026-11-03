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

  // ==========================================
  // Validation Helpers
  // ==========================================

  /// Validates password complexity:
  /// - Minimum 8 characters
  /// - At least one uppercase letter (A-Z)
  /// - At least one lowercase letter (a-z)
  /// - At least one digit (0-9)
  /// - At least one special character (!@#$%&* etc.)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must include at least one uppercase letter (A-Z)';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Must include at least one lowercase letter (a-z)';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must include at least one number (0-9)';
    }
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=~`]'))) {
      return 'Must include at least one special character (!@#\$%&* etc.)';
    }
    return null;
  }

  /// Validates password confirmation
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates new password when changing password:
  /// - Satisfies password complexity rules
  /// - Cannot match current password
  static String? validateNewPassword(String? value, String currentPassword) {
    final basicError = validatePassword(value);
    if (basicError != null) return basicError;
    if (value == currentPassword) {
      return 'New password cannot be the same as current password';
    }
    return null;
  }

  /// Validates username format and length
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3 || trimmed.length > 50) {
      return 'Username must be between 3 and 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(trimmed)) {
      return 'Only letters, numbers, underscores, dots, and hyphens allowed';
    }
    return null;
  }

  /// Validates Gmail format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@gmail\.com$');
    if (!gmailRegex.hasMatch(trimmed)) {
      return 'Only Gmail addresses (@gmail.com) are allowed';
    }
    return null;
  }

  /// Validates first name / last name
  static String? validateNamePart(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 50) {
      return '$fieldName must be between 2 and 50 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'\-\.]+$").hasMatch(trimmed)) {
      return 'Only letters, spaces, and hyphens allowed';
    }
    return null;
  }

  /// Validates optional phone number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\+?[0-9\s\-]{8,20}$').hasMatch(trimmed)) {
      return 'Enter a valid phone number (8-20 digits)';
    }
    return null;
  }

  /// Validates 6-digit OTP code
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP code is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be exactly 6 digits';
    }
    return null;
  }
}
