import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/models/product.dart';
import 'package:inventory_management/models/dashboard_summary.dart';
import 'package:inventory_management/data/api_service.dart';

/// Bento Metric Grid matching Image 1:
/// 2x2 grid of square cards (24px radius):
/// - Top-Left: Solid lavender card (#A594F9), white circle icon, 'Weekly ˅', '$45,210', 'Total Stock Value', '↗'
/// - Top-Right: Pure white card, mint green circle icon, 'Weekly ˅', '1,284', 'Total Stock', '↗'
/// - Bottom-Left: Pure white card, coral circle icon, 'Weekly ˅', '08', 'Out of Stock', '↗'
/// - Bottom-Right: Pure white card, amber circle icon, 'Weekly ˅', '23', 'Low Stock', '↗'
class DashboardSummaryGrid extends StatefulWidget {
  final ProductProvider products;
  final StockProvider stock;
  final DashboardSummary? summary;

  const DashboardSummaryGrid({
    super.key,
    required this.products,
    required this.stock,
    this.summary,
  });

  @override
  State<DashboardSummaryGrid> createState() => _DashboardSummaryGridState();
}

class _DashboardSummaryGridState extends State<DashboardSummaryGrid> {
  String _selectedPeriod = 'Weekly';
  final Map<String, DashboardSummary> _periodSummaries = {};

  @override
  void initState() {
    super.initState();
    _fetchPeriodSummary(_selectedPeriod);
  }

  Future<void> _fetchPeriodSummary(String period) async {
    final backendPeriod = period == 'Daily'
        ? 'TODAY'
        : (period == 'Monthly' ? 'THIS_MONTH' : 'THIS_WEEK');

    try {
      final json = await ApiService().getInventorySummaryReport(period: backendPeriod);
      if (json != null && mounted) {
        setState(() {
          _periodSummaries[period] = DashboardSummary.fromJson(json);
        });
      }
    } catch (_) {}
  }

  void _changePeriod(String period) {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    if (!_periodSummaries.containsKey(period)) {
      _fetchPeriodSummary(period);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSummary = _periodSummaries[_selectedPeriod] ?? widget.summary;

    // Total stock value from period report or fallback
    final double totalStockValue = activeSummary != null
        ? activeSummary.totalInventoryValue
        : widget.products.allProducts.fold<double>(
            0.0,
            (sum, p) => sum + (p.quantity * p.price),
          );
    final String formattedStockValue = AppUtils.formatCurrency(totalStockValue);

    final String formattedTotalStock = activeSummary != null
        ? AppUtils.formatNumber(activeSummary.totalStockQuantity)
        : AppUtils.formatNumber(widget.products.totalQuantity);
    final String formattedOutOfStock = activeSummary != null
        ? activeSummary.outOfStockCount.toString().padLeft(2, '0')
        : widget.products.outOfStockCount.toString().padLeft(2, '0');
    final String formattedLowStock = activeSummary != null
        ? activeSummary.lowStockCount.toString().padLeft(2, '0')
        : widget.products.lowStockCount.toString().padLeft(2, '0');

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
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
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
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
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
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
                onTap: () {
                  widget.products.setStatusFilter(StockStatus.outOfStock);
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
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
                onTap: () {
                  widget.products.setStatusFilter(StockStatus.lowStock);
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
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onTap;

  const _BentoMetricCard({
    required this.isPrimary,
    this.isCompact = false,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.period,
    required this.onPeriodChanged,
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
                // Top Row: Circular pastel icon (left) & Pill dropdown ('Weekly ˅') (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Circular icon
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
                    const SizedBox(width: 4),

                    // Pill dropdown ('Weekly ˅')
                    Flexible(
                      child: PopupMenuButton<String>(
                        initialValue: period,
                        onSelected: onPeriodChanged,
                        tooltip: 'Select range',
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Daily', child: Text('Daily')),
                          const PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                          const PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPrimary
                                ? Colors.white.withValues(alpha: 0.22)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            border: Border.all(
                              color: isPrimary
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  period,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isPrimary
                                        ? Colors.white
                                        : AppColors.secondaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 13,
                                color: isPrimary
                                    ? Colors.white
                                    : AppColors.secondaryText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Row: Bold metric (bottom-left) & Tiny diagonal arrow ('↗') (bottom-right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
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
                    ),

                    // Tiny diagonal arrow ('↗')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 4),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.text,
                      ),
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
