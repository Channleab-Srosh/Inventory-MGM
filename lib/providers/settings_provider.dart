import 'package:flutter/material.dart';

/// Manages app settings: theme, currency, low-stock threshold, notifications
class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  int _lowStockThreshold = 10;
  String _currency = 'USD';
  String _currencySymbol = '\$';
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  int get lowStockThreshold => _lowStockThreshold;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  bool get notificationsEnabled => _notificationsEnabled;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLowStockThreshold(int value) {
    _lowStockThreshold = value;
    notifyListeners();
  }

  void setCurrency(String currency, String symbol) {
    _currency = currency;
    _currencySymbol = symbol;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
}
