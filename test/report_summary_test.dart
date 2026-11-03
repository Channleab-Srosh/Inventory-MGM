import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management/core/services/report_data_service.dart';
import 'package:inventory_management/models/inventory_report.dart';
import 'package:inventory_management/models/stock_movement.dart';

void main() {
  group('Stock Summary Report Calculations & Filtering', () {
    final sampleItems = [
      InventoryReportItem(
        id: '1',
        sku: 'SKU-COKE',
        name: 'Coca Cola',
        categoryName: 'Beverages',
        unitPrice: 10.0,
        stockQuantity: 50,
        minimumStock: 20,
        totalValue: 500.0,
        lowStock: false,
        active: true,
        updatedAt: DateTime(2026, 11, 2, 10, 0),
      ),
      InventoryReportItem(
        id: '2',
        sku: 'SKU-MBP',
        name: 'MacBook Pro',
        categoryName: 'Electronics',
        unitPrice: 200.0,
        stockQuantity: 5,
        minimumStock: 10,
        totalValue: 1000.0,
        lowStock: true,
        active: true,
        updatedAt: DateTime(2026, 11, 2, 11, 0),
      ),
      InventoryReportItem(
        id: '3',
        sku: 'SKU-PEN',
        name: 'Blue Pen',
        categoryName: 'Office',
        unitPrice: 2.0,
        stockQuantity: 0,
        minimumStock: 10,
        totalValue: 0.0,
        lowStock: true,
        active: true,
        updatedAt: DateTime(2026, 10, 20, 9, 0),
      ),
    ];

    test('All Time mode calculates full catalog inventory snapshot', () {
      final summary = ReportDataService.calculateSummary(
        allItems: sampleItems,
        periodMovements: [],
        isAllTime: true,
      );

      expect(summary.isAllTime, true);
      expect(summary.totalItems, 3);
      expect(summary.totalUnits, 55); // 50 + 5 + 0
      expect(summary.valuation, 1500.0); // 500 + 1000 + 0
      expect(summary.inStockCount, 1); // SKU-COKE
      expect(summary.lowStockCount, 1); // SKU-MBP
      expect(summary.outOfStockCount, 1); // SKU-PEN
      expect(summary.categories.length, 3);
    });

    test('Period Movement mode calculates exact stock activity (in, out, net, valuation)', () {
      final periodMovements = [
        StockMovement(
          id: '101',
          productId: '1',
          productName: 'Coca Cola',
          type: MovementType.stockIn,
          quantity: 20,
          date: DateTime(2026, 11, 2, 10, 30),
          userId: '1',
          userName: 'admin',
        ),
        StockMovement(
          id: '102',
          productId: '1',
          productName: 'Coca Cola',
          type: MovementType.stockOut,
          quantity: 5,
          date: DateTime(2026, 11, 2, 11, 0),
          userId: '1',
          userName: 'admin',
        ),
        StockMovement(
          id: '103',
          productId: '2',
          productName: 'MacBook Pro',
          type: MovementType.stockIn,
          quantity: 3,
          date: DateTime(2026, 11, 2, 12, 0),
          userId: '1',
          userName: 'admin',
        ),
      ];

      final summary = ReportDataService.calculateSummary(
        allItems: sampleItems,
        periodMovements: periodMovements,
        isAllTime: false,
      );

      expect(summary.isAllTime, false);
      expect(summary.totalItems, 2); // SKU-COKE and SKU-MBP transacted
      expect(summary.unitsIn, 23); // 20 + 3
      expect(summary.unitsOut, 5); // 5
      expect(summary.netUnits, 18); // 23 - 5
      expect(summary.totalUnits, 28); // 23 + 5 moved

      // Valuation: Coke net +15 * $10 = $150, MBP net +3 * $200 = $600 -> total = $750
      expect(summary.valuationIn, (20 * 10.0) + (3 * 200.0)); // 200 + 600 = 800
      expect(summary.valuationOut, 5 * 10.0); // 50
      expect(summary.valuation, 750.0); // 800 - 50 = 750

      // Health of transacted items:
      // Product 1 (Coke) had stock in -> In Stock
      // Product 2 (MBP) had stock in -> In Stock
      expect(summary.inStockCount, 2);
      expect(summary.lowStockCount, 0);
      expect(summary.outOfStockCount, 0);

      // Categories:
      expect(summary.categories.length, 2);
      expect(summary.categories.first.categoryName, 'Electronics'); // largest value $600
      expect(summary.categories.first.netUnits, 3);
    });

    test('Stock Status Distribution accurately reflects stock-in count matching stock-in transactions', () {
      final mixedMovements = [
        // 2 Stock In transactions for 2 distinct products (Coke and Pen)
        StockMovement(
          id: '201',
          productId: '1',
          productName: 'Coca Cola',
          type: MovementType.stockIn,
          quantity: 10,
          date: DateTime(2026, 11, 2, 8, 0),
          userId: '1',
          userName: 'admin',
        ),
        StockMovement(
          id: '202',
          productId: '3',
          productName: 'Blue Pen',
          type: MovementType.stockIn,
          quantity: 5,
          date: DateTime(2026, 11, 2, 9, 0),
          userId: '1',
          userName: 'admin',
        ),
        // Stock Out only for Product 2 (MacBook Pro) which is low stock
        StockMovement(
          id: '203',
          productId: '2',
          productName: 'MacBook Pro',
          type: MovementType.stockOut,
          quantity: 1,
          date: DateTime(2026, 11, 2, 10, 0),
          userId: '1',
          userName: 'admin',
        ),
      ];

      final testItems = [
        sampleItems[0], // Coke (qty 50 > min 20)
        sampleItems[1], // MBP (qty 5 <= min 10)
        InventoryReportItem(
          id: '3',
          sku: 'SKU-PEN',
          name: 'Blue Pen',
          categoryName: 'Office',
          unitPrice: 2.0,
          stockQuantity: 5,
          minimumStock: 10,
          totalValue: 10.0,
          lowStock: true,
          active: true,
          updatedAt: DateTime(2026, 11, 2, 9, 0),
        ),
      ];

      final summary = ReportDataService.calculateSummary(
        allItems: testItems,
        periodMovements: mixedMovements,
        isAllTime: false,
      );

      // Exactly 2 products were stocked in (Coke and Blue Pen)
      expect(summary.inStockCount, 2);
      // Product 2 had only stock-out and has low stock (5 <= 10)
      expect(summary.lowStockCount, 1);
      expect(summary.outOfStockCount, 0);
    });

    test('Period Movement mode handles empty period cleanly', () {
      final summary = ReportDataService.calculateSummary(
        allItems: sampleItems,
        periodMovements: [],
        isAllTime: false,
      );

      expect(summary.totalItems, 0);
      expect(summary.totalUnits, 0);
      expect(summary.unitsIn, 0);
      expect(summary.unitsOut, 0);
      expect(summary.netUnits, 0);
      expect(summary.valuation, 0.0);
      expect(summary.categories, isEmpty);
      expect(summary.products, isEmpty);
    });

    test('InventoryReportItem isLowStock and isOutOfStock are mutually exclusive', () {
      final inStock = sampleItems[0];
      final lowStock = sampleItems[1];
      final outOfStock = sampleItems[2];

      expect(inStock.isLowStock, false);
      expect(inStock.isOutOfStock, false);

      expect(lowStock.isLowStock, true);
      expect(lowStock.isOutOfStock, false);

      expect(outOfStock.isLowStock, false);
      expect(outOfStock.isOutOfStock, true);

      // Low stock count in a list must only count low stock, not out of stock
      final lowCount = sampleItems.where((i) => i.isLowStock).length;
      final outCount = sampleItems.where((i) => i.isOutOfStock).length;
      expect(lowCount, 1);
      expect(outCount, 1);
    });

    test('Period updatedInRange correctly filters products updated within range', () {
      final todayRange = DateTimeRange(
        start: DateTime(2026, 11, 2, 0, 0),
        end: DateTime(2026, 11, 2, 23, 59),
      );

      final todayItems = ReportDataService.updatedInRange(sampleItems, todayRange);
      expect(todayItems.length, 2); // Coke and MBP were updated on Nov 2
      expect(todayItems.map((e) => e.sku), containsAll(['SKU-COKE', 'SKU-MBP']));
      expect(todayItems.any((e) => e.sku == 'SKU-PEN'), false); // PEN was updated Oct 20
    });

    test('Stock Status Distribution is accurate for filtered products', () {
      final todayRange = DateTimeRange(
        start: DateTime(2026, 11, 2, 0, 0),
        end: DateTime(2026, 11, 2, 23, 59),
      );

      final todayItems = ReportDataService.updatedInRange(sampleItems, todayRange);
      final inStock = todayItems.where((i) => !i.isLowStock && !i.isOutOfStock).length;
      final lowStock = todayItems.where((i) => i.isLowStock).length;
      final outOfStock = todayItems.where((i) => i.isOutOfStock).length;

      expect(inStock, 1);
      expect(lowStock, 1);
      expect(outOfStock, 0);
    });
  });
}
