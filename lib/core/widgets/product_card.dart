import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import 'common_widgets.dart';

/// Product list card with image placeholder, info, and status chip
class ProductCard extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.categoryName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image / placeholder
              Hero(
                tag: 'product-${product.id}',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(product.imageUrl!,
                              fit: BoxFit.cover),
                        )
                      : Icon(Icons.inventory_2_outlined,
                          color: AppColors.primary, size: 28),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _statusChip(product.stockStatus),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${product.sku}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoBadge(label: categoryName, icon: Icons.label_outline),
                        const SizedBox(width: 8),
                        _InfoBadge(
                          label: 'Qty: ${AppUtils.formatNumber(product.quantity)}',
                          icon: Icons.inventory_outlined,
                        ),
                        const Spacer(),
                        Text(
                          AppUtils.formatCurrency(product.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return StatusChip.inStock();
      case StockStatus.lowStock:
        return StatusChip.lowStock();
      case StockStatus.outOfStock:
        return StatusChip.outOfStock();
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.grey500),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
      ],
    );
  }
}
