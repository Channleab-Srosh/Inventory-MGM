import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../core/widgets/product_image.dart';

/// Product detail page: image, info, stock history
class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  Future<void> _handleDeleteProduct(BuildContext context, Product product) async {
    final prodProv = context.read<ProductProvider>();

    if (product.quantity > 0) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Product Has Stock'),
          content: Text(
            'Product "${product.name}" currently has ${product.quantity} ${product.unit} in stock.\n\n'
            'To maintain inventory integrity, products with stock cannot be deleted. Would you like to deactivate this product instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: const Text('Deactivate Instead'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.pop(ctx, 'deactivate'),
            ),
          ],
        ),
      );

      if (action == 'deactivate' && context.mounted) {
        final ok = await prodProv.toggleProductStatus(product.id);
        if (context.mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${product.name}" has been deactivated.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Product',
      message: 'Are you sure you want to delete "${product.name}" (${product.sku})? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.danger,
    );

    if (confirmed && context.mounted) {
      final ok = await prodProv.deleteProduct(product.id);
      if (context.mounted) {
        if (ok) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${product.name}" deleted successfully'),
              backgroundColor: AppColors.inStock,
            ),
          );
        } else {
          final errorMsg = prodProv.error ?? 'Failed to delete product';
          final isLinked = errorMsg.toLowerCase().contains('transaction') ||
              errorMsg.toLowerCase().contains('associated') ||
              errorMsg.toLowerCase().contains('history');

          if (isLinked) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Cannot Delete Product'),
                content: Text(
                  'Product "${product.name}" has recorded stock transactions in history.\n\n'
                  'To protect historical audit trails, you can deactivate it instead so it no longer appears for new stock operations.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: const Text('Deactivate Instead'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await prodProv.toggleProductStatus(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${product.name}" has been deactivated.'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: AppColors.danger),
            );
          }
        }
      }
    }
  }

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

    final auth = context.watch<AuthProvider>();
    final canManageProducts = auth.user?.canManageProducts ?? true;
    final canViewCategories = auth.user?.canViewCategories ?? true;
    final categories = context.watch<CategoryProvider>();
    final suppliers = context.watch<SupplierProvider>();
    final stock = context.watch<StockProvider>();
    final category = categories.findById(product.categoryId);
    final supplier = suppliers.findById(product.supplierId);
    final movements = stock.movementsForProduct(productId);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              // Hero image app bar
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product-$productId',
                    child: Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      width: double.infinity,
                      child: ProductImage(
                        path: product.imageUrl,
                        fit: BoxFit.cover,
                        fallback: const Center(
                          child: Icon(Icons.inventory_2_outlined,
                              size: 80, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (canManageProducts) ...[
                    IconButton(
                      tooltip: product.status == 'Active'
                          ? 'Deactivate Product'
                          : 'Activate Product',
                      icon: Icon(
                        product.status == 'Active'
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        size: 28,
                        color: product.status == 'Active'
                            ? AppColors.inStock
                            : AppColors.grey500,
                      ),
                      onPressed: () async {
                        final ok =
                            await products.toggleProductStatus(productId);
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.name} is now ${product.status == "Active" ? "Inactive" : "Active"}',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: const CircleBorder(),
                          fixedSize: const Size(40, 40), // smaller circle
                        ),
                        onPressed: () =>
                            context.push('/products/edit/$productId'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: const Size(40, 40),
                        ),
                        tooltip: 'Delete Product',
                        onPressed: () => _handleDeleteProduct(context, product),
                      ),
                    ),
                  ],
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
                            _InfoRow('Product ID', product.id),
                            const Divider(height: 20),
                            if (canViewCategories) ...[
                              _InfoRow(
                                  'Category',
                                  category?.name ??
                                      product.categoryName ??
                                      '-'),
                              const Divider(height: 20),
                            ],
                            _InfoRow('Supplier',
                                supplier?.name ?? product.supplierName ?? '-'),
                            const Divider(height: 20),
                            _InfoRow('Price',
                                AppUtils.formatCurrency(product.price)),
                            const Divider(height: 20),
                            _InfoRow('Unit of Measure', product.unit),
                            const Divider(height: 20),
                            _InfoRow('Current Qty',
                                '${AppUtils.formatNumber(product.quantity)} ${product.unit}'),
                            const Divider(height: 20),
                            _InfoRow('Min Stock',
                                '${product.minStockLevel} ${product.unit}'),
                            const Divider(height: 20),
                            _InfoRow(
                                'Stock Value',
                                AppUtils.formatCurrency(
                                    product.price * product.quantity)),
                            const Divider(height: 20),
                            _InfoRow('Status', product.status),
                            const Divider(height: 20),
                            _InfoRow('Created Date',
                                AppUtils.formatDate(product.createdAt)),
                            const Divider(height: 20),
                            _InfoRow('Updated Date',
                                AppUtils.formatDate(product.updatedAt)),
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
                    const SectionHeader(title: 'Stock History'),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
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
        child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: color, size: 18),
      ),
      title: Text(
        isIn ? 'Stock In' : 'Stock Out',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        movement.stockBefore != null && movement.stockAfter != null
            ? '${AppUtils.formatDateTime(movement.date)} · Stock: ${movement.stockBefore} → ${movement.stockAfter} ${movement.unit ?? "pcs"}'
            : AppUtils.formatDateTime(movement.date),
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Text(
        '${isIn ? '+' : '-'}${movement.quantity} ${movement.unit ?? "pcs"}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
