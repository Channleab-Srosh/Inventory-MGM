import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/core/services/report_data_service.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/inventory_report.dart';
import '../widgets/report_header_banner.dart';

/// Low Stock Report Tab
/// Highlights inventory shortages, reorder deficits, and direct restock navigation backed by ReportController.
class LowStockReportTab extends StatefulWidget {
  final DateTimeRange dateRange;
  final String periodLabel;
  final bool isAllTime;

  const LowStockReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
    this.isAllTime = false,
  });

  @override
  State<LowStockReportTab> createState() => _LowStockReportTabState();
}

class _LowStockReportTabState extends State<LowStockReportTab> {
  List<InventoryReportItem>? _reportItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  @override
  void didUpdateWidget(covariant LowStockReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodLabel != widget.periodLabel ||
        oldWidget.dateRange != widget.dateRange ||
        oldWidget.isAllTime != widget.isAllTime) {
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    List<InventoryReportItem>? items;
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

      // all pages, so the date filter sees every low-stock product
      items = await ReportDataService.fetchInventory(
        lowStockOnly: true,
        period: periodCode,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (_) {
      items = null; // falls back to the products already loaded in the app
    }
    if (mounted) {
      setState(() {
        _reportItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();

    final allItems = _reportItems ??
        products.lowStockProducts
            .map((p) => InventoryReportItem(
                  id: p.id,
                  sku: p.sku,
                  name: p.name,
                  categoryName: p.categoryName,
                  unitPrice: p.price,
                  stockQuantity: p.quantity,
                  minimumStock: p.minStockLevel,
                  totalValue: p.price * p.quantity,
                  lowStock: p.quantity > 0 && p.quantity <= p.minStockLevel,
                  active: p.status.toLowerCase() == 'active',
                  updatedAt: p.updatedAt,
                ))
            .toList();

    final items = widget.isAllTime
        ? allItems
        : ReportDataService.updatedInRange(allItems, widget.dateRange);

    final lowStockCount = items.where((i) => i.isLowStock).length;
    final outOfStockCount = items.where((i) => i.isOutOfStock).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportHeaderBanner(
          title: 'Low Stock Report',
          period: widget.periodLabel,
          subtitle: widget.isAllTime
              ? 'All products currently below minimum stock threshold'
              : 'Low and out-of-stock products updated in this period',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Low Stock',
                value: '$lowStockCount',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Out of Stock',
                value: '$outOfStockCount',
                icon: Icons.cancel_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SectionHeader(
          title: 'Actionable Items (${items.length})',
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.inStock, size: 48),
                    const SizedBox(height: 12),
                    Text(widget.isAllTime
                        ? 'No low stock items currently'
                        : 'No low stock items in this period',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(widget.isAllTime
                        ? 'All products are currently stocked above their minimum thresholds.'
                        : 'No low or out-of-stock product was updated in the selected period.',
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  ],
                ),
              ),
            ),
          )
        else
          ...items.map((p) {
            final isOut = p.isOutOfStock;
            final deficit = (p.minStockLevel - p.quantity).clamp(0, 9999);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isOut ? AppColors.danger : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOut ? Icons.error_outline : Icons.warning_amber_outlined,
                    color: isOut ? AppColors.danger : AppColors.warning,
                  ),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ${p.categoryName ?? "General"} · SKU: ${p.sku}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      'Current: ${p.quantity} | Min Required: ${p.minStockLevel} (Deficit: $deficit)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOut ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    final targetQty = deficit > 0 ? deficit : 1;
                    context.go('/stock?tab=in&productId=${p.id}&quantity=$targetQty');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chartIn,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text('Restock', style: TextStyle(fontSize: 12)),
                ),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}