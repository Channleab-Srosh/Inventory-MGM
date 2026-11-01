import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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

/// Service handling file export, saving to device storage, and CSV generation
class ReportExportService {
  ReportExportService._();
  static final ReportExportService instance = ReportExportService._();

  /// Escape a CSV cell value according to RFC 4180
  String _escapeCsvCell(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Generate RFC 4180 CSV string with UTF-8 BOM for Microsoft Excel compatibility
  String generateCsvString(ReportExportData data) {
    final buffer = StringBuffer();
    // UTF-8 Byte Order Mark (BOM) so Excel opens UTF-8 files correctly
    buffer.write('\uFEFF');

    // Header metadata
    buffer.writeln('${_escapeCsvCell("Report:")},${_escapeCsvCell(data.title)}');
    buffer.writeln('${_escapeCsvCell("Period:")},${_escapeCsvCell(data.periodLabel)}');
    buffer.writeln(
        '${_escapeCsvCell("Generated:")},${_escapeCsvCell(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()))}');
    buffer.writeln(); // Blank line

    // Summary metrics block
    if (data.summaryMetrics != null && data.summaryMetrics!.isNotEmpty) {
      buffer.writeln(_escapeCsvCell('--- SUMMARY METRICS ---'));
      for (final entry in data.summaryMetrics!.entries) {
        buffer.writeln('${_escapeCsvCell(entry.key)},${_escapeCsvCell(entry.value)}');
      }
      buffer.writeln(); // Blank line
    }

    // Table headers
    buffer.writeln(data.headers.map(_escapeCsvCell).join(','));

    // Table rows
    for (final row in data.rows) {
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }

    return buffer.toString();
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

  /// Save bytes directly to device storage (Downloads or Documents directory)
  Future<File> saveFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    Directory targetDir;
    try {
      if (Platform.isAndroid || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final downloads = await getDownloadsDirectory();
        if (downloads != null && await downloads.exists()) {
          targetDir = downloads;
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      targetDir = await getApplicationDocumentsDirectory();
    }

    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Export ReportExportData directly as CSV file
  Future<File> exportToCsvFile(ReportExportData data) async {
    final csvContent = generateCsvString(data);
    final bytes = Uint8List.fromList(utf8.encode(csvContent));
    final fileName = sanitizeFileName(data.title, 'csv');
    return await saveFile(bytes: bytes, filename: fileName);
  }

  /// Format file size into human-readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
