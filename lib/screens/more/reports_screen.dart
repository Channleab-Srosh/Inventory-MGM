import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_pdf_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import 'reports/tabs/stock_summary_tab.dart';
import 'reports/tabs/stock_in_report_tab.dart';
import 'reports/tabs/stock_out_report_tab.dart';
import 'reports/tabs/low_stock_report_tab.dart';
import 'reports/tabs/transaction_history_tab.dart';


enum DateFilterPeriod { today, thisWeek, thisMonth, custom }

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
  DateFilterPeriod _selectedPeriod = DateFilterPeriod.thisMonth;
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
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case DateFilterPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case DateFilterPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
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
      case DateFilterPeriod.custom:
        return '${fmt.format(range.start)} - ${fmt.format(range.end)}';
    }
  }

  void _exportReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report: ${_getReportTitle(_tabCtrl.index)}'),
            const SizedBox(height: 6),
            Text('Period: ${_getPeriodLabel()}'),
            const SizedBox(height: 16),
            const Text(
              'Export as:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.outOfStockText),
                  label: const Text('PDF Document'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _exportPdf(context);
                  },
                ),
              ],
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

  /// Builds the PDF for the currently selected report tab and opens the
  /// share / save sheet.
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
        currencySymbol: symbol,
      );
      messenger.hideCurrentSnackBar();
      final path = await ReportPdfService.share(bytes, title);
      messenger.showSnackBar(
        SnackBar(
          content: Text('PDF saved: $path'),
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
                            _customDateRange = picked;
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
              StockSummaryReportTab(dateRange: range, periodLabel: periodLabel),
              StockInReportTab(dateRange: range, periodLabel: periodLabel),
              StockOutReportTab(dateRange: range, periodLabel: periodLabel),
              LowStockReportTab(dateRange: range, periodLabel: periodLabel),
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