import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:inventory_management/core/services/report_data_service.dart';
import 'package:inventory_management/models/inventory_report.dart';
import 'package:inventory_management/models/stock_movement.dart';

/// Builds PDF files for the 5 report tabs and shares/saves them.
///
/// Report index (same order as the tabs in ReportsScreen):
/// 0 = Stock Summary, 1 = Stock In, 2 = Stock Out, 3 = Low Stock, 4 = Transactions
///
/// The data is fetched here from the API (all pages), so the PDF always
/// contains the full report, not only what the tab currently shows.
class ReportPdfService {
  ReportPdfService._();

  static const PdfColor _primary = PdfColor.fromInt(0xFF7C6CE6);
  static const PdfColor _light = PdfColor.fromInt(0xFFEBE8FC);
  static const PdfColor _text = PdfColor.fromInt(0xFF1F2330);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);

  // ------------------------------------------------------------------
  // Public API
  // ------------------------------------------------------------------

  /// Fetches the data for [reportIndex] and returns the PDF bytes.
  static Future<Uint8List> build({
    required int reportIndex,
    required String title,
    required String periodLabel,
    required DateTimeRange range,
    String currencySymbol = '\$',
  }) async {
    // Default PDF fonts only contain Latin symbols; fall back to no symbol
    // for things like the Riel sign so we don't print an empty box.
    final symbol = currencySymbol.runes.every((r) => r < 256) ? currencySymbol : '';

    final doc = pw.Document(
      title: title,
      author: 'Inventory Management',
      creator: 'Inventory Management',
    );

    late final List<pw.Widget> content;
    switch (reportIndex) {
      case 0:
        content = await _stockSummary(symbol, range);
        break;
      case 1:
        content = await _movements(range, type: 'STOCK_IN', label: 'Incoming Transactions');
        break;
      case 2:
        content = await _movements(range, type: 'STOCK_OUT', label: 'Outgoing Transactions');
        break;
      case 3:
        content = await _lowStock(symbol, range);
        break;
      case 4:
        content = await _movements(range, type: null, label: 'All Transactions');
        break;
      default:
        content = await _stockSummary(symbol, range);
    }

    final generatedAt = DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: 200,
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated $generatedAt',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ),
        build: (ctx) => [
          _banner(title, periodLabel),
          pw.SizedBox(height: 14),
          ...content,
        ],
      ),
    );

    return doc.save();
  }

  /// Saves the PDF to the device and then tries to open the share sheet.
  /// Returns the path of the saved file.
  ///
  /// The file is saved first, so the export still works when no app can handle
  /// sharing/printing (for example on an emulator).
  static Future<String> share(Uint8List bytes, String title) async {
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = '${slug}_$date.pdf';

    // 1) Save a copy in the app's storage folder
    Directory dir;
    try {
      dir = (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);

    // 2) Try the share / save sheet. Ignore failures: the file is already saved.
    try {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (_) {}

    return file.path;
  }

  // ------------------------------------------------------------------
  // Report bodies
  // ------------------------------------------------------------------

  static Future<List<pw.Widget>> _stockSummary(
      String symbol, DateTimeRange range) async {
    // Date filter: products whose stock/details were updated inside the period
    final items = ReportDataService.updatedInRange(
        await ReportDataService.fetchInventory(), range);

    final totalUnits = items.fold<int>(0, (s, i) => s + i.stockQuantity);
    final totalValue = items.fold<double>(0, (s, i) => s + i.totalValue);
    final outCount = items.where((i) => i.stockQuantity <= 0).length;
    final lowCount =
        items.where((i) => i.stockQuantity > 0 && i.lowStock).length;
    final inCount = items.length - outCount - lowCount;

    return [
      _chips([
        ('Total Items', '${items.length}'),
        ('Total Units', '$totalUnits'),
        ('Inventory Value', _money(totalValue, symbol)),
        ('In Stock', '$inCount'),
        ('Low Stock', '$lowCount'),
        ('Out of Stock', '$outCount'),
      ]),
      pw.SizedBox(height: 6),
      _note('Includes products updated during the selected period.'),
      pw.SizedBox(height: 12),
      _sectionTitle('Products (${items.length})'),
      pw.SizedBox(height: 6),
      _table(
        headers: const [
          'SKU',
          'Product',
          'Category',
          'Stock',
          'Min',
          'Unit Price',
          'Total Value',
          'Status',
        ],
        rows: [
          for (final i in items)
            [
              i.sku,
              i.name,
              i.categoryName ?? '-',
              '${i.stockQuantity} ${i.unitOfMeasure.toLowerCase()}',
              '${i.minimumStock}',
              _money(i.unitPrice, symbol),
              _money(i.totalValue, symbol),
              _statusOf(i),
            ],
        ],
        widths: const {
          0: pw.FlexColumnWidth(1.4),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(1.8),
          3: pw.FlexColumnWidth(1.3),
          4: pw.FlexColumnWidth(0.8),
          5: pw.FlexColumnWidth(1.3),
          6: pw.FlexColumnWidth(1.5),
          7: pw.FlexColumnWidth(1.3),
        },
        rightAligned: const {3, 4, 5, 6},
      ),
    ];
  }

  static Future<List<pw.Widget>> _lowStock(
      String symbol, DateTimeRange range) async {
    // Date filter: low-stock products updated inside the period
    final items = ReportDataService.updatedInRange(
        await ReportDataService.fetchInventory(lowStockOnly: true), range);
    final outCount = items.where((i) => i.stockQuantity <= 0).length;

    return [
      _chips([
        ('Items Needing Action', '${items.length}'),
        ('Out of Stock', '$outCount'),
        ('Low Stock', '${items.length - outCount}'),
      ]),
      pw.SizedBox(height: 6),
      _note('Includes low-stock products updated during the selected period.'),
      pw.SizedBox(height: 12),
      _sectionTitle('Actionable Items (${items.length})'),
      pw.SizedBox(height: 6),
      _table(
        headers: const [
          'SKU',
          'Product',
          'Category',
          'Supplier',
          'Stock',
          'Min',
          'Shortage',
          'Status',
        ],
        rows: [
          for (final i in items)
            [
              i.sku,
              i.name,
              i.categoryName ?? '-',
              i.supplierName ?? '-',
              '${i.stockQuantity}',
              '${i.minimumStock}',
              '${(i.minimumStock - i.stockQuantity).clamp(0, 1 << 30)}',
              _statusOf(i),
            ],
        ],
        widths: const {
          0: pw.FlexColumnWidth(1.4),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(1.8),
          3: pw.FlexColumnWidth(2),
          4: pw.FlexColumnWidth(0.9),
          5: pw.FlexColumnWidth(0.9),
          6: pw.FlexColumnWidth(1),
          7: pw.FlexColumnWidth(1.3),
        },
        rightAligned: const {4, 5, 6},
      ),
    ];
  }

  /// [type] = 'STOCK_IN', 'STOCK_OUT' or null for all transactions.
  static Future<List<pw.Widget>> _movements(
    DateTimeRange range, {
    required String? type,
    required String label,
  }) async {
    final list = await ReportDataService.fetchMovements(range, type: type);
    final fmt = DateFormat('MMM d, yyyy h:mm a');

    final totalIn = list
        .where((m) => m.type == MovementType.stockIn)
        .fold<int>(0, (s, m) => s + m.quantity);
    final totalOut = list
        .where((m) => m.type == MovementType.stockOut)
        .fold<int>(0, (s, m) => s + m.quantity);

    final chips = <(String, String)>[
      ('Transactions', '${list.length}'),
      if (type != 'STOCK_OUT') ('Total In', '+$totalIn units'),
      if (type != 'STOCK_IN') ('Total Out', '-$totalOut units'),
      if (type == null) ('Net Change', '${totalIn - totalOut >= 0 ? '+' : ''}${totalIn - totalOut} units'),
    ];

    return [
      _chips(chips),
      pw.SizedBox(height: 16),
      _sectionTitle('$label (${list.length})'),
      pw.SizedBox(height: 6),
      _table(
        headers: const [
          'Date',
          'Product',
          'Type',
          'Qty',
          'Before',
          'After',
          'Reference',
          'By',
          'Note',
        ],
        rows: [
          for (final m in list)
            [
              fmt.format(m.date.toLocal()),
              m.productName,
              m.isStockIn ? 'IN' : 'OUT',
              '${m.isStockIn ? '+' : '-'}${m.quantity}',
              m.stockBefore?.toString() ?? '-',
              m.stockAfter?.toString() ?? '-',
              m.reference ?? '-',
              m.userName,
              (m.note == null || m.note!.isEmpty) ? '-' : m.note!,
            ],
        ],
        widths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(2.6),
          2: pw.FlexColumnWidth(0.9),
          3: pw.FlexColumnWidth(0.9),
          4: pw.FlexColumnWidth(0.9),
          5: pw.FlexColumnWidth(0.9),
          6: pw.FlexColumnWidth(1.6),
          7: pw.FlexColumnWidth(1.4),
          8: pw.FlexColumnWidth(2.4),
        },
        rightAligned: const {3, 4, 5},
      ),
    ];
  }

  // ------------------------------------------------------------------
  // PDF building blocks
  // ------------------------------------------------------------------

  static String _money(double v, String symbol) =>
      '$symbol${NumberFormat('#,##0.00').format(v)}';

  static String _statusOf(InventoryReportItem i) {
    if (i.stockQuantity <= 0) return 'Out of stock';
    if (i.lowStock) return 'Low stock';
    return 'In stock';
  }

  static pw.Widget _banner(String title, String period) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: pw.BoxDecoration(
        color: _light,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary)),
          pw.SizedBox(height: 4),
          pw.Text('Period: $period',
              style: const pw.TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _note(String text) {
    return pw.Text(text, style: const pw.TextStyle(fontSize: 8.5, color: _muted));
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(text,
        style: pw.TextStyle(
            fontSize: 12, fontWeight: pw.FontWeight.bold, color: _text));
  }

  /// Row of small summary boxes: (label, value)
  static pw.Widget _chips(List<(String, String)> items) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in items)
          pw.Container(
            width: 150,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: const pw.TextStyle(fontSize: 8, color: _muted)),
                pw.SizedBox(height: 3),
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _text)),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.TableColumnWidth> widths,
    Set<int> rightAligned = const {},
  }) {
    if (rows.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text('No records found for this report.',
            style: const pw.TextStyle(fontSize: 10, color: _muted)),
      );
    }

    final alignments = <int, pw.Alignment>{
      for (var i = 0; i < headers.length; i++)
        i: rightAligned.contains(i)
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
    };

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      columnWidths: widths,
      cellAlignments: alignments,
      headerAlignments: alignments,
      headerStyle: pw.TextStyle(
          fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      cellStyle: const pw.TextStyle(fontSize: 8.5, color: _text),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF7F7FB)),
      border: pw.TableBorder(
        bottom: const pw.BorderSide(color: _line),
        horizontalInside: const pw.BorderSide(color: _line, width: 0.5),
      ),
    );
  }
}