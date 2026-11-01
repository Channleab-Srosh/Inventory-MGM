import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';

/// Low stock items carousel section for the Dashboard with 16px cards & pill badges
class LowStockHorizontalList extends StatelessWidget {
  final ProductProvider products;

  const LowStockHorizontalList({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final lowStockItems = products.lowStockProducts;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4);
    final carouselHeight = (116.0 * textScale).clamp(116.0, 144.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Low Stock Alerts',
          trailing: TextButton(
            onPressed: () {
              products.setStatusFilter(StockStatus.lowStock);
              context.go('/products');
            },
            child: const Text('View All →'),
          ),
        ),
        const SizedBox(height: 8),
        if (products.isLoadingLowStock && lowStockItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (lowStockItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.inStockText,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All products have healthy stock levels',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: carouselHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: lowStockItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = lowStockItems[i];
                final isOut = p.stockStatus == StockStatus.outOfStock;
                final fgColor = isOut ? AppColors.outOfStockText : AppColors.lowStockText;
                final bgColor = isOut ? AppColors.outOfStockBg : AppColors.lowStockBg;
                final statusLabel = isOut ? 'OUT OF STOCK' : 'LOW STOCK';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/products/${p.id}'),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Stock: ${p.quantity} ${p.unit} · Min: ${p.minStockLevel}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: fgColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
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
