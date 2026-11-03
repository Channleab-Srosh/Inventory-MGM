import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:inventory_management/core/services/report_data_service.dart';
import 'package:inventory_management/models/stock_movement.dart';

/// Data structure representing an exportable report
class ReportExportData {
  final String title;
  final String periodLabel;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Map<String, String>? summaryMetrics;

  const ReportExportData({
    required this.title,
    required this.periodLabel,
    required this.headers,
    required this.rows,
    this.summaryMetrics,
  });
}

/// Service handling report export to styled Excel (.xlsx), CSV, and device storage saving
class ReportExportService {
  ReportExportService._();
  static final ReportExportService instance = ReportExportService._();

  /// Escape a CSV cell value according to RFC 4180
  String _escapeCsvCell(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Escape XML special characters
  String _escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Convert zero-based column index to Excel column letters (0->A, 1->B, 25->Z, 26->AA)
  String _columnLetter(int colIndex) {
    var temp = colIndex;
    var letter = '';
    while (temp >= 0) {
      letter = String.fromCharCode((temp % 26) + 65) + letter;
      temp = (temp ~/ 26) - 1;
    }
    return letter;
  }

  /// Generate formatted RFC 4180 CSV string with UTF-8 BOM, executive header banner,
  /// and structured summary metrics block.
  String generateCsvString(ReportExportData data) {
    final buffer = StringBuffer();
    // UTF-8 Byte Order Mark (BOM) so Excel opens UTF-8 files correctly
    buffer.write('\uFEFF');

    // Executive Header Banner
    const bannerDivider = '================================================================================';
    buffer.writeln(_escapeCsvCell(bannerDivider));
    buffer.writeln('${_escapeCsvCell("REPORT:")},${_escapeCsvCell(data.title.toUpperCase())}');
    buffer.writeln('${_escapeCsvCell("PERIOD:")},${_escapeCsvCell(data.periodLabel)}');
    buffer.writeln(
        '${_escapeCsvCell("GENERATED:")},${_escapeCsvCell(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()))}');
    buffer.writeln(_escapeCsvCell(bannerDivider));
    buffer.writeln(); // Blank line

    // Summary metrics block
    if (data.summaryMetrics != null && data.summaryMetrics!.isNotEmpty) {
      buffer.writeln(_escapeCsvCell('--- SUMMARY METRICS ---'));
      buffer.writeln('${_escapeCsvCell("METRIC")},${_escapeCsvCell("VALUE")}');
      for (final entry in data.summaryMetrics!.entries) {
        buffer.writeln('${_escapeCsvCell(entry.key)},${_escapeCsvCell(entry.value)}');
      }
      buffer.writeln(_escapeCsvCell('---------------------------------'));
      buffer.writeln(); // Blank line
    }

    // Detailed table headers
    buffer.writeln(_escapeCsvCell('--- DETAILED DATA ---'));
    buffer.writeln(data.headers.map(_escapeCsvCell).join(','));

    // Table rows
    for (final row in data.rows) {
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }

    return buffer.toString();
  }

  /// Generate a genuine styled Microsoft Excel (.xlsx) spreadsheet matching the visual
  /// hierarchy and purple color palette (#7C6CE6, #EBE8FC, #F7F7FB) of the PDF report.
  Uint8List generateXlsxBytes(ReportExportData data) {
    final archive = Archive();

    void addXml(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    // 1. [Content_Types].xml
    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';
    addXml('[Content_Types].xml', contentTypes);

    // 2. _rels/.rels
    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';
    addXml('_rels/.rels', rels);

    // 3. xl/_rels/workbook.xml.rels
    const wbRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    addXml('xl/_rels/workbook.xml.rels', wbRels);

    // 4. xl/workbook.xml
    const workbook = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Report" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';
    addXml('xl/workbook.xml', workbook);

    // 5. xl/styles.xml
    // Color Palette matching PDF:
    // Primary Header: #7C6CE6 (FF7C6CE6)
    // Light Accent:   #EBE8FC (FFEBE8FC)
    // Zebra Stripe:   #F7F7FB (FFF7F7FB)
    // KPI Card Fill:  #F3F1FD (FFF3F1FD)
    // Border Line:    #E5E7EB (FFE5E7EB)
    // KPI Border:     #D6D0F8 (FFD6D0F8)
    const styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="7">
    <font><sz val="10"/><color rgb="FF1F2330"/><name val="Segoe UI"/></font>
    <font><b/><sz val="15"/><color rgb="FFFFFFFF"/><name val="Segoe UI"/></font>
    <font><i/><sz val="9.5"/><color rgb="FF4B5563"/><name val="Segoe UI"/></font>
    <font><b/><sz val="10.5"/><color rgb="FFFFFFFF"/><name val="Segoe UI"/></font>
    <font><b/><sz val="8.5"/><color rgb="FF6B7280"/><name val="Segoe UI"/></font>
    <font><b/><sz val="12"/><color rgb="FF7C6CE6"/><name val="Segoe UI"/></font>
    <font><b/><sz val="11"/><color rgb="FF1F2330"/><name val="Segoe UI"/></font>
  </fonts>
  <fills count="6">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF7C6CE6"/><bgColor indexed="64"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFEBE8FC"/><bgColor indexed="64"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFF7F7FB"/><bgColor indexed="64"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFF3F1FD"/><bgColor indexed="64"/></patternFill></fill>
  </fills>
  <borders count="3">
    <border><left/><right/><top/><bottom/><diagonal/></border>
    <border>
      <left style="thin"><color rgb="FFE5E7EB"/></left>
      <right style="thin"><color rgb="FFE5E7EB"/></right>
      <top style="thin"><color rgb="FFE5E7EB"/></top>
      <bottom style="thin"><color rgb="FFE5E7EB"/></bottom>
      <diagonal/>
    </border>
    <border>
      <left style="thin"><color rgb="FFD6D0F8"/></left>
      <right style="thin"><color rgb="FFD6D0F8"/></right>
      <top style="thin"><color rgb="FFD6D0F8"/></top>
      <bottom style="thin"><color rgb="FFD6D0F8"/></bottom>
      <diagonal/>
    </border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="13">
    <!-- 0: Normal default -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <!-- 1: Title Banner (Merged Header Fill #7C6CE6) -->
    <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <!-- 2: Subtitle Bar (Period Bar Fill #EBE8FC) -->
    <xf numFmtId="0" fontId="2" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <!-- 3: Table Column Header (Purple #7C6CE6) -->
    <xf numFmtId="0" fontId="3" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center" wrapText="1"/>
    </xf>
    <!-- 4: Table Data Normal (Left) -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="left" vertical="center"/>
    </xf>
    <!-- 5: Table Data Normal (Right - numbers/currency) -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="right" vertical="center"/>
    </xf>
    <!-- 6: Table Data Normal (Center - dates/status) -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <!-- 7: Table Data Zebra Alternate (Left) -->
    <xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="left" vertical="center"/>
    </xf>
    <!-- 8: Table Data Zebra Alternate (Right) -->
    <xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="right" vertical="center"/>
    </xf>
    <!-- 9: Table Data Zebra Alternate (Center) -->
    <xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <!-- 10: KPI Card Label -->
    <xf numFmtId="0" fontId="4" fillId="5" borderId="2" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <!-- 11: KPI Card Value -->
    <xf numFmtId="0" fontId="5" fillId="5" borderId="2" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <!-- 12: Section Header -->
    <xf numFmtId="0" fontId="6" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1">
      <alignment horizontal="left" vertical="center"/>
    </xf>
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>''';
    addXml('xl/styles.xml', styles);

    // 6. xl/worksheets/sheet1.xml
    final numCols = math.max(1, data.headers.length);
    final lastColLetter = _columnLetter(numCols - 1);

    // Calculate auto column widths
    final colWidths = List<int>.filled(numCols, 14);
    for (int c = 0; c < numCols; c++) {
      int maxLen = data.headers[c].length;
      for (final row in data.rows) {
        if (c < row.length) {
          final s = row[c]?.toString() ?? '';
          if (s.length > maxLen) maxLen = s.length;
        }
      }
      colWidths[c] = math.min(48, math.max(14, maxLen + 4));
    }

    final sheetXml = StringBuffer();
    sheetXml.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sheetXml.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    sheetXml.writeln('<sheetViews><sheetView tabSelected="1" workbookViewId="0"/></sheetViews>');
    sheetXml.writeln('<sheetFormatPr defaultRowHeight="18"/>');

    // Columns
    sheetXml.writeln('<cols>');
    for (int i = 0; i < numCols; i++) {
      final colNum = i + 1;
      sheetXml.writeln('<col min="$colNum" max="$colNum" width="${colWidths[i]}" customWidth="1"/>');
    }
    sheetXml.writeln('</cols>');

    sheetXml.writeln('<sheetData>');

    int currentRow = 1;

    // Row 1: Title Banner (Merged across all table columns)
    sheetXml.writeln('<row r="$currentRow" ht="36" customHeight="1">');
    sheetXml.writeln('<c r="A$currentRow" s="1" t="inlineStr"><is><t>${_escapeXml(data.title)}</t></is></c>');
    for (int c = 1; c < numCols; c++) {
      sheetXml.writeln('<c r="${_columnLetter(c)}$currentRow" s="1"/>');
    }
    sheetXml.writeln('</row>');
    currentRow++;

    // Row 2: Subtitle Bar (Period & Generated timestamp)
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final subtitleText = 'Period: ${data.periodLabel}   •   Generated: $timeStr';
    sheetXml.writeln('<row r="$currentRow" ht="22" customHeight="1">');
    sheetXml.writeln('<c r="A$currentRow" s="2" t="inlineStr"><is><t>${_escapeXml(subtitleText)}</t></is></c>');
    for (int c = 1; c < numCols; c++) {
      sheetXml.writeln('<c r="${_columnLetter(c)}$currentRow" s="2"/>');
    }
    sheetXml.writeln('</row>');
    currentRow++;

    // Row 3: Blank separator
    sheetXml.writeln('<row r="$currentRow" ht="12"/>');
    currentRow++;

    // KPI Metrics Section (if present)
    if (data.summaryMetrics != null && data.summaryMetrics!.isNotEmpty) {
      final kpiEntries = data.summaryMetrics!.entries.toList();
      final chunkSize = numCols;

      for (int i = 0; i < kpiEntries.length; i += chunkSize) {
        final chunk = kpiEntries.sublist(i, math.min(i + chunkSize, kpiEntries.length));

        // Metric Labels row
        final labelRow = currentRow++;
        sheetXml.writeln('<row r="$labelRow" ht="20" customHeight="1">');
        for (int c = 0; c < chunk.length; c++) {
          final col = _columnLetter(c);
          sheetXml.writeln('<c r="$col$labelRow" s="10" t="inlineStr"><is><t>${_escapeXml(chunk[c].key)}</t></is></c>');
        }
        sheetXml.writeln('</row>');

        // Metric Values row
        final valueRow = currentRow++;
        sheetXml.writeln('<row r="$valueRow" ht="26" customHeight="1">');
        for (int c = 0; c < chunk.length; c++) {
          final col = _columnLetter(c);
          sheetXml.writeln('<c r="$col$valueRow" s="11" t="inlineStr"><is><t>${_escapeXml(chunk[c].value)}</t></is></c>');
        }
        sheetXml.writeln('</row>');

        // Separator after metrics chunk
        sheetXml.writeln('<row r="$currentRow" ht="14"/>');
        currentRow++;
      }
    }

    // Table Column Headers row
    final headerRow = currentRow++;
    sheetXml.writeln('<row r="$headerRow" ht="26" customHeight="1">');
    for (int c = 0; c < numCols; c++) {
      final col = _columnLetter(c);
      sheetXml.writeln('<c r="$col$headerRow" s="3" t="inlineStr"><is><t>${_escapeXml(data.headers[c])}</t></is></c>');
    }
    sheetXml.writeln('</row>');

    // Helper to detect numeric/currency, status/date, or text
    bool isNumeric(String s) {
      final clean = s.replaceAll(RegExp(r'[\$,+\s]'), '');
      return double.tryParse(clean) != null;
    }

    bool isCenterAligned(String header, String val) {
      final h = header.toLowerCase();
      if (h.contains('date') || h.contains('time') || h.contains('status') || h.contains('type')) {
        return true;
      }
      const badges = {
        'IN_STOCK',
        'LOW_STOCK',
        'OUT_OF_STOCK',
        'STOCK_IN',
        'STOCK_OUT',
        'SALE',
        'DAMAGE',
        'DAMAGED',
        'OTHER',
      };
      return badges.contains(val.toUpperCase());
    }

    // Data rows
    for (int r = 0; r < data.rows.length; r++) {
      final rowNum = currentRow++;
      final isZebra = r % 2 == 1;
      final row = data.rows[r];

      sheetXml.writeln('<row r="$rowNum" ht="22" customHeight="1">');
      for (int c = 0; c < numCols; c++) {
        final val = c < row.length ? (row[c]?.toString() ?? '') : '';
        final col = _columnLetter(c);
        final header = data.headers[c];

        final int styleId;
        if (isNumeric(val) && !isCenterAligned(header, val)) {
          styleId = isZebra ? 8 : 5; // Right-aligned numeric/currency
        } else if (isCenterAligned(header, val)) {
          styleId = isZebra ? 9 : 6; // Center-aligned date/status
        } else {
          styleId = isZebra ? 7 : 4; // Left-aligned text
        }

        sheetXml.writeln('<c r="$col$rowNum" s="$styleId" t="inlineStr"><is><t>${_escapeXml(val)}</t></is></c>');
      }
      sheetXml.writeln('</row>');
    }

    sheetXml.writeln('</sheetData>');

    // Merged Cells for Title and Subtitle banner
    sheetXml.writeln('<mergeCells count="2">');
    sheetXml.writeln('<mergeCell ref="A1:${lastColLetter}1"/>');
    sheetXml.writeln('<mergeCell ref="A2:${lastColLetter}2"/>');
    sheetXml.writeln('</mergeCells>');

    sheetXml.writeln('</worksheet>');

    addXml('xl/worksheets/sheet1.xml', sheetXml.toString());

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// Sanitize filename for local storage
  String sanitizeFileName(String title, String ext) {
    final cleanTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final timeStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${cleanTitle}_$timeStr.$ext';
  }

  /// Get public Download directory on device/emulator (specifically supporting MuMu Player & Android devices)
  static Future<Directory> getPublicDownloadDirectory() async {
    if (Platform.isAndroid) {
      // 1. Standard public Download directory on Android / MuMu Player
      final candidates = [
        Directory('/storage/emulated/0/Download'),
        Directory('/sdcard/Download'),
      ];

      for (final dir in candidates) {
        try {
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final testFile = File('${dir.path}/.test_write_${DateTime.now().millisecondsSinceEpoch}');
          testFile.writeAsStringSync('ok');
          testFile.deleteSync();
          return dir;
        } catch (_) {}
      }

      // 2. Fallback to path_provider external storage directory for downloads
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          final dir = extDirs.first;
          if (!dir.existsSync()) dir.createSync(recursive: true);
          return dir;
        }
      } catch (_) {}

      // 3. Fallback: try navigating from getExternalStorageDirectory() to /storage/emulated/0/Download
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final emulatedRoot = extDir.parent.parent.parent.parent;
          final downloadDir = Directory('${emulatedRoot.path}/Download');
          try {
            if (!downloadDir.existsSync()) downloadDir.createSync(recursive: true);
            final testFile = File('${downloadDir.path}/.test_write_${DateTime.now().millisecondsSinceEpoch}');
            testFile.writeAsStringSync('ok');
            testFile.deleteSync();
            return downloadDir;
          } catch (_) {}
          return extDir;
        }
      } catch (_) {}
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          if (!downloads.existsSync()) downloads.createSync(recursive: true);
          return downloads;
        }
      } catch (_) {}
    }

    return await getApplicationDocumentsDirectory();
  }

  /// Save bytes directly to device public Downloads folder
  Future<File> saveFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    final targetDir = await getPublicDownloadDirectory();
    final file = File('${targetDir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Export ReportExportData directly as styled Excel (.xlsx) spreadsheet
  Future<File> exportToExcelFile(ReportExportData data) async {
    final bytes = generateXlsxBytes(data);
    final fileName = sanitizeFileName(data.title, 'xlsx');
    return await saveFile(bytes: bytes, filename: fileName);
  }

  /// Export ReportExportData directly as formatted CSV file
  Future<File> exportToCsvFile(ReportExportData data) async {
    final csvContent = generateCsvString(data);
    final bytes = Uint8List.fromList(utf8.encode(csvContent));
    final fileName = sanitizeFileName(data.title, 'csv');
    return await saveFile(bytes: bytes, filename: fileName);
  }

  /// Build ReportExportData for any of the 5 report tabs
  static Future<ReportExportData> buildReportData({
    required int reportIndex,
    required String title,
    required String periodLabel,
    required DateTimeRange range,
    bool isAllTime = false,
    String currencySymbol = '\$',
  }) async {
    switch (reportIndex) {
      case 0: // Stock Summary
        String? periodCode;
        DateTime? fromDate;
        DateTime? toDate;

        if (!isAllTime) {
          final labelLower = periodLabel.toLowerCase();
          if (labelLower.startsWith('today')) {
            periodCode = 'TODAY';
          } else if (labelLower.startsWith('this week')) {
            periodCode = 'THIS_WEEK';
          } else if (labelLower.startsWith('this month')) {
            periodCode = 'THIS_MONTH';
          } else {
            periodCode = 'CUSTOM';
            fromDate = range.start;
            toDate = range.end;
          }
        }

        final all = await ReportDataService.fetchInventory(
          period: isAllTime ? periodCode : null,
          fromDate: isAllTime ? fromDate : null,
          toDate: isAllTime ? toDate : null,
        );
        final movements = isAllTime
            ? <StockMovement>[]
            : await ReportDataService.fetchMovements(range);

        final data = await ReportDataService.fetchInventorySummary(
          period: periodCode,
          fromDate: fromDate,
          toDate: toDate,
          isAllTime: isAllTime,
          periodMovements: movements,
          fallbackItems: all,
        );

        final summaryMetrics = <String, String>{
          'Total Items': '${data.totalItems}',
          'Total Units': '${data.totalUnits}',
          'Inventory Value': '$currencySymbol${data.valuation.toStringAsFixed(2)}',
          'In Stock': '${data.inStockCount}',
          'Low Stock': '${data.lowStockCount}',
          'Out of Stock': '${data.outOfStockCount}',
        };

        if (!isAllTime && (data.unitsIn > 0 || data.unitsOut > 0)) {
          summaryMetrics['Stock In Units'] = '+${data.unitsIn}';
          summaryMetrics['Stock Out Units'] = '-${data.unitsOut}';
          summaryMetrics['Net Units Change'] =
              '${data.netUnits >= 0 ? "+" : ""}${data.netUnits}';
        }

        return ReportExportData(
          title: title,
          periodLabel: periodLabel,
          summaryMetrics: summaryMetrics,
          headers: [
            'SKU',
            'Product Name',
            'Category',
            'Stock Quantity',
            'Unit Price',
            'Total Value',
            'Status',
          ],
          rows: [
            for (final p in data.products)
              [
                p.sku,
                p.name,
                p.categoryName,
                p.currentStock,
                '$currencySymbol${p.unitPrice.toStringAsFixed(2)}',
                '$currencySymbol${p.movementValue.toStringAsFixed(2)}',
                p.status,
              ],
          ],
        );

      case 1: // Stock In
        final list =
            await ReportDataService.fetchMovements(range, type: 'STOCK_IN');
        final totalUnits = list.fold<int>(0, (s, m) => s + m.quantity);

        return ReportExportData(
          title: title,
          periodLabel: periodLabel,
          summaryMetrics: {
            'Transactions': '${list.length}',
            'Total Units In': '+$totalUnits',
          },
          headers: [
            'Date & Time',
            'Product Name',
            'Type',
            'Quantity',
            'Stock Before',
            'Stock After',
            'Reference Note',
            'Recorded By',
          ],
          rows: [
            for (final m in list)
              [
                DateFormat('yyyy-MM-dd HH:mm:ss').format(m.date),
                m.productName,
                'STOCK_IN',
                '+${m.quantity}',
                m.stockBefore?.toString() ?? '-',
                m.stockAfter?.toString() ?? '-',
                m.note?.isNotEmpty == true ? m.note! : (m.reference ?? '-'),
                m.userName,
              ],
          ],
        );

      case 2: // Stock Out
        final list =
            await ReportDataService.fetchMovements(range, type: 'STOCK_OUT');
        final totalUnits = list.fold<int>(0, (s, m) => s + m.quantity);

        return ReportExportData(
          title: title,
          periodLabel: periodLabel,
          summaryMetrics: {
            'Transactions': '${list.length}',
            'Total Units Out': '-$totalUnits',
          },
          headers: [
            'Date & Time',
            'Product Name',
            'Type',
            'Reason',
            'Quantity',
            'Stock Before',
            'Stock After',
            'Reference Note',
            'Recorded By',
          ],
          rows: [
            for (final m in list)
              [
                DateFormat('yyyy-MM-dd HH:mm:ss').format(m.date),
                m.productName,
                'STOCK_OUT',
                m.reason == StockOutReason.damaged
                    ? 'DAMAGED'
                    : m.reason == StockOutReason.other
                        ? 'OTHER'
                        : 'SALE',
                '-${m.quantity}',
                m.stockBefore?.toString() ?? '-',
                m.stockAfter?.toString() ?? '-',
                m.note?.isNotEmpty == true ? m.note! : (m.reference ?? '-'),
                m.userName,
              ],
          ],
        );

      case 3: // Low Stock
        final all = await ReportDataService.fetchInventory(lowStockOnly: true);
        final items = isAllTime ? all : ReportDataService.updatedInRange(all, range);
        final outCount = items.where((i) => i.stockQuantity <= 0).length;

        return ReportExportData(
          title: title,
          periodLabel: periodLabel,
          summaryMetrics: {
            'Actionable Items': '${items.length}',
            'Out of Stock': '$outCount',
            'Low Stock': '${items.length - outCount}',
          },
          headers: [
            'SKU',
            'Product Name',
            'Category',
            'Supplier',
            'Current Stock',
            'Minimum Stock',
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
                i.stockQuantity,
                i.minimumStock,
                (i.minimumStock - i.stockQuantity).clamp(0, 1 << 30),
                i.stockQuantity <= 0 ? 'OUT_OF_STOCK' : 'LOW_STOCK',
              ],
          ],
        );

      case 4: // Transaction History
      default:
        final list = await ReportDataService.fetchMovements(range, type: null);
        final totalIn = list
            .where((m) => m.type == MovementType.stockIn)
            .fold<int>(0, (s, m) => s + m.quantity);
        final totalOut = list
            .where((m) => m.type == MovementType.stockOut)
            .fold<int>(0, (s, m) => s + m.quantity);

        return ReportExportData(
          title: title,
          periodLabel: periodLabel,
          summaryMetrics: {
            'Total Transactions': '${list.length}',
            'Total In': '+$totalIn',
            'Total Out': '-$totalOut',
            'Net Change':
                '${totalIn - totalOut >= 0 ? '+' : ''}${totalIn - totalOut}',
          },
          headers: [
            'Date & Time',
            'Product Name',
            'Type',
            'Reason',
            'Quantity',
            'Stock Before',
            'Stock After',
            'Reference Note',
            'Recorded By',
          ],
          rows: [
            for (final m in list)
              [
                DateFormat('yyyy-MM-dd HH:mm:ss').format(m.date),
                m.productName,
                m.type == MovementType.stockIn ? 'STOCK_IN' : 'STOCK_OUT',
                m.type == MovementType.stockOut
                    ? (m.reason == StockOutReason.damaged
                        ? 'DAMAGED'
                        : m.reason == StockOutReason.other
                            ? 'OTHER'
                            : 'SALE')
                    : '-',
                m.type == MovementType.stockIn
                    ? '+${m.quantity}'
                    : '-${m.quantity}',
                m.stockBefore?.toString() ?? '-',
                m.stockAfter?.toString() ?? '-',
                m.note?.isNotEmpty == true ? m.note! : (m.reference ?? '-'),
                m.userName,
              ],
          ],
        );
    }
  }

  /// Format file size into human-readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
