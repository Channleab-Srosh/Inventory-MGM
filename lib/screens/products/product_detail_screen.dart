import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';

/// Product detail page: image, info, stock history
class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final product = products.findById(productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: const EmptyState(
          message: 'Product not found',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    final categories = context.watch<CategoryProvider>();
    final suppliers = context.watch<SupplierProvider>();
    final stock = context.watch<StockProvider>();
    final category = categories.findById(product.categoryId);
    final supplier = suppliers.findById(product.supplierId);
    final movements = stock.movementsForProduct(productId);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-$productId',
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 80, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/products/edit/$productId'),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Name + status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(product.name,
                          style: theme.textTheme.headlineMedium),
                    ),
                    _statusChip(product.stockStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text('SKU: ${product.sku}',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),

                // Info grid
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow('Category', category?.name ?? '-'),
                        const Divider(height: 20),
                        _InfoRow('Supplier', supplier?.name ?? '-'),
                        const Divider(height: 20),
                        _InfoRow('Price',
                            AppUtils.formatCurrency(product.price)),
                        const Divider(height: 20),
                        _InfoRow('Current Qty',
                            AppUtils.formatNumber(product.quantity)),
                        const Divider(height: 20),
                        _InfoRow('Min Stock', '${product.minStockLevel}'),
                        const Divider(height: 20),
                        _InfoRow('Stock Value',
                            AppUtils.formatCurrency(
                                product.price * product.quantity)),
                        const Divider(height: 20),
                        _InfoRow('Added',
                            AppUtils.formatDate(product.createdAt)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                if (product.description != null) ...[
                  const SectionHeader(title: 'Description'),
                  const SizedBox(height: 8),
                  Text(product.description!,
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                ],

                // Stock history
                SectionHeader(title: 'Stock History'),
                const SizedBox(height: 8),
                if (movements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text('No movements yet',
                            style: TextStyle(color: AppColors.grey500))),
                  )
                else
                  ...movements.map((m) => _MovementTile(movement: m)),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovement movement;
  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.chartIn : AppColors.chartOut;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
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
      title: Text(
        isIn ? 'Stock In' : 'Stock Out',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(AppUtils.formatDateTime(movement.date),
          style: theme.textTheme.bodyMedium),
      trailing: Text(
        '${isIn ? '+' : '-'}${movement.quantity}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
