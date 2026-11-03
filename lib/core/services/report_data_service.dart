import 'package:flutter/material.dart' show DateTimeRange;

import 'package:inventory_management/data/api_service.dart';
import 'package:inventory_management/models/inventory_report.dart';
import 'package:inventory_management/models/stock_movement.dart';

/// Category summary model for stock report breakdowns
class StockSummaryCategoryItem {
  final String categoryName;
  final int itemsCount;
  final int unitsIn;
  final int unitsOut;
  final int netUnits;
  final double netValue;
  final int currentUnits;
  final double currentValue;

  StockSummaryCategoryItem({
    required this.categoryName,
    required this.itemsCount,
    this.unitsIn = 0,
    this.unitsOut = 0,
    this.netUnits = 0,
    this.netValue = 0.0,
    this.currentUnits = 0,
    this.currentValue = 0.0,
  });
}

/// Product summary row for stock report breakdown and exports
class StockSummaryProductRow {
  final String id;
  final String sku;
  final String name;
  final String categoryName;
  final int unitsIn;
  final int unitsOut;
  final int netUnits;
  final double unitPrice;
  final double movementValue;
  final int currentStock;
  final int minStock;
  final String status; // 'In Stock', 'Low Stock', 'Out of Stock'

  StockSummaryProductRow({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryName,
    required this.unitsIn,
    required this.unitsOut,
    required this.netUnits,
    required this.unitPrice,
    required this.movementValue,
    required this.currentStock,
    required this.minStock,
    required this.status,
  });
}

/// Aggregated stock summary result representing either full inventory catalog
/// or period-based stock movement summary.
class StockSummaryData {
  final bool isAllTime;
  final int totalItems;
  final int totalUnits;
  final int unitsIn;
  final int unitsOut;
  final int netUnits;
  final double valuation;
  final double valuationIn;
  final double valuationOut;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final List<StockSummaryCategoryItem> categories;
  final List<StockSummaryProductRow> products;

  StockSummaryData({
    required this.isAllTime,
    required this.totalItems,
    required this.totalUnits,
    required this.unitsIn,
    required this.unitsOut,
    required this.netUnits,
    required this.valuation,
    required this.valuationIn,
    required this.valuationOut,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.categories,
    required this.products,
  });
}

class _ProductAccumulator {
  final InventoryReportItem? product;
  final String fallbackId;
  final String fallbackName;
  final String fallbackSku;
  final double price;
  int unitsIn = 0;
  int unitsOut = 0;

  _ProductAccumulator({
    required this.product,
    required this.fallbackId,
    required this.fallbackName,
    required this.fallbackSku,
    required this.price,
  });
}

class _CategoryAccumulator {
  final String name;
  final Set<String> productIds = {};
  int unitsIn = 0;
  int unitsOut = 0;
  double valIn = 0.0;
  double valOut = 0.0;
  int currentUnits = 0;
  double currentValue = 0.0;

  _CategoryAccumulator(this.name);
}

/// Loads report data from the API (all pages) and calculates report summaries.
/// Used by report tabs, PDF export, and CSV export.
class ReportDataService {
  ReportDataService._();

  static const int pageSize = 100;
  static const int maxPages = 50; // safety cap: 50 x 100 = 5,000 rows

  /// Inventory rows from GET /reports/inventory (all pages).
  /// Throws if the request fails.
  static Future<List<InventoryReportItem>> fetchInventory({
    bool? lowStockOnly,
    String? keyword,
    dynamic categoryId,
    dynamic supplierId,
    bool? active,
    String? period,
    DateTime? fromDate,
    DateTime? toDate,
    String? zoneId,
  }) async {
    final api = ApiService();
    final all = <InventoryReportItem>[];
    for (var page = 0; page < maxPages; page++) {
      final chunk = await api.getInventoryReport(
        keyword: keyword,
        categoryId: categoryId,
        supplierId: supplierId,
        active: active,
        lowStockOnly: lowStockOnly,
        period: period,
        fromDate: fromDate,
        toDate: toDate,
        zoneId: zoneId,
        page: page,
        size: pageSize,
      );
      all.addAll(chunk
          .map((e) => InventoryReportItem.fromJson(e as Map<String, dynamic>)));
      if (chunk.length < pageSize) break;
    }
    return all;
  }

