import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/stock_movement.dart';
import '../../models/product.dart';

/// Features 9, 10, 11, 12, 13: Professional Mobile Dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final stock = context.watch<StockProvider>();
    final theme = Theme.of(context);
    final userName = auth.user?.firstName ?? auth.user?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, $userName',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            Text(
              "Today's Overview",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Feature 10: Summary Cards (Total Products, Total Stock, Low Stock, Out of Stock)
            _SummaryGrid(products: products),
            const SizedBox(height: 20),

            // Feature 11: Low Stock Products compact section
            _LowStockSection(products: products),
            const SizedBox(height: 20),

            // Feature 13: Stock Movement Chart (Stock In / Stock Out)
            const SectionHeader(title: 'Stock Movement (7 Days)'),
            const SizedBox(height: 10),
            _StockChart(
              stockIn: stock.stockInLast7Days,
              stockOut: stock.stockOutLast7Days,
            ),
            const SizedBox(height: 24),

            // Feature 12: Recent Transactions
            SectionHeader(
              title: 'Recent Transactions',
              trailing: TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('View All →'),
              ),
            ),
            const SizedBox(height: 8),
            if (stock.recentMovements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No recent transactions found',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              )
            else
              ...stock.recentMovements.take(6).map(
                    (m) => _TransactionTile(movement: m),
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Feature 10: Summary Cards
class _SummaryGrid extends StatelessWidget {
  final ProductProvider products;
  const _SummaryGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 500 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth > 500 ? 1.4 : 1.35,
          children: [
            SummaryCard(
              title: 'Total Products',
              value: '${products.totalProducts}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
              onTap: () => context.go('/products'),
            ),
            SummaryCard(
              title: 'Total Stock',
              value: AppUtils.formatNumber(products.totalQuantity),
              icon: Icons.layers_outlined,
              color: AppColors.inStock,
              onTap: () => context.go('/products'),
            ),
            SummaryCard(
              title: 'Low Stock',
              value: '${products.lowStockCount}',
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
              onTap: () {
                products.setStatusFilter(StockStatus.lowStock);
                context.go('/products');
              },
            ),
            SummaryCard(
              title: 'Out of Stock',
              value: '${products.outOfStockCount}',
              icon: Icons.cancel_outlined,
              color: AppColors.danger,
              onTap: () {
                products.setStatusFilter(StockStatus.outOfStock);
                context.go('/products');
              },
            ),
          ],
        );
      },
    );
  }
}

/// Feature 11: Low Stock Products compact section
class _LowStockSection extends StatelessWidget {
  final ProductProvider products;
  const _LowStockSection({required this.products});

  @override
  Widget build(BuildContext context) {
    final lowStockItems = products.lowStockProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Low Stock',
          trailing: TextButton(
            onPressed: () {
              products.setStatusFilter(StockStatus.lowStock);
              context.go('/products');
            },
            child: const Text('View All →'),
          ),
        ),
        const SizedBox(height: 8),
        if (lowStockItems.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'All products have healthy stock levels',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lowStockItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = lowStockItems[i];
                final isOut = p.stockStatus == StockStatus.outOfStock;
                final badgeColor = isOut ? AppColors.danger : AppColors.warning;
                final statusLabel = isOut ? 'OUT OF STOCK' : 'LOW STOCK';

                return InkWell(
                  onTap: () => context.push('/products/${p.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 165,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock: ${p.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                            Text(
                              'Minimum: ${p.minStockLevel}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Feature 12: Recent Transactions tile
class _TransactionTile extends StatelessWidget {
  final StockMovement movement;
  const _TransactionTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == MovementType.stockIn;
    final color = isIn ? AppColors.success : AppColors.danger;
    final icon = isIn ? Icons.south_west : Icons.north_east;
    final sign = isIn ? '+' : '-';
    final typeLabel = isIn ? 'Stock In' : 'Stock Out';

    final now = DateTime.now();
    final isToday = movement.date.year == now.year &&
        movement.date.month == now.month &&
        movement.date.day == now.day;
    final dateStr = isToday ? 'Today' : DateFormat('MMM d').format(movement.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          movement.productName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$typeLabel • $dateStr',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
        trailing: Text(
          '$sign${movement.quantity}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Feature 13: Stock Movement Chart (fl_chart)
class _StockChart extends StatelessWidget {
  final List<double> stockIn;
  final List<double> stockOut;

  const _StockChart({required this.stockIn, required this.stockOut});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d).substring(0, 2);
    });

    final maxVal = [
      ...stockIn,
      ...stockOut,
      10.0,
    ].reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ChartLegend(label: 'Stock In', color: AppColors.success),
                const SizedBox(width: 16),
                _ChartLegend(label: 'Stock Out', color: AppColors.danger),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal * 1.25).ceilToDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final type = rod.color == AppColors.success ? 'In' : 'Out';
                        return BarTooltipItem(
                          '$type: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i >= 0 && i < dayLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                dayLabels[i],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxVal * 1.25) / 3).ceilToDouble().clamp(1.0, 1000.0),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final inQty = i < stockIn.length ? stockIn[i] : 0.0;
                    final outQty = i < stockOut.length ? stockOut[i] : 0.0;

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: inQty,
                          color: AppColors.success,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: outQty,
                          color: AppColors.danger,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _ChartLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
