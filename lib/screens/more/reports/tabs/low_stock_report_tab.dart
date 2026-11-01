import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/core/services/report_data_service.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';
import 'package:inventory_management/models/inventory_report.dart';
import '../widgets/report_header_banner.dart';

/// Low Stock Report Tab
/// Highlights inventory shortages, reorder deficits, and direct restock navigation backed by ReportController.
class LowStockReportTab extends StatefulWidget {
  final DateTimeRange dateRange;
  final String periodLabel;

  const LowStockReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
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

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    List<InventoryReportItem>? items;
    try {
      // all pages, so the date filter sees every low-stock product
      items = await ReportDataService.fetchInventory(lowStockOnly: true);
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
    final categories = context.watch<CategoryProvider>();

    // Date filter: low-stock products updated inside the selected period
    final range = widget.dateRange;
    final items = _reportItems == null
        ? null
        : ReportDataService.updatedInRange(_reportItems!, range);
    final localLow = products.lowStockProducts
        .where((p) => ReportDataService.inRange(p.updatedAt, range))
        .toList();

    final lowStockCount = items != null
        ? items.where((i) => i.isLowStock || i.isOutOfStock).length
        : localLow.length;
    final outOfStockCount = items != null
        ? items.where((i) => i.isOutOfStock).length
        : localLow.where((p) => p.stockStatus == StockStatus.outOfStock).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportHeaderBanner(
          title: 'Low Stock Report',
          period: widget.periodLabel,
          subtitle: 'Low and out-of-stock products updated in this period',
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
          title: 'Actionable Items (${items?.length ?? localLow.length})',
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if ((items != null && items.isEmpty) ||
            (items == null && localLow.isEmpty))
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.inStock, size: 48),
                    SizedBox(height: 12),
                    Text('No low stock items in this period',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('No low or out-of-stock product was updated in the selected period.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  ],
                ),
              ),
            ),
          )
        else if (items != null)
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
                    Text('Category: ${p.categoryName} · SKU: ${p.sku}',
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
          })
        else
          ...localLow.map((p) {
            final cat = categories.findById(p.categoryId);
            final isOut = p.stockStatus == StockStatus.outOfStock;
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
                    Text('Category: ${cat?.name ?? "General"} · SKU: ${p.sku}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      'Current: ${p.quantity} ${p.unit} | Min Required: ${p.minStockLevel} ${p.unit} (Deficit: $deficit ${p.unit})',
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