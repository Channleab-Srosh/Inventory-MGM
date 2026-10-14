import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';

/// Reports screen with two tabs: Stock Report + Transaction Report
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Export'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Export feature coming soon!')));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Stock Report'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _StockReportTab(),
          _TransactionReportTab(),
        ],
      ),
    );
  }
}

class _StockReportTab extends StatelessWidget {
  const _StockReportTab();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final settings = context.watch<SettingsProvider>();

    final inStock = products.allProducts
        .where((p) => p.stockStatus == StockStatus.inStock)
        .length;
    final lowStock = products.allProducts
        .where((p) => p.stockStatus == StockStatus.lowStock)
        .length;
    final outOfStock = products.allProducts
        .where((p) => p.stockStatus == StockStatus.outOfStock)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'In Stock',
                value: '$inStock',
                icon: Icons.check_circle_outline,
                color: AppColors.inStock,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Low Stock',
                value: '$lowStock',
                icon: Icons.warning_amber_outlined,
                color: AppColors.lowStock,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Out of Stock',
                value: '$outOfStock',
                icon: Icons.cancel_outlined,
                color: AppColors.outOfStock,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Total Value',
                value: AppUtils.formatCurrency(
                    products.totalStockValue,
                    symbol: settings.currencySymbol),
                icon: Icons.attach_money,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Pie chart
        const SectionHeader(title: 'Stock Distribution'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: inStock.toDouble(),
                      color: AppColors.inStock,
                      title: '$inStock',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: lowStock.toDouble(),
                      color: AppColors.lowStock,
                      title: '$lowStock',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: outOfStock.toDouble(),
                      color: AppColors.outOfStock,
                      title: '$outOfStock',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      radius: 60,
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PieLegend(color: AppColors.inStock, label: 'In Stock'),
            const SizedBox(width: 16),
            _PieLegend(color: AppColors.lowStock, label: 'Low Stock'),
            const SizedBox(width: 16),
            _PieLegend(color: AppColors.outOfStock, label: 'Out of Stock'),
          ],
        ),
        const SizedBox(height: 20),

        // Product list
        const SectionHeader(title: 'All Products'),
        const SizedBox(height: 8),
        ...products.allProducts.map((p) => _ProductReportTile(
              product: p,
              symbol: settings.currencySymbol,
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _TransactionReportTab extends StatelessWidget {
  const _TransactionReportTab();

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final movements = stock.allMovements;
    final totalIn = movements
        .where((m) => m.type == MovementType.stockIn)
        .fold<int>(0, (s, m) => s + m.quantity);
    final totalOut = movements
        .where((m) => m.type == MovementType.stockOut)
        .fold<int>(0, (s, m) => s + m.quantity);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total In',
                value: '$totalIn',
                icon: Icons.arrow_downward,
                color: AppColors.chartIn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Total Out',
                value: '$totalOut',
                icon: Icons.arrow_upward,
                color: AppColors.chartOut,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SummaryCard(
          title: 'Total Movements',
          value: '${movements.length}',
          icon: Icons.swap_horiz,
          color: AppColors.primary,
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'All Transactions'),
        const SizedBox(height: 8),
        ...movements
            .toList()
            .reversed
            .map((m) => _TransactionTile(movement: m)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ProductReportTile extends StatelessWidget {
  final Product product;
  final String symbol;
  const _ProductReportTile({required this.product, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('SKU: ${product.sku}',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Qty: ${product.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  AppUtils.formatCurrency(product.price * product.quantity,
                      symbol: symbol),
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final StockMovement movement;
  const _TransactionTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.chartIn : AppColors.chartOut;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
              isIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: color, size: 18),
        ),
        title: Text(movement.productName,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(AppUtils.formatDateTime(movement.date),
            style: theme.textTheme.bodyMedium),
        trailing: Text(
          '${isIn ? '+' : '-'}${movement.quantity}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _PieLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
      ],
    );
  }
}
