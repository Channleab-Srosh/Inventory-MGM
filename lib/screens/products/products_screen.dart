import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/app_components.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import 'widgets/product_filter_sheet.dart';

/// Products / Inventory screen matching Image 2:
/// - Top Header: "Inventory" title on left, pill "Add Product" on right
/// - Search & Filter Bar: Circular search button next to horizontal scrolling pill filter chips
///   ("Total Stock" [active lavender], "Out of Stock", "Low Stock", Categories...)
/// - List of Inventory Cards with 56px thumbnail, 3-line info with "X in Stock | ↑ 6%", and semantic status pill badge
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  late final ScrollController _scrollCtrl;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductProvider>();
      if (p.allProducts.isEmpty) p.fetchProducts();
      final c = context.read<CategoryProvider>();
      if (c.allCategories.isEmpty) c.fetchCategories();
      final s = context.read<SupplierProvider>();
      if (s.allSuppliers.isEmpty) s.fetchSuppliers();
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

  void _openFilterBottomSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final canViewCategories = auth.user?.canViewCategories ?? true;
    final products = context.read<ProductProvider>();
    final categories = canViewCategories
        ? context.read<CategoryProvider>().categories
        : <Category>[];
    final suppliers = context.read<SupplierProvider>().allSuppliers;

    ProductFilterSheet.show(
      context: context,
      initialCategoryId: products.selectedCategoryId,
      initialSupplierId: products.selectedSupplierId,
      initialStatus: products.statusFilter,
      categories: categories,
      suppliers: suppliers,
      onApply: (categoryId, supplierId, status) {
        products.setCategoryFilter(categoryId);
        products.setSupplierFilter(supplierId);
        products.setStatusFilter(status);
      },
    );
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Product',
      message: 'Delete "${product.name}"? This action cannot be undone.',
    );
    if (confirmed && context.mounted) {
      context.read<ProductProvider>().deleteProduct(product.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManageProducts = auth.user?.canManageProducts ?? true;
    final canViewCategories = auth.user?.canViewCategories ?? true;
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>();
    final filtered = products.filteredProducts;

    final bool isAllSelected = products.selectedCategoryId == null &&
        products.statusFilter == null &&
        products.selectedSupplierId == null;

    final isWide = AppResponsive.isTabletOrDesktop(context);
    final hPad = AppResponsive.screenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header matching Image 2: "Inventory" + Pill "Add Product"
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventory',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        filtered.length == products.allProducts.length
                            ? '${products.allProducts.length} Products'
                            : '${filtered.length} of ${products.allProducts.length} Products',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (canManageProducts)
                    GestureDetector(
                      onTap: () => context.push('/products/add'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius:
                              BorderRadius.circular(AppTheme.pillRadius),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x041A1A1A),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Add Product',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search & Filter Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  // Circular search icon button
                  GestureDetector(
                    onTap: () => setState(() => _showSearch = !_showSearch),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _showSearch
                            ? AppColors.primaryActive
                            : AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _showSearch
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x041A1A1A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _showSearch
                              ? AppColors.primaryDark
                              : AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Horizontal scrolling pill filter chips
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _FilterPill(
                            label: 'Total Stock',
                            selected: isAllSelected,
                            onTap: () => products.clearFilters(),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Out of Stock',
                            selected: products.statusFilter ==
                                StockStatus.outOfStock,
                            onTap: () => products
                                .setStatusFilter(StockStatus.outOfStock),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Low Stock',
                            selected:
                                products.statusFilter == StockStatus.lowStock,
                            onTap: () => products
                                .setStatusFilter(StockStatus.lowStock),
                          ),
                          const SizedBox(width: 8),
                          if (canViewCategories)
                            ...categories.categories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterPill(
                                  label: cat.name,
                                  selected:
                                      products.selectedCategoryId == cat.id,
                                  onTap: () =>
                                      products.setCategoryFilter(
                                          products.selectedCategoryId == cat.id
                                              ? null
                                              : cat.id),
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _openFilterBottomSheet(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanding search field
            if (_showSearch) ...[
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: SearchField(
                  controller: _searchCtrl,
                  hint: 'Search products, SKU...',
                  onChanged: products.setSearch,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Product list / grid
            Expanded(
              child: products.isLoading && products.allProducts.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                        strokeWidth: 3,
                      ),
                    )
                  : products.error != null && products.allProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: AppColors.outOfStockText,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  products.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  label: 'Retry',
                                  width: 120,
                                  onPressed: () => products.fetchProducts(),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await Future.wait([
                              products.fetchProducts(),
                              categories.fetchCategories(),
                            ]);
                          },
                          color: AppColors.primaryDark,
                          child: filtered.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 80),
                                    EmptyState(
                                      message: 'No products found',
                                      subtitle: products.searchQuery.isNotEmpty
                                          ? 'Try a different search term'
                                          : 'Add a product using the button above',
                                      icon: Icons.inventory_2_outlined,
                                    ),
                                  ],
                                )
                              : isWide
                                  // ── Tablet/Desktop: 2-column grid ──────────
                                  ? _buildProductGrid(
                                      context,
                                      filtered,
                                      categories,
                                      canViewCategories,
                                      canManageProducts,
                                      hPad,
                                    )
                                  // ── Mobile: list ───────────────────────────
                                  : ListView.builder(
                                      controller: _scrollCtrl,
                                      padding: EdgeInsets.fromLTRB(
                                          hPad, 4, hPad, 100),
                                      itemCount: filtered.length +
                                          (products.isLoadingMore ? 1 : 0),
                                      itemBuilder: (_, i) {
                                        if (i == filtered.length) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              ),
                                            ),
                                          );
                                        }
                                        final product = filtered[i];
                                        final cat = canViewCategories
                                            ? categories
                                                .findById(product.categoryId)
                                            : null;
                                        return Slidable(
                                          key: ValueKey(product.id),
                                          endActionPane: canManageProducts
                                              ? ActionPane(
                                                  motion: const DrawerMotion(),
                                                  children: [
                                                    SlidableAction(
                                                      onPressed: (_) =>
                                                          context.push(
                                                              '/products/edit/${product.id}'),
                                                      backgroundColor:
                                                          AppColors.primaryDark,
                                                      foregroundColor:
                                                          Colors.white,
                                                      icon:
                                                          Icons.edit_outlined,
                                                      label: 'Edit',
                                                      borderRadius:
                                                          const BorderRadius
                                                              .horizontal(
                                                              left:
                                                                  Radius.circular(
                                                                      12)),
                                                    ),
                                                    SlidableAction(
                                                      onPressed: (_) async {
                                                        final ok = await products.toggleProductStatus(product.id);
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
                                                      backgroundColor: product.status == 'Active'
                                                          ? const Color(0xFFD97706)
                                                          : AppColors.inStock,
                                                      foregroundColor: Colors.white,
                                                      icon: product.status == 'Active'
                                                          ? Icons.block_outlined
                                                          : Icons.check_circle_outline,
                                                      label: product.status == 'Active'
                                                          ? 'Deactivate'
                                                          : 'Activate',
                                                    ),
                                                    SlidableAction(
                                                      onPressed: (_) =>
                                                          _deleteProduct(
                                                              context, product),
                                                      backgroundColor:
                                                          AppColors
                                                              .outOfStockText,
                                                      foregroundColor:
                                                          Colors.white,
                                                      icon:
                                                          Icons.delete_outlined,
                                                      label: 'Delete',
                                                      borderRadius:
                                                          const BorderRadius
                                                              .horizontal(
                                                              right: Radius
                                                                  .circular(
                                                                      12)),
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          child: ProductCard(
                                            product: product,
                                            categoryName: canViewCategories
                                                ? (cat?.name ??
                                                    product.categoryName ??
                                                    '')
                                                : '',
                                            onTap: () => context
                                                .push('/products/${product.id}'),
                                          ),
                                        );
                                      },
                                    ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Responsive grid layout for tablet/desktop with fixed main axis height.
  Widget _buildProductGrid(
    BuildContext context,
    List<Product> filtered,
    CategoryProvider categories,
    bool canViewCategories,
    bool canManageProducts,
    double hPad,
  ) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4);
    final cardHeight = (112.0 * textScale).clamp(112.0, 148.0);

    final isLoadingMore = context.watch<ProductProvider>().isLoadingMore;

    return GridView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 100),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 460,
        mainAxisExtent: cardHeight,
        mainAxisSpacing: 10,
        crossAxisSpacing: 12,
      ),
      itemCount: filtered.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == filtered.length) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final product = filtered[i];
        final cat = canViewCategories
            ? categories.findById(product.categoryId)
            : null;
        return Slidable(
          key: ValueKey(product.id),
          endActionPane: canManageProducts
              ? ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          context.push('/products/edit/${product.id}'),
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                    ),
                    SlidableAction(
                      onPressed: (_) async {
                        final ok = await context
                            .read<ProductProvider>()
                            .toggleProductStatus(product.id);
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
                      backgroundColor: product.status == 'Active'
                          ? const Color(0xFFD97706)
                          : AppColors.inStock,
                      foregroundColor: Colors.white,
                      icon: product.status == 'Active'
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      label: product.status == 'Active' ? 'Deactivate' : 'Activate',
                    ),
                    SlidableAction(
                      onPressed: (_) => _deleteProduct(context, product),
                      backgroundColor: AppColors.outOfStockText,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outlined,
                      label: 'Delete',
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12)),
                    ),
                  ],
                )
              : null,
          child: ProductCard(
            product: product,
            margin: EdgeInsets.zero,
            categoryName: canViewCategories
                ? (cat?.name ?? product.categoryName ?? '')
                : '',
            onTap: () => context.push('/products/${product.id}'),
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryActive : AppColors.card,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x041A1A1A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryDark : AppColors.text,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}