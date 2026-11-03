import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/models/stock_movement.dart';
import '../widgets/report_header_banner.dart';

/// Stock Out Report Tab
/// Displays dispatched goods, sales fulfillment, damaged items, backed by ReportController.
class StockOutReportTab extends StatefulWidget {
  final DateTimeRange dateRange;
  final String periodLabel;

  const StockOutReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
  });

  @override
  State<StockOutReportTab> createState() => _StockOutReportTabState();
}

class _StockOutReportTabState extends State<StockOutReportTab> {
  List<StockMovement>? _reportMovements;
  bool _isLoading = false;
  StockOutReason? _selectedReasonFilter;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  @override
  void didUpdateWidget(covariant StockOutReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange) {
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    final stock = context.read<StockProvider>();
    final results = await stock.fetchTransactionReport(
      type: 'STOCK_OUT',
      fromDate: widget.dateRange.start,
      toDate: widget.dateRange.end,
    );
    if (mounted) {
      setState(() {
        _reportMovements = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();

    final outMovements = _reportMovements ??
        stock.getMovementsBetween(
          widget.dateRange.start,
          widget.dateRange.end,
          type: MovementType.stockOut,
        );

    final totalQuantity = outMovements.fold<int>(0, (s, m) => s + m.quantity);
    final totalSales = outMovements
        .where((m) => m.reason == StockOutReason.sale)
        .fold<int>(0, (s, m) => s + m.quantity);
    final totalDamaged = outMovements
        .where((m) => m.reason == StockOutReason.damaged)
        .fold<int>(0, (s, m) => s + m.quantity);
    final totalOther = outMovements
        .where((m) => m.reason == StockOutReason.other)
        .fold<int>(0, (s, m) => s + m.quantity);

    final displayedMovements = _selectedReasonFilter == null
        ? outMovements
        : outMovements.where((m) => m.reason == _selectedReasonFilter).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportHeaderBanner(
          title: 'Stock Out Report',
          period: widget.periodLabel,
          subtitle: 'Dispatched goods, sales fulfillment, and damaged stock write-offs',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Dispatched',
                value: '-$totalQuantity units',
                icon: Icons.arrow_upward,
                color: AppColors.chartOut,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Orders / Events',
                value: '${outMovements.length}',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Sales Out',
                value: '$totalSales units',
                icon: Icons.point_of_sale,
                color: AppColors.inStock,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Damaged / Other',
                value: '${totalDamaged + totalOther} units',
                icon: Icons.delete_sweep_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Reason filter chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('All (${outMovements.length})'),
              selected: _selectedReasonFilter == null,
              onSelected: (_) => setState(() => _selectedReasonFilter = null),
            ),
            ChoiceChip(
              label: Text('Sales (${outMovements.where((m) => m.reason == StockOutReason.sale).length})'),
              selected: _selectedReasonFilter == StockOutReason.sale,
              selectedColor: AppColors.inStock.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedReasonFilter == StockOutReason.sale ? AppColors.inStock : null,
              ),
              onSelected: (_) => setState(() => _selectedReasonFilter = StockOutReason.sale),
            ),
            ChoiceChip(
              label: Text('Damaged (${outMovements.where((m) => m.reason == StockOutReason.damaged).length})'),
              selected: _selectedReasonFilter == StockOutReason.damaged,
              selectedColor: AppColors.danger.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedReasonFilter == StockOutReason.damaged ? AppColors.danger : null,
              ),
              onSelected: (_) => setState(() => _selectedReasonFilter = StockOutReason.damaged),
            ),
            ChoiceChip(
              label: Text('Other (${outMovements.where((m) => m.reason == StockOutReason.other).length})'),
              selected: _selectedReasonFilter == StockOutReason.other,
              selectedColor: AppColors.warning.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _selectedReasonFilter == StockOutReason.other ? AppColors.warning : null,
              ),
              onSelected: (_) => setState(() => _selectedReasonFilter = StockOutReason.other),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SectionHeader(title: 'Dispatched Transactions (${displayedMovements.length})'),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (displayedMovements.isEmpty)
          const EmptyState(
            message: 'No Stock Out records in this period',
            subtitle: 'Try changing the date or reason filter',
            icon: Icons.arrow_upward,
          )
        else
          ...displayedMovements.map((m) {
            final String reasonText;
            final Color reasonColor;
            switch (m.reason) {
              case StockOutReason.damaged:
                reasonText = 'DAMAGED';
                reasonColor = AppColors.danger;
                break;
              case StockOutReason.other:
                reasonText = 'OTHER';
                reasonColor = AppColors.warning;
                break;
              case StockOutReason.sale:
              default:
                reasonText = 'SALE';
                reasonColor = AppColors.inStock;
                break;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.chartOut.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_upward,
                              color: AppColors.chartOut, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${AppUtils.formatDateTime(m.date)} · by ${m.userName}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-${m.quantity} ${m.unit ?? "pcs"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.chartOut,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Stock: ${m.stockBefore ?? "-"} → ${m.stockAfter ?? "-"} units',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: reasonColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: reasonColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              reasonText,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: reasonColor),
                            ),
                          ),
                          if (m.reference != null && m.reference!.isNotEmpty)
                            Text(
                              'Ref: ${m.reference}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.secondaryText),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}
