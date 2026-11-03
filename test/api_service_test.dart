import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management/data/api_service.dart';
import 'package:inventory_management/core/constants/app_constants.dart';
import 'package:inventory_management/models/category.dart';
import 'package:inventory_management/models/supplier.dart';
import 'package:inventory_management/models/product.dart';
import 'package:inventory_management/models/stock_movement.dart';
import 'package:inventory_management/models/user_profile.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _RealHttpOverrides();
  });

  group('Backend API Integration Tests', () {
    final api = ApiService();

    test('Live connection checking and auto-detecting', () async {
      // Valid server should report connected
      final isLocalReachable = await api.checkConnection(AppConstants.defaultBaseUrl);
      expect(isLocalReachable, isTrue);

      // Dead or unroutable IP should fail fast (under 4 seconds)
      final stopwatch = Stopwatch()..start();
      final isBogusReachable = await api.checkConnection('http://192.0.2.1:8080/api/v1');
      stopwatch.stop();
      expect(isBogusReachable, isFalse);
      expect(stopwatch.elapsedMilliseconds, lessThan(4000));

      // findWorkingBaseUrl should discover reachable server
      final detected = await api.findWorkingBaseUrl();
      expect(detected, isNotNull);
      expect(detected, contains(':8080'));
    });

    test('Login and fetch profile from real backend', () async {
      final loginData = await api.login(
        AppConstants.defaultAdminUsername,
        AppConstants.defaultAdminPassword,
      );
      expect(loginData['token'], isNotNull);
      expect(api.hasToken, isTrue);

      final user = await api.getCurrentUser();
      expect(user['username'], equals('admin'));
      expect(user['role'], equals('ADMIN'));

      final profile = UserProfile.fromJson(user);
      expect(profile.name, equals('System Administrator'));
      expect(profile.isAdmin, isTrue);
    });

    test('Fetch categories and parse Category model', () async {
      final rawCategories = await api.getCategories();
      expect(rawCategories, isNotEmpty);
      final categories = rawCategories.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList();
      expect(categories.any((c) => c.name.contains('Beverages')), isTrue);
    });

    test('Fetch suppliers and parse Supplier model', () async {
      final rawSuppliers = await api.getSuppliers();
      expect(rawSuppliers, isNotEmpty);
      final suppliers = rawSuppliers.map((s) => Supplier.fromJson(s as Map<String, dynamic>)).toList();
      expect(suppliers.any((s) => s.name.contains('Phnom Penh') || s.name.contains('Cambodia')), isTrue);
    });

    test('Fetch products and parse Product model', () async {
      final rawProducts = await api.getProducts();
      expect(rawProducts, isNotEmpty);
      final products = rawProducts.map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
      expect(products.any((p) => p.name.contains('MacBook') || p.name.contains('Coca-Cola')), isTrue);
    });

    test('Fetch stock history and parse StockMovement model', () async {
      final rawMovements = await api.getStockHistory();
      expect(rawMovements, isNotEmpty);
      final movements = rawMovements.map((m) => StockMovement.fromJson(m as Map<String, dynamic>)).toList();
      expect(movements, isNotEmpty);
    });

    test('Fetch users and parse UserProfile model', () async {
      final rawUsers = await api.getUsers();
      expect(rawUsers, isNotEmpty);
      final users = rawUsers.map((u) => UserProfile.fromJson(u as Map<String, dynamic>)).toList();
      expect(users.any((u) => u.name == 'System Administrator'), isTrue);
    });

    test('Fetch dashboard summary metrics', () async {
      final summary = await api.getDashboardSummary();
      expect(summary['totalProducts'], greaterThan(0));
      expect(summary['totalStockQuantity'], greaterThan(0));
    });

    test('Fetch reports endpoints', () async {
      final inventoryReport = await api.getInventoryReport();
      expect(inventoryReport, isNotEmpty);

      final txReport = await api.getStockTransactionReport();
      expect(txReport, isNotEmpty);
    });
  });
}
