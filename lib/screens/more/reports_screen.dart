import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_pdf_service.dart';
import '../../core/utils/report_export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import 'reports/tabs/stock_summary_tab.dart';
import 'reports/tabs/stock_in_report_tab.dart';
import 'reports/tabs/stock_out_report_tab.dart';
import 'reports/tabs/low_stock_report_tab.dart';
import 'reports/tabs/transaction_history_tab.dart';


enum DateFilterPeriod { allTime, today, thisWeek, thisMonth, custom }

/// Feature 13: Reports Screen matching Notion specifications
/// Basic Reports:
/// 1. Stock Summary
/// 2. Stock In Report
/// 3. Stock Out Report
/// 4. Low Stock Report
/// 5. Transaction History
/// Date filtering: Today, This Week, This Month, Custom Date
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateFilterPeriod _selectedPeriod = DateFilterPeriod.allTime;
  DateTimeRange _customDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  DateTimeRange _getActiveDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case DateFilterPeriod.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case DateFilterPeriod.thisWeek:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0),
          end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59, 999),
        );
      case DateFilterPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(
          start: startOfMonth,
          end: endOfMonth,
        );
      case DateFilterPeriod.allTime:
        return DateTimeRange(
          start: DateTime(2020, 1, 1, 0, 0, 0),
          end: DateTime(2035, 12, 31, 23, 59, 59, 999),
        );
      case DateFilterPeriod.custom:
        return _customDateRange;
    }
  }

  String _getPeriodLabel() {
    final range = _getActiveDateRange();
    final fmt = DateFormat('MMM d, yyyy');
    switch (_selectedPeriod) {
      case DateFilterPeriod.today:
        return 'Today (${DateFormat("MMM d").format(range.start)})';
      case DateFilterPeriod.thisWeek:
        return 'This Week (${fmt.format(range.start)} - ${fmt.format(range.end)})';
      case DateFilterPeriod.thisMonth:
        return 'This Month (${DateFormat("MMMM yyyy").format(range.start)})';
      case DateFilterPeriod.allTime:
        return 'All Time (${fmt.format(DateTime.now())})';
      case DateFilterPeriod.custom:
        return '${fmt.format(range.start)} - ${fmt.format(range.end)}';
    }
  }

  void _exportReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Report', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getReportTitle(_tabCtrl.index),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getPeriodLabel(),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Export Format:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            // 1. Excel (.xlsx) Option
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(ctx);
                _exportExcel(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.table_chart_rounded, color: Color(0xFF107C41), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Excel Spreadsheet (.xlsx)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          Text('Color headers, KPI cards & styled table',
                              style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            const Divider(height: 12),
            // 2. PDF Document Option
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(ctx);
                _exportPdf(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.outOfStockText.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.outOfStockText, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PDF Document (.pdf)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          Text('Landscape layout for printing & sharing',
                              style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            const Divider(height: 12),
            // 3. CSV Document Option
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(ctx);
                _exportCsv(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.grid_on_rounded, color: Colors.blueGrey, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CSV Document (.csv)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          Text('Formatted plain-text with executive banner',
                              style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Exports the currently selected report as a styled Microsoft Excel (.xlsx) file
  /// with matching PDF colors, KPI metric cards, and table styling, saved directly to Downloads.
  Future<void> _exportExcel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final index = _tabCtrl.index;
    final title = _getReportTitle(index);
    final range = _getActiveDateRange();
    final period = _getPeriodLabel();
    final symbol = context.read<SettingsProvider>().currencySymbol;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Generating $title Excel (.xlsx)...')),
          ],
        ),
        duration: const Duration(minutes: 2),
      ),
    );

    try {
      final exportData = await ReportExportService.buildReportData(
        reportIndex: index,
        title: title,
        periodLabel: period,
        range: range,
        isAllTime: _selectedPeriod == DateFilterPeriod.allTime,
        currencySymbol: symbol,
      );
      final file = await ReportExportService.instance.exportToExcelFile(exportData);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Excel (.xlsx) saved to Downloads folder:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(file.path, style: const TextStyle(fontSize: 12)),
            ],
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: AppColors.inStock,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Excel export failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.outOfStockText,
        ),
      );
    }
  }

  /// Builds the PDF for the currently selected report tab and saves directly to
  /// the phone's Download folder (MuMu Phone / Android).
  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final index = _tabCtrl.index;
    final title = _getReportTitle(index);
    final range = _getActiveDateRange();
    final period = _getPeriodLabel();
    final symbol = context.read<SettingsProvider>().currencySymbol;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Generating $title PDF...')),
          ],
        ),
        duration: const Duration(minutes: 2),
      ),
    );

    try {
      final bytes = await ReportPdfService.build(
        reportIndex: index,
        title: title,
        periodLabel: period,
        range: range,
        isAllTime: _selectedPeriod == DateFilterPeriod.allTime,
        currencySymbol: symbol,
      );
      messenger.hideCurrentSnackBar();
      final path = await ReportPdfService.share(bytes, title);
      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PDF saved to Downloads folder:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(path, style: const TextStyle(fontSize: 12)),
            ],
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'PDF export failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.outOfStockText,
        ),
      );
    }
  }

  /// Exports the currently selected report as an Excel-compatible CSV and saves directly to
  /// the phone's Download folder (MuMu Phone / Android).
  Future<void> _exportCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final index = _tabCtrl.index;
    final title = _getReportTitle(index);
    final range = _getActiveDateRange();
    final period = _getPeriodLabel();
    final symbol = context.read<SettingsProvider>().currencySymbol;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Generating $title CSV...')),
          ],
        ),
        duration: const Duration(minutes: 2),
      ),
    );

    try {
      final exportData = await ReportExportService.buildReportData(
        reportIndex: index,
        title: title,
        periodLabel: period,
        range: range,
        isAllTime: _selectedPeriod == DateFilterPeriod.allTime,
        currencySymbol: symbol,
      );
      final file = await ReportExportService.instance.exportToCsvFile(exportData);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CSV saved to Downloads folder:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(file.path, style: const TextStyle(fontSize: 12)),
            ],
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: AppColors.inStock,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'CSV export failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.outOfStockText,
        ),
      );
    }
  }

  String _getReportTitle(int index) {
    switch (index) {
      case 0:
        return 'Stock Summary Report';
      case 1:
        return 'Stock In Report';
      case 2:
        return 'Stock Out Report';
      case 3:
        return 'Low Stock Report';
      case 4:
        return 'Transaction History Report';
      default:
        return 'Inventory Report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _getActiveDateRange();
    final periodLabel = _getPeriodLabel();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        title: const Text('Reports'),
        actions: [
          GestureDetector(
            onTap: () => _exportReport(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: 16, color: AppColors.secondaryText),
                  SizedBox(width: 6),
                  Text(
                    'Export',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Date Filter Pills (Today, This Week, This Month, Custom Date)
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    _PeriodChip(
                      label: 'All Time',
                      selected: _selectedPeriod == DateFilterPeriod.allTime,
                      onTap: () =>
                          setState(() => _selectedPeriod = DateFilterPeriod.allTime),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'Today',
                      selected: _selectedPeriod == DateFilterPeriod.today,
                      onTap: () =>
                          setState(() => _selectedPeriod = DateFilterPeriod.today),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'This Week',
                      selected: _selectedPeriod == DateFilterPeriod.thisWeek,
                      onTap: () => setState(
                          () => _selectedPeriod = DateFilterPeriod.thisWeek),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'This Month',
                      selected: _selectedPeriod == DateFilterPeriod.thisMonth,
                      onTap: () => setState(
                          () => _selectedPeriod = DateFilterPeriod.thisMonth),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'Custom Date',
                      icon: Icons.calendar_month_rounded,
                      selected: _selectedPeriod == DateFilterPeriod.custom,
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _customDateRange,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppColors.primaryDark,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _customDateRange = DateTimeRange(
                              start: DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
                              end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999),
                            );
                            _selectedPeriod = DateFilterPeriod.custom;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Report Category Tabs with pill-style indicator
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.secondaryText,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                indicator: BoxDecoration(
                  color: AppColors.primaryActive,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: -8, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Stock Summary'),
                  Tab(text: 'Stock In'),
                  Tab(text: 'Stock Out'),
                  Tab(text: 'Low Stock'),
                  Tab(text: 'Transactions'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              StockSummaryReportTab(
                dateRange: range,
                periodLabel: periodLabel,
                isAllTime: _selectedPeriod == DateFilterPeriod.allTime,
              ),
              StockInReportTab(dateRange: range, periodLabel: periodLabel),
              StockOutReportTab(dateRange: range, periodLabel: periodLabel),
              LowStockReportTab(
                dateRange: range,
                periodLabel: periodLabel,
                isAllTime: _selectedPeriod == DateFilterPeriod.allTime,
              ),
              TransactionHistoryReportTab(dateRange: range, periodLabel: periodLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryActive : AppColors.card,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14,
                    color: selected ? AppColors.primaryDark : AppColors.secondaryText),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primaryDark : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}