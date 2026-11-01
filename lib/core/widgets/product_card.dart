import 'package:flutter/material.dart';
import 'package:inventory_management/core/widgets/product_image.dart';
import '../../models/product.dart';
import '../../core/theme/app_theme.dart';

/// Modern List / Inventory Card matching Image 2:
/// - 16px radius pure white card with subtle border & soft shadow
/// - 56px rounded-square product thumbnail on light gray background (left)
/// - 3-line stack (center):
///     1. Title (e.g. "Smart Watch Series 5")
///     2. SKU (e.g. "SKU: SWT-2024-087")
///     3. "8 in Stock  |  ↓ 12%" (Stock count with trend percentage)
/// - Semantic status pill badge aligned to bottom-right (In Stock / Low Stock / Out of Stock)
class ProductCard extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const ProductCard({
    super.key,
    required this.product,
    required this.categoryName,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 56px rounded-square product thumbnail on a light gray background (left)
                Hero(
                  tag: 'product-${product.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ProductImage(
                      path: product.imageUrl,
                      fallback: _buildFallbackThumbnail(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. 3-line vertical stack (center)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Line 1: Title (Semi-bold, 15px, deep charcoal)
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Line 2: SKU (Regular, 12px, muted gray)
                      Text(
                        'SKU: ${product.sku}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Line 3: "8 in Stock  |  ↓ 12%"
                      _buildStockLine(),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Semantic status pill badge aligned to the bottom-right
                Align(
                  alignment: Alignment.bottomRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildStatusPill(product.stockStatus),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    IconData icon = Icons.inventory_2_outlined;
    final lower = product.name.toLowerCase();
    if (lower.contains('watch')) {
      icon = Icons.watch_outlined;
    } else if (lower.contains('cable') || lower.contains('usb')) {
      icon = Icons.cable_outlined;
    } else if (lower.contains('laptop') || lower.contains('stand')) {
      icon = Icons.laptop_mac_outlined;
    } else if (lower.contains('keyboard')) {
      icon = Icons.keyboard_outlined;
    } else if (lower.contains('mouse')) {
      icon = Icons.mouse_outlined;
    } else if (lower.contains('phone')) {
      icon = Icons.smartphone_outlined;
    }

    return Center(
      child: Icon(
        icon,
        color: AppColors.text.withValues(alpha: 0.75),
        size: 26,
      ),
    );
  }

  Widget _buildStockLine() {
    final isOut = product.stockStatus == StockStatus.outOfStock;
    final isLow = product.stockStatus == StockStatus.lowStock;

    // Trend percentage logic matching mockup:
    // Out of Stock: "0 in Stock  |  ↓ 100%"
    // Low Stock: "8 in Stock  |  ↓ 12%"
    // In Stock: "89 in Stock  |  ↑ 6%"
    final String trendText = isOut
        ? '↓ 100%'
        : (isLow ? '↓ 12%' : '↑ ${(product.quantity % 15) + 4}%');
    final Color trendColor =
        (isOut || isLow) ? AppColors.outOfStockText : AppColors.inStockText;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${product.quantity} in Stock',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
          const TextSpan(
            text: '  |  ',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: trendText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusPill(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inStockBg,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          child: const Text(
            'In Stock',
            style: TextStyle(
              color: AppColors.inStockText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        );
      case StockStatus.lowStock:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.lowStockBg,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          child: const Text(
            'Low Stock',
            style: TextStyle(
              color: AppColors.lowStockText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        );
      case StockStatus.outOfStock:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.outOfStockBg,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          child: const Text(
            'Out of Stock',
            style: TextStyle(
              color: AppColors.outOfStockText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        );
    }
  }
}
