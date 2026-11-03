import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management/models/dashboard_summary.dart';
import 'package:inventory_management/models/stock_movement.dart';
import 'package:inventory_management/providers/stock_provider.dart';

void main() {
  group('Dashboard Summary Model & Metrics Tests', () {
    test('DashboardSummary parses report json accurately with both flat and nested keys', () {
      final json = {
        'totalItems': 9,
        'totalUnits': 637,
        'totalInventoryValuation': 31602.00,
        'inStockCount': 3,
        'lowStockCount': 3,
        'outOfStockCount': 3,
        'stockSummary': {
          'totalItems': 9,
          'totalUnits': 637,
          'totalInventoryValuation': 31602.00,
          'inStockCount': 3,
          'lowStockCount': 3,
          'outOfStockCount': 3,
        }
      };

      final summary = DashboardSummary.fromJson(json);

      expect(summary.totalProducts, equals(9));
      expect(summary.totalStockQuantity, equals(637));
      expect(summary.totalInventoryValue, equals(31602.00));
      expect(summary.lowStockCount, equals(3));
      expect(summary.outOfStockCount, equals(3));
    });

    test('DashboardSummary parses /api/v1/dashboard/summary json accurately', () {
      final json = {
        'totalProducts': 28,
        'totalCategories': 8,
        'totalSuppliers': 8,
        'totalStockQuantity': 3241,
        'totalInventoryValue': 48534.40,
        'lowStockCount': 7,
        'outOfStockCount': 3,
        'totalStockInQuantity': 4469,
        'totalStockOutQuantity': 1203,
      };

      final summary = DashboardSummary.fromJson(json);

      expect(summary.totalProducts, equals(28));
      expect(summary.totalCategories, equals(8));
      expect(summary.totalSuppliers, equals(8));
      expect(summary.totalStockQuantity, equals(3241));
      expect(summary.totalInventoryValue, equals(48534.40));
      expect(summary.lowStockCount, equals(7));
      expect(summary.outOfStockCount, equals(3));
      expect(summary.totalStockInQuantity, equals(4469));
      expect(summary.totalStockOutQuantity, equals(1203));
    });

    test('StockProvider.getStockFlowData returns 0 bars and neutral message when 0 transactions exist', () {
      final stockProvider = StockProvider();
      expect(stockProvider.allMovements, isEmpty);

      final weeklyFlow = stockProvider.getStockFlowData('Weekly');
      expect(weeklyFlow.labels.length, equals(7));
      expect(weeklyFlow.totalIn, equals(0.0));
      expect(weeklyFlow.totalOut, equals(0.0));
      // Must NOT return fake dummy bars like [45, 20, 50, ...]
      expect(weeklyFlow.barPercentages, equals([0, 0, 0, 0, 0, 0, 0]));
      // Must NOT return fake trend '+18% Rise'
      expect(weeklyFlow.trendText, equals('No transactions recorded for this period'));

      final dailyFlow = stockProvider.getStockFlowData('Daily');
      expect(dailyFlow.labels.length, equals(5));
      expect(dailyFlow.barPercentages, equals([0, 0, 0, 0, 0]));
      expect(dailyFlow.trendText, equals('No transactions recorded for this period'));
    });

    test('StockProvider.getStockFlowData calculates correct percentage trend when transactions exist', () {
      final stockProvider = StockProvider();
      final now = DateTime.now();

      stockProvider.addMovement(StockMovement(
        id: 'm1',
        productId: '1',
        productName: 'MacBook Pro',
        type: MovementType.stockIn,
        quantity: 100,
        userId: 'u1',
        userName: 'Admin',
        date: now,
      ));

      stockProvider.addMovement(StockMovement(
        id: 'm2',
        productId: '1',
        productName: 'MacBook Pro',
        type: MovementType.stockOut,
        quantity: 20,
        userId: 'u1',
        userName: 'Admin',
        date: now,
      ));

      final weeklyFlow = stockProvider.getStockFlowData('Weekly');
      expect(weeklyFlow.totalIn, equals(100.0));
      expect(weeklyFlow.totalOut, equals(20.0));
      // Total activity = 120. Diff = +80. Pct = (80 / 120) * 100 = 67%
      expect(weeklyFlow.trendText, equals('+67% Rise in Total Inventory Units'));
      expect(weeklyFlow.isPositive, isTrue);
    });

    test('DashboardSummary netAvailableStock calculates net units accurately across all periods', () {
      // 1. All-Time response: 3,125 available stock
      const allTimeSummary = DashboardSummary(
        totalProducts: 29,
        totalStockQuantity: 3125,
        totalInventoryValue: 43062.40,
        lowStockCount: 6,
        outOfStockCount: 4,
        totalStockInQuantity: 4328,
        totalStockOutQuantity: 1203,
      );
      expect(allTimeSummary.netAvailableStock, equals(3125));

      // 2. Today response: Stock In = 610, Stock Out = 364 -> Net Available = 246
      const todaySummary = DashboardSummary(
        totalProducts: 29,
        totalStockQuantity: 246,
        totalInventoryValue: 8995.10,
        lowStockCount: 6,
        outOfStockCount: 4,
        totalStockInQuantity: 610,
        totalStockOutQuantity: 364,
      );
      expect(todaySummary.netAvailableStock, equals(246));
      expect(todaySummary.totalStockInQuantity - todaySummary.totalStockOutQuantity, equals(246));

      // 3. Fallback when totalStockQuantity is 0: derive from in - out
      const derivedSummary = DashboardSummary(
        totalStockQuantity: 0,
        totalStockInQuantity: 610,
        totalStockOutQuantity: 364,
      );
      expect(derivedSummary.netAvailableStock, equals(246));
    });
  });
}
