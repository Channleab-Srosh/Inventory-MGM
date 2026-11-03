import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_management/providers/settings_provider.dart';
import 'package:inventory_management/core/services/report_data_service.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/inventory_report.dart';
import 'package:inventory_management/models/stock_movement.dart';
import '../widgets/report_header_banner.dart';

/// Stock Summary Report Tab
/// Displays catalog health, unit totals, inventory valuation, and stock movement
/// summary for the selected period (Today, This Week, This Month, All Time, Custom).
class StockSummaryReportTab extends StatefulWidget {
  final DateTimeRange dateRange;
  final String periodLabel;
  final bool isAllTime;

  const StockSummaryReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
    this.isAllTime = false,
  });

  @override
  State<StockSummaryReportTab> createState() => _StockSummaryReportTabState();
}

class _StockSummaryReportTabState extends State<StockSummaryReportTab> {
  List<InventoryReportItem>? _allItems;
  List<StockMovement>? _periodMovements;
  StockSummaryData? _summaryData;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StockSummaryReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodLabel != widget.periodLabel ||
        oldWidget.dateRange != widget.dateRange ||
        oldWidget.isAllTime != widget.isAllTime) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      String? periodCode;
      DateTime? fromDate;
      DateTime? toDate;

      if (!widget.isAllTime) {
        final labelLower = widget.periodLabel.toLowerCase();
        if (labelLower.startsWith('today')) {
          periodCode = 'TODAY';
        } else if (labelLower.startsWith('this week')) {
          periodCode = 'THIS_WEEK';
        } else if (labelLower.startsWith('this month')) {
          periodCode = 'THIS_MONTH';
        } else {
          periodCode = 'CUSTOM';
          fromDate = widget.dateRange.start;
          toDate = widget.dateRange.end;
        }
      }

      final itemsFuture = widget.isAllTime
          ? ReportDataService.fetchInventory(
              period: periodCode,
              fromDate: fromDate,
              toDate: toDate,
            )
          : ReportDataService.fetchInventory();
      final movementsFuture = widget.isAllTime
          ? Future.value(<StockMovement>[])
          : ReportDataService.fetchMovements(widget.dateRange);

      final results = await Future.wait([itemsFuture, movementsFuture]);
      final items = results[0] as List<InventoryReportItem>;
      final movements = results[1] as List<StockMovement>;

      final summary = await ReportDataService.fetchInventorySummary(
        period: periodCode,
        fromDate: fromDate,
        toDate: toDate,
        isAllTime: widget.isAllTime,
        periodMovements: movements,
        fallbackItems: items,
      );

      if (mounted) {
        setState(() {
          _allItems = items;
          _periodMovements = movements;
          _summaryData = summary;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  PieChartSectionData _section(int value, Color color, bool compact) {
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      title: '$value',
      radius: compact ? 35 : 45,
      titleStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final header = ReportHeaderBanner(
      title: 'Stock Summary Report',
      period: widget.periodLabel,
      subtitle: widget.isAllTime
          ? 'Complete overview of catalog health, valuation and stock levels'
          : 'Stock distribution, valuation and movement summary for ${widget.periodLabel}',
    );

    if (_loading && _allItems == null && _summaryData == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header,
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_failed && _summaryData == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header,
          const SizedBox(height: 24),
          const Center(child: Text('Could not load the report.')),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }

    // Aggregated stock summary
    final data = _summaryData ??
        ReportDataService.calculateSummary(
          allItems: _allItems ?? [],
          periodMovements: _periodMovements ?? [],
          isAllTime: widget.isAllTime,
        );

    final hasMovements = data.unitsIn > 0 || data.unitsOut > 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header,
          const SizedBox(height: 16),

          // Top Inventory Snapshot Cards based on selected period
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Total Items',
                  value: '${data.totalItems}',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  title: widget.isAllTime ? 'Total Units' : 'Net Units',
                  value: widget.isAllTime
                      ? AppUtils.formatNumber(data.totalUnits)
                      : '${data.netUnits >= 0 ? "+" : ""}${AppUtils.formatNumber(data.netUnits)}',
                  icon: Icons.layers_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SummaryCard(
            title: widget.isAllTime
                ? 'Total Inventory Valuation'
                : 'Net Valuation Change',
            value: AppUtils.formatCurrency(data.valuation,
                symbol: settings.currencySymbol),
            icon: Icons.attach_money,
            color: AppColors.inStock,
          ),

          // Additional Period Movement Activity (when movements exist in the period)
          if (!widget.isAllTime && hasMovements) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Stock In Units',
                    value: '+${AppUtils.formatNumber(data.unitsIn)}',
                    icon: Icons.arrow_downward,
                    color: AppColors.chartIn,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SummaryCard(
                    title: 'Stock Out Units',
                    value: '-${AppUtils.formatNumber(data.unitsOut)}',
                    icon: Icons.arrow_upward,
                    color: AppColors.chartOut,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Stock Status Distribution
          const SectionHeader(
            title: 'Stock Status Distribution',
          ),
          const SizedBox(height: 8),
          if (data.totalItems == 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No stock records found for ${widget.periodLabel}.',
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;

                    final pieWidget = SizedBox(
                      height: isCompact ? 160 : 180,
                      width: isCompact ? 160 : 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: isCompact ? 35 : 45,
                          sections: [
                            if (data.inStockCount > 0)
                              _section(
                                  data.inStockCount, AppColors.inStock, isCompact),
                            if (data.lowStockCount > 0)
                              _section(
                                  data.lowStockCount, AppColors.warning, isCompact),
                            if (data.outOfStockCount > 0)
                              _section(
                                  data.outOfStockCount, AppColors.danger, isCompact),
                          ],
                        ),
                      ),
                    );

                    final legendWidget = Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                            'In Stock (${data.inStockCount})', AppColors.inStock),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                            'Low Stock (${data.lowStockCount})', AppColors.warning),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                            'Out of Stock (${data.outOfStockCount})',
                            AppColors.danger),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          pieWidget,
                          const SizedBox(height: 16),
                          legendWidget,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        pieWidget,
                        const SizedBox(width: 20),
                        Expanded(child: legendWidget),
                      ],
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Category Stock Breakdown
          const SectionHeader(
            title: 'Category Stock Breakdown',
          ),
          const SizedBox(height: 8),
          if (data.categories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No category stock data available for ${widget.periodLabel}.',
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.categories.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final cat = data.categories[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.category_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    title: Text(cat.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${cat.itemsCount} items · ${AppUtils.formatNumber(cat.currentUnits)} units',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      AppUtils.formatCurrency(cat.currentValue,
                          symbol: settings.currencySymbol),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
