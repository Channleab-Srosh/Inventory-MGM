import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/models/product.dart';
import 'package:inventory_management/models/stock_movement.dart';
import 'package:inventory_management/models/dashboard_summary.dart';

/// Bento Metric Grid:
/// 2x2 grid of square cards:
/// - Top-Left: Solid lavender card (#A594F9), white circle icon, '$45,210', 'Total Stock Value', '↗'
/// - Top-Right: Pure white card, mint green circle icon, '1,284', 'Total Stock', '↗'
/// - Bottom-Left: Pure white card, coral circle icon, '08', 'Out of Stock', '↗'
/// - Bottom-Right: Pure white card, amber circle icon, '23', 'Low Stock', '↗'
/// Fixed to All Time (live snapshot) without period dropdowns.
class DashboardSummaryGrid extends StatelessWidget {
  final ProductProvider products;
  final StockProvider stock;
  final DashboardSummary? summary;

  const DashboardSummaryGrid({
    super.key,
    required this.products,
    required this.stock,
    this.summary,
  });

  int _calculateNetStockUnits() {
    if (summary?.netAvailableStock != null && summary!.netAvailableStock > 0) {
      return summary!.netAvailableStock;
    }
    if (products.totalQuantity > 0) {
      return products.totalQuantity;
    }
    final inQty = stock.allMovements
        .where((m) => m.type == MovementType.stockIn)
        .fold<int>(0, (sum, m) => sum + m.quantity);
    final outQty = stock.allMovements
        .where((m) => m.type == MovementType.stockOut)
        .fold<int>(0, (sum, m) => sum + m.quantity);
    return inQty - outQty;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Total stock value (All Time live inventory)
    final double totalStockValue = (summary?.totalInventoryValue ?? 0.0) > 0
        ? summary!.totalInventoryValue
        : products.allProducts
            .where((p) => p.status.toLowerCase() == 'active' && p.quantity > 0)
            .fold<double>(
              0.0,
              (sum, p) => sum + (p.quantity * p.price),
            );
    final String formattedStockValue = AppUtils.formatCurrency(totalStockValue);

    // 2. Total Stock units on hand (All Time live available stock)
    final int netStockUnits = (summary?.netAvailableStock ?? 0) > 0
        ? summary!.netAvailableStock
        : (products.totalQuantity > 0
            ? products.totalQuantity
            : _calculateNetStockUnits());
    final String formattedTotalStock = AppUtils.formatNumber(netStockUnits);

    // 3. Out of stock count (All Time)
    final int outOfStockCount = (summary != null && summary!.outOfStockCount > 0)
        ? summary!.outOfStockCount
        : products.outOfStockCount;
    final String formattedOutOfStock = outOfStockCount.toString().padLeft(2, '0');

    // 4. Low stock count (All Time)
    final int lowStockCount = (summary != null && summary!.lowStockCount > 0)
        ? summary!.lowStockCount
        : products.lowStockCount;
    final String formattedLowStock = lowStockCount.toString().padLeft(2, '0');

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;

        // Dynamically choose column count based on available space:
        // >= 720px width: 4 columns
        // < 720px width: 2 columns
        final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
        final crossCount = constraints.maxWidth >= 720 ? 4 : 2;
        final itemWidth = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
        final baseHeight = crossCount == 4
            ? 136.0
            : (itemWidth * 0.94).clamp(132.0, 156.0);
        final itemHeight = baseHeight * textScale;
        final isCompact = itemWidth < 160;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            // 1. Featured Top-Left: Total Stock Value (Solid Lavender)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: true,
                isCompact: isCompact,
                title: 'Total Stock Value',
                value: formattedStockValue,
                icon: Icons.inventory_2_outlined,
                iconBg: Colors.white,
                iconColor: AppColors.text,
                onTap: () => context.go('/products'),
              ),
            ),

            // 2. Top-Right: Total Stock (Pure White + Mint Green icon)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: false,
                isCompact: isCompact,
                title: 'Total Stock',
                value: formattedTotalStock,
                icon: Icons.all_inbox_rounded,
                iconBg: AppColors.inStockBg,
                iconColor: AppColors.inStockText,
                onTap: () => context.go('/products'),
              ),
            ),

            // 3. Bottom-Left: Out of Stock (Pure White + Coral Pink icon)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: false,
                isCompact: isCompact,
                title: 'Out of Stock',
                value: formattedOutOfStock,
                icon: Icons.inventory_outlined,
                iconBg: AppColors.outOfStockBg,
                iconColor: AppColors.outOfStockText,
                onTap: () {
                  products.setStatusFilter(StockStatus.outOfStock);
                  context.go('/products');
                },
              ),
            ),

            // 4. Bottom-Right: Low Stock (Pure White + Amber Orange icon)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: false,
                isCompact: isCompact,
                title: 'Low Stock',
                value: formattedLowStock,
                icon: Icons.attach_money_rounded,
                iconBg: AppColors.lowStockBg,
                iconColor: AppColors.lowStockText,
                onTap: () {
                  products.setStatusFilter(StockStatus.lowStock);
                  context.go('/products');
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BentoMetricCard extends StatelessWidget {
  final bool isPrimary;
  final bool isCompact;
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _BentoMetricCard({
    required this.isPrimary,
    this.isCompact = false,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hPadding = isCompact ? 10.0 : 14.0;
    final vPadding = isCompact ? 10.0 : 12.0;
    final iconSize = isCompact ? 30.0 : 36.0;

    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
        border: Border.all(
          color: isPrimary ? Colors.transparent : AppColors.border,
          width: 1,
        ),
        boxShadow: isPrimary ? AppColors.lavenderShadow : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Circular pastel icon (left) & Subtle diagonal arrow (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        boxShadow: isPrimary
                            ? const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(icon, color: iconColor, size: isCompact ? 15 : 17),
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: isCompact ? 16 : 18,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.grey500,
                    ),
                  ],
                ),

                // Bottom Row: Bold metric & title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: isPrimary ? Colors.white : AppColors.text,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
