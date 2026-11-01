import 'package:flutter/material.dart' show DateTimeRange;

import 'package:inventory_management/data/api_service.dart';
import 'package:inventory_management/models/inventory_report.dart';
import 'package:inventory_management/models/stock_movement.dart';

/// Loads report data from the API (all pages) and applies the date filter.
/// Used by both the report tabs on screen and the PDF export, so they always agree.
class ReportDataService {
  ReportDataService._();

  static const int pageSize = 100;
  static const int maxPages = 50; // safety cap: 50 x 100 = 5,000 rows

  /// Inventory rows from GET /reports/inventory (all pages).
  /// Throws if the request fails.
  static Future<List<InventoryReportItem>> fetchInventory({
    bool? lowStockOnly,
  }) async {
    final api = ApiService();
    final all = <InventoryReportItem>[];
    for (var page = 0; page < maxPages; page++) {
      final chunk = await api.getInventoryReport(
        lowStockOnly: lowStockOnly,
        page: page,
        size: pageSize,
      );
      all.addAll(chunk
          .map((e) => InventoryReportItem.fromJson(e as Map<String, dynamic>)));
      if (chunk.length < pageSize) break;
    }
    return all;
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

  /// Date filter for the inventory reports (Stock Summary, Low Stock):
  /// keeps products whose stock or details were updated inside [range].
  static List<InventoryReportItem> updatedInRange(
    List<InventoryReportItem> items,
    DateTimeRange range,
  ) =>
      items.where((i) => inRange(i.updatedAt, range)).toList();

  static bool inRange(DateTime date, DateTimeRange range) =>
      !date.isBefore(range.start) && !date.isAfter(range.end);
}