  /// Fetches aggregated Stock Summary and Category Breakdown directly from
  /// GET /reports/inventory/summary, returning [StockSummaryData].
  /// If the API call fails, falls back to calculating via [calculateSummary].
  static Future<StockSummaryData> fetchInventorySummary({
    String? period,
    DateTime? fromDate,
    DateTime? toDate,
    String? zoneId,
    bool isAllTime = false,
    List<StockMovement>? periodMovements,
    List<InventoryReportItem>? fallbackItems,
  }) async {
    // In period mode (Today, This Week, This Month, Custom), calculate summary
    // metrics strictly from the actual stock transactions of the period so that
    // total items, units, and stock status distribution match the transactions.
    if (!isAllTime) {
      return calculateSummary(
        allItems: fallbackItems ?? [],
        periodMovements: periodMovements ?? [],
        isAllTime: false,
      );
    }

    try {
      final res = await ApiService().getInventorySummaryReport(
        period: period,
        fromDate: fromDate,
        toDate: toDate,
        zoneId: zoneId,
      );

      if (res != null) {
        final stockSum = res['stockSummary'] as Map<String, dynamic>? ?? res;
        final totalItems = (stockSum['totalItems'] as num?)?.toInt() ?? 0;
        final totalUnits = (stockSum['totalUnits'] as num?)?.toInt() ?? 0;
        final valuation = (stockSum['totalInventoryValuation'] as num?)?.toDouble() ?? 0.0;
        final inCount = (stockSum['inStockCount'] as num?)?.toInt() ?? 0;
        final lowCount = (stockSum['lowStockCount'] as num?)?.toInt() ?? 0;
        final outCount = (stockSum['outOfStockCount'] as num?)?.toInt() ?? 0;

        final catList = (res['categoryBreakdown'] as List<dynamic>?) ?? [];
        final categories = catList.map((c) {
          final cat = c as Map<String, dynamic>;
          final cItems = (cat['totalItems'] as num?)?.toInt() ?? 0;
          final cUnits = (cat['totalUnits'] as num?)?.toInt() ?? 0;
          final cVal = (cat['totalValuation'] as num?)?.toDouble() ?? 0.0;
          return StockSummaryCategoryItem(
            categoryName: cat['categoryName']?.toString() ?? 'Uncategorized',
            itemsCount: cItems,
            netUnits: cUnits,
            netValue: cVal,
            currentUnits: cUnits,
            currentValue: cVal,
          );
        }).toList()
          ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

        var unitsIn = 0;
        var unitsOut = 0;
        var valIn = 0.0;
        var valOut = 0.0;
        if (periodMovements != null) {
          for (final m in periodMovements) {
            final cost = m.unitCost ?? 0.0;
            if (m.isStockIn) {
              unitsIn += m.quantity;
              valIn += m.quantity * cost;
            } else {
              unitsOut += m.quantity;
              valOut += m.quantity * cost;
            }
          }
        }

        final productRows = (fallbackItems ?? []).map((i) {
          final status = i.stockQuantity <= 0
              ? 'Out of Stock'
              : (i.isLowStock ? 'Low Stock' : 'In Stock');
          return StockSummaryProductRow(
            id: i.id,
            sku: i.sku,
            name: i.name,
            categoryName: i.categoryName ?? 'Uncategorized',
            unitsIn: 0,
            unitsOut: 0,
            netUnits: i.stockQuantity,
            unitPrice: i.unitPrice,
            movementValue: i.totalValue,
            currentStock: i.stockQuantity,
            minStock: i.minimumStock,
            status: status,
          );
        }).toList()
          ..sort((a, b) => b.movementValue.compareTo(a.movementValue));

        final resolvedUnits = isAllTime ? totalUnits : (unitsIn - unitsOut != 0 ? (unitsIn - unitsOut) : totalUnits);
        final resolvedValuation = isAllTime ? valuation : (valIn - valOut != 0.0 ? (valIn - valOut) : valuation);

        return StockSummaryData(
          isAllTime: isAllTime,
          totalItems: totalItems,
          totalUnits: resolvedUnits,
          unitsIn: unitsIn,
          unitsOut: unitsOut,
          netUnits: unitsIn - unitsOut,
          valuation: resolvedValuation,
          valuationIn: valIn,
          valuationOut: valOut,
          inStockCount: inCount,
          lowStockCount: lowCount,
          outOfStockCount: outCount,
          categories: categories,
          products: productRows,
        );
      }
    } catch (_) {}

    return calculateSummary(
      allItems: fallbackItems ?? [],
      periodMovements: periodMovements ?? [],
      isAllTime: isAllTime,
    );
  }

  /// Stock transactions from GET /reports/stock-transactions (all pages).
  /// [type] = 'STOCK_IN', 'STOCK_OUT' or null for both.
  static Future<List<StockMovement>> fetchMovements(
    DateTimeRange range, {
    String? type,
  }) async {
    final api = ApiService();
    final all = <StockMovement>[];
    for (var page = 0; page < maxPages; page++) {
      final chunk = await api.getStockTransactionReport(
        type: type,
        fromDate: range.start,
        toDate: range.end,
        page: page,
        size: pageSize,
      );
      all.addAll(chunk
          .map((e) => StockMovement.fromJson(e as Map<String, dynamic>)));
      if (chunk.length < pageSize) break;
    }
    return all;
  }

