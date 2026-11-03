import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/product_image.dart';
import '../../models/product.dart';

/// Product Management Screen (accessible from Tab 4 "More")
/// Operations: View, Add, Edit, Activate/Deactivate, Delete, Search, Filter
/// Structured matching CategoriesScreen and UsersScreen
class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  final _searchCtrl = TextEditingController();
  late final ScrollController _scrollCtrl;
  String _searchQuery = '';
  String? _statusFilter; // null=All, 'ACTIVE', 'INACTIVE', 'LOW_STOCK', 'OUT_OF_STOCK'
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductProvider>();
      if (p.allProducts.isEmpty) p.fetchProducts();
      final c = context.read<CategoryProvider>();
      if (c.allCategories.isEmpty) c.fetchCategories();
    });
  }

  void _onScroll() {
    if (_scrollCtrl.hasClients &&
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleToggleStatus(BuildContext context, Product product) async {
    final prodProv = context.read<ProductProvider>();
    final ok = await prodProv.toggleProductStatus(product.id);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${product.name}" is now ${product.status == "Active" ? "Inactive" : "Active"}',
          ),
        ),
      );
    }
  }

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

  Widget _buildStatusBadge(Product product) {
    final isActive = product.status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.inStock : AppColors.danger).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? AppColors.inStock : AppColors.danger,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStockChip(Product product) {
    Color bg;
    Color fg;
    String label;

    switch (product.stockStatus) {
      case StockStatus.outOfStock:
        bg = AppColors.outOfStockBg;
        fg = AppColors.outOfStockText;
        label = '0 in stock';
        break;
      case StockStatus.lowStock:
        bg = AppColors.lowStockBg;
        fg = AppColors.lowStockText;
        label = '${product.quantity} in stock';
        break;
      case StockStatus.inStock:
        bg = AppColors.inStockBg;
        fg = AppColors.inStockText;
        label = '${product.quantity} in stock';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prodProv = context.watch<ProductProvider>();
    final catProv = context.watch<CategoryProvider>();
    final canManageProducts = auth.user?.canManageProducts ?? true;
    final allProducts = prodProv.allProducts;

    // Filter products
    final filtered = allProducts.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchSku = p.sku.toLowerCase().contains(q);
        final matchCat = p.categoryName?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchSku && !matchCat) return false;
      }
      if (_selectedCategory != null) {
        final selectedCatId = _selectedCategory!;
        final selectedCat = catProv.findById(selectedCatId);
        final matchesId = p.categoryId == selectedCatId;
        final matchesName = selectedCat != null &&
            p.categoryName != null &&
            p.categoryName!.trim().toLowerCase() ==
                selectedCat.name.trim().toLowerCase();
        if (!matchesId && !matchesName) {
          return false;
        }
      }
      if (_statusFilter == 'ACTIVE' && p.status.toLowerCase() != 'active') {
        return false;
      }
      if (_statusFilter == 'INACTIVE' && p.status.toLowerCase() == 'active') {
        return false;
      }
      if (_statusFilter == 'LOW_STOCK' && p.stockStatus != StockStatus.lowStock) {
        return false;
      }
      if (_statusFilter == 'OUT_OF_STOCK' && p.stockStatus != StockStatus.outOfStock) {
        return false;
      }
      return true;
    }).toList();

    final activeCount = allProducts.where((p) => p.status.toLowerCase() == 'active').length;
    final inactiveCount = allProducts.length - activeCount;
    final lowStockCount = allProducts.where((p) => p.stockStatus == StockStatus.lowStock).length;
    final outOfStockCount = allProducts.where((p) => p.stockStatus == StockStatus.outOfStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          PopupMenuButton<String?>(
            tooltip: 'Filter by Category',
            icon: Badge(
              isLabelVisible: _selectedCategory != null,
              child: Icon(
                _selectedCategory != null
                    ? Icons.filter_alt_rounded
                    : Icons.filter_alt_outlined,
                color: _selectedCategory != null ? AppColors.primary : null,
              ),
            ),
            initialValue: _selectedCategory,
            onSelected: (catId) {
              setState(() {
                _selectedCategory = catId;
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('All Categories'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...catProv.allCategories.map(
                (cat) => PopupMenuItem<String?>(
                  value: cat.id,
                  child: Row(
                    children: [
                      Icon(
                        _selectedCategory == cat.id
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: _selectedCategory == cat.id
                            ? AppColors.primary
                            : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: _selectedCategory == cat.id
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search by name, SKU, category...',
              onChanged: (q) => setState(() => _searchQuery = q.trim()),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            children: [
              // Filter chips
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChipItem(
                      label: 'All (${allProducts.length})',
                      selected: _statusFilter == null && _selectedCategory == null,
                      onSelected: () => setState(() {
                        _statusFilter = null;
                        _selectedCategory = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipItem(
                      label: 'Active ($activeCount)',
                      selected: _statusFilter == 'ACTIVE',
                      color: AppColors.inStock,
                      onSelected: () => setState(() => _statusFilter = _statusFilter == 'ACTIVE' ? null : 'ACTIVE'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipItem(
                      label: 'Inactive ($inactiveCount)',
                      selected: _statusFilter == 'INACTIVE',
                      color: AppColors.danger,
                      onSelected: () => setState(() => _statusFilter = _statusFilter == 'INACTIVE' ? null : 'INACTIVE'),
                    ),
                    if (lowStockCount > 0) ...[
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'Low Stock ($lowStockCount)',
                        selected: _statusFilter == 'LOW_STOCK',
                        color: AppColors.lowStock,
                        onSelected: () => setState(() => _statusFilter = _statusFilter == 'LOW_STOCK' ? null : 'LOW_STOCK'),
                      ),
                    ],
                    if (outOfStockCount > 0) ...[
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: 'Out of Stock ($outOfStockCount)',
                        selected: _statusFilter == 'OUT_OF_STOCK',
                        color: AppColors.outOfStockText,
                        onSelected: () => setState(() => _statusFilter = _statusFilter == 'OUT_OF_STOCK' ? null : 'OUT_OF_STOCK'),
                      ),
                    ],
                    if (catProv.allCategories.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        height: 24,
                        width: 1,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      const SizedBox(width: 8),
                      ...catProv.allCategories.map((cat) {
                        final catProductCount = allProducts
                            .where((p) =>
                                p.categoryId == cat.id ||
                                (p.categoryName != null &&
                                    p.categoryName!.trim().toLowerCase() ==
                                        cat.name.trim().toLowerCase()))
                            .length;
                        final isSelected = _selectedCategory == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChipItem(
                            label: '${cat.name} ($catProductCount)',
                            selected: isSelected,
                            color: AppColors.primary,
                            onSelected: () => setState(() {
                              _selectedCategory = isSelected ? null : cat.id;
                            }),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: prodProv.isLoading && allProducts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : prodProv.error != null && allProducts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                                  const SizedBox(height: 12),
                                  Text(
                                    prodProv.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.danger, fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: () => prodProv.fetchProducts(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => prodProv.fetchProducts(),
                            child: filtered.isEmpty
                                ? ListView(
                                    children: [
                                      const SizedBox(height: 80),
                                      EmptyState(
                                        message: 'No products found',
                                        subtitle: _searchQuery.isNotEmpty || _selectedCategory != null || _statusFilter != null
                                            ? 'Try a different search term or clear filters'
                                            : 'Tap the + button to add a new product',
                                        icon: Icons.inventory_2_outlined,
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    controller: _scrollCtrl,
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                                    itemCount: filtered.length + (prodProv.isLoadingMore ? 1 : 0),
                                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                                    itemBuilder: (_, i) {
                                      if (i == filtered.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          child: Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        );
                                      }
                                      final product = filtered[i];
                                      final category = catProv.findById(product.categoryId);

                                      return Card(
                                        child: InkWell(
                                          onTap: () => context.push('/products/${product.id}'),
                                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Thumbnail
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    width: 48,
                                                    height: 48,
                                                    color: AppColors.primaryActive,
                                                    child: ProductImage(
                                                      path: product.imageUrl,
                                                      fit: BoxFit.cover,
                                                      fallback: const Center(
                                                        child: Icon(Icons.inventory_2_outlined,
                                                            size: 22, color: AppColors.primaryDark),
                                                      ),
                                                    ),
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
                                                              style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight: FontWeight.w700,
                                                                color: AppColors.text,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          _buildStatusBadge(product),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'SKU: ${product.sku}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppColors.secondaryText,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          if (category != null || product.categoryName != null) ...[
                                                            const SizedBox(width: 6),
                                                            const Text('·', style: TextStyle(color: AppColors.secondaryText)),
                                                            const SizedBox(width: 6),
                                                            Flexible(
                                                              child: Text(
                                                                category?.name ?? product.categoryName ?? '',
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: AppColors.secondaryText,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            AppUtils.formatCurrency(product.price),
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w700,
                                                              color: AppColors.primaryDark,
                                                            ),
                                                          ),
                                                          _buildStockChip(product),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Actions
                                                if (canManageProducts) ...[
                                                  const SizedBox(width: 4),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                                        tooltip: 'Edit',
                                                        constraints: const BoxConstraints(),
                                                        padding: const EdgeInsets.all(6),
                                                        onPressed: () => context.push('/products/edit/${product.id}'),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          product.status.toLowerCase() == 'active'
                                                              ? Icons.toggle_on
                                                              : Icons.toggle_off,
                                                          size: 26,
                                                          color: product.status.toLowerCase() == 'active'
                                                              ? AppColors.inStock
                                                              : AppColors.secondaryText,
                                                        ),
                                                        tooltip: product.status.toLowerCase() == 'active'
                                                            ? 'Deactivate'
                                                            : 'Activate',
                                                        constraints: const BoxConstraints(),
                                                        padding: const EdgeInsets.all(6),
                                                        onPressed: () => _handleToggleStatus(context, product),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline_rounded,
                                                            size: 20, color: AppColors.danger),
                                                        tooltip: 'Delete',
                                                        constraints: const BoxConstraints(),
                                                        padding: const EdgeInsets.all(6),
                                                        onPressed: () => _handleDeleteProduct(context, product),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canManageProducts
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/products/add'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  const _FilterChipItem({
    required this.label,
    required this.selected,
    this.color = AppColors.primary,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