  /// Calculates Stock Summary metrics based on selection mode:
  /// - [isAllTime] = true: Full warehouse catalog health & valuation.
  /// - [isAllTime] = false: Stock Movement Summary during [periodMovements].
  static StockSummaryData calculateSummary({
    required List<InventoryReportItem> allItems,
    required List<StockMovement> periodMovements,
    required bool isAllTime,
  }) {
    if (isAllTime) {
      final totalUnits = allItems.fold<int>(0, (s, i) => s + i.stockQuantity);
      final totalVal = allItems.fold<double>(0.0, (s, i) => s + i.totalValue);
      final outCount = allItems.where((i) => i.stockQuantity <= 0).length;
      final lowCount =
          allItems.where((i) => i.stockQuantity > 0 && i.lowStock).length;
      final inCount =
          (allItems.length - outCount - lowCount).clamp(0, 999999);

      // Group by category
      final catMap = <String, _CategoryAccumulator>{};
      for (final i in allItems) {
        final cat = catMap.putIfAbsent(
            i.categoryName ?? 'Uncategorized', () => _CategoryAccumulator(i.categoryName ?? 'Uncategorized'));
        cat.productIds.add(i.id);
        cat.currentUnits += i.stockQuantity;
        cat.currentValue += i.totalValue;
      }

      final categories = catMap.values.map((c) {
        return StockSummaryCategoryItem(
          categoryName: c.name,
          itemsCount: c.productIds.length,
          netUnits: c.currentUnits,
          netValue: c.currentValue,
          currentUnits: c.currentUnits,
          currentValue: c.currentValue,
        );
      }).toList()
        ..sort((a, b) => b.netValue.compareTo(a.netValue));

      final productRows = allItems.map((i) {
        final status = i.stockQuantity <= 0
            ? 'Out of Stock'
            : (i.lowStock ? 'Low Stock' : 'In Stock');
        return StockSummaryProductRow(
          id: i.id,
          sku: i.sku,
          name: i.name,
          categoryName: i.categoryName ?? 'Uncategorized',
          unitsIn: 0,
          unitsOut: 0,
          netUnits: i.stockQuantity,
          unitPrice: i.unitPrice,
          movementValue: i.totalValue,
          currentStock: i.stockQuantity,
          minStock: i.minimumStock,
          status: status,
        );
      }).toList()
        ..sort((a, b) => b.movementValue.compareTo(a.movementValue));

      return StockSummaryData(
        isAllTime: true,
        totalItems: allItems.length,
        totalUnits: totalUnits,
        unitsIn: 0,
        unitsOut: 0,
        netUnits: totalUnits,
        valuation: totalVal,
        valuationIn: totalVal,
        valuationOut: 0.0,
        inStockCount: inCount,
        lowStockCount: lowCount,
        outOfStockCount: outCount,
        categories: categories,
        products: productRows,
      );
    }

    // Period Stock Movement Mode
    if (periodMovements.isEmpty) {
      return StockSummaryData(
        isAllTime: false,
        totalItems: 0,
        totalUnits: 0,
        unitsIn: 0,
        unitsOut: 0,
        netUnits: 0,
        valuation: 0.0,
        valuationIn: 0.0,
        valuationOut: 0.0,
        inStockCount: 0,
        lowStockCount: 0,
        outOfStockCount: 0,
        categories: [],
        products: [],
      );
    }

    final productById = {for (final p in allItems) p.id: p};
    final productBySku = {for (final p in allItems) p.sku: p};

    final accMap = <String, _ProductAccumulator>{};
    var totalUnitsIn = 0;
    var totalUnitsOut = 0;
    var totalValIn = 0.0;
    var totalValOut = 0.0;

    for (final m in periodMovements) {
      final p = productById[m.productId] ?? productBySku[m.reference];
      final price = p?.unitPrice ?? m.unitCost ?? 0.0;
      final key = m.productId.isNotEmpty ? m.productId : (m.reference ?? m.productName);

      final acc = accMap.putIfAbsent(
        key,
        () => _ProductAccumulator(
          product: p,
          fallbackId: m.productId,
          fallbackName: m.productName,
          fallbackSku: m.reference ?? '',
          price: price,
        ),
      );

      if (m.isStockIn) {
        acc.unitsIn += m.quantity;
        totalUnitsIn += m.quantity;
        totalValIn += m.quantity * price;
      } else {
        acc.unitsOut += m.quantity;
        totalUnitsOut += m.quantity;
        totalValOut += m.quantity * price;
      }
    }

    final netUnits = totalUnitsIn - totalUnitsOut;
    final netValuation = totalValIn - totalValOut;

    // Transacted products stock health status in period mode:
    // - inStockCount reflects distinct products that received incoming stock (Stock In) during the period.
    // - outOfStockCount reflects transacted products that are currently depleted (currentQty <= 0).
    // - lowStockCount reflects transacted products with only stock-out that are at or below minimum threshold.
    var inStock = 0;
    var lowStock = 0;
    var outOfStock = 0;

    for (final acc in accMap.values) {
      final p = acc.product;
      final currentQty = p?.stockQuantity ?? (acc.unitsIn - acc.unitsOut);
      final minStock = p?.minimumStock ?? 0;
      final isLow = p?.lowStock ?? (currentQty <= minStock);

      if (currentQty <= 0) {
        outOfStock++;
      } else if (acc.unitsIn > 0) {
        inStock++;
      } else if (isLow) {
        lowStock++;
      }
    }

    // Category breakdown for the period
    final catMap = <String, _CategoryAccumulator>{};
    for (final acc in accMap.values) {
      final catName = acc.product?.categoryName ?? 'Uncategorized';
      final cat = catMap.putIfAbsent(catName, () => _CategoryAccumulator(catName));
      cat.productIds.add(acc.fallbackId);
      cat.unitsIn += acc.unitsIn;
      cat.unitsOut += acc.unitsOut;
      cat.valIn += acc.unitsIn * acc.price;
      cat.valOut += acc.unitsOut * acc.price;
      cat.currentUnits += acc.product?.stockQuantity ?? 0;
      cat.currentValue += acc.product?.totalValue ?? 0.0;
    }

    final categories = catMap.values.map((c) {
      final netCatUnits = c.unitsIn - c.unitsOut;
      final netCatVal = c.valIn - c.valOut;
      return StockSummaryCategoryItem(
        categoryName: c.name,
        itemsCount: c.productIds.length,
        unitsIn: c.unitsIn,
        unitsOut: c.unitsOut,
        netUnits: netCatUnits,
        netValue: netCatVal,
        currentUnits: c.currentUnits,
        currentValue: c.currentValue,
      );
    }).toList()
      ..sort((a, b) => b.netValue.abs().compareTo(a.netValue.abs()));

    // Product rows
    final productRows = accMap.values.map((acc) {
      final p = acc.product;
      final netPUnits = acc.unitsIn - acc.unitsOut;
      final pMovementVal = netPUnits * acc.price;
      final currentQty = p?.stockQuantity ?? netPUnits;
      final minStock = p?.minimumStock ?? 0;
      final isLow = p?.lowStock ?? (currentQty <= minStock);
      final status = currentQty <= 0
          ? 'Out of Stock'
          : (isLow ? 'Low Stock' : 'In Stock');

      return StockSummaryProductRow(
        id: p?.id ?? acc.fallbackId,
        sku: p?.sku ?? acc.fallbackSku,
        name: p?.name ?? acc.fallbackName,
        categoryName: p?.categoryName ?? 'Uncategorized',
        unitsIn: acc.unitsIn,
        unitsOut: acc.unitsOut,
        netUnits: netPUnits,
        unitPrice: acc.price,
        movementValue: pMovementVal,
        currentStock: currentQty,
        minStock: minStock,
        status: status,
      );
    }).toList()
      ..sort((a, b) => b.movementValue.abs().compareTo(a.movementValue.abs()));

    return StockSummaryData(
      isAllTime: false,
      totalItems: accMap.length,
      totalUnits: totalUnitsIn + totalUnitsOut,
      unitsIn: totalUnitsIn,
      unitsOut: totalUnitsOut,
      netUnits: netUnits,
      valuation: netValuation,
      valuationIn: totalValIn,
      valuationOut: totalValOut,
      inStockCount: inStock,
      lowStockCount: lowStock,
      outOfStockCount: outOfStock,
      categories: categories,
      products: productRows,
    );
  }

  /// Date filter for the inventory reports (Stock Summary, Low Stock):
  /// keeps products whose stock or details were updated inside [range].
  static List<InventoryReportItem> updatedInRange(
    List<InventoryReportItem> items,
    DateTimeRange range,
  ) =>
      items.where((i) => inRange(i.updatedAt, range)).toList();

  static bool inRange(DateTime date, DateTimeRange range) {
    final d = date.toLocal();
    final start = range.start.toLocal();
    final end = range.end.toLocal();
    return !d.isBefore(start) && !d.isAfter(end);
  }
}
