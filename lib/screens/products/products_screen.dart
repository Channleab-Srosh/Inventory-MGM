import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../../models/product.dart';

/// Products list with search, filter chips, slidable actions
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>();
    final filtered = products.filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filter Products',
            onPressed: () => _openFilterBottomSheet(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search products, SKU...',
              onChanged: products.setSearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ---- Filter chips ----
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: products.selectedCategoryId == null &&
                      products.statusFilter == null,
                  onSelected: (_) => products.clearFilters(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Low Stock',
                  selected: products.statusFilter == StockStatus.lowStock,
                  onSelected: (_) => products.setStatusFilter(StockStatus.lowStock),
                  color: AppColors.lowStock,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Out of Stock',
                  selected: products.statusFilter == StockStatus.outOfStock,
                  onSelected: (_) =>
                      products.setStatusFilter(StockStatus.outOfStock),
                  color: AppColors.outOfStock,
                ),
                const SizedBox(width: 8),
                ...categories.categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: cat.name,
                        selected: products.selectedCategoryId == cat.id,
                        onSelected: (_) => products.setCategoryFilter(cat.id),
                      ),
                    )),
              ],
            ),
          ),

          // ---- List ----
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    message: 'No products found',
                    subtitle: products.searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Add a product using the + button',
                    icon: Icons.inventory_2_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (_, i) {
                      final product = filtered[i];
                      final cat = categories.findById(product.categoryId);
                      return Slidable(
                        key: ValueKey(product.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) =>
                                  context.push('/products/edit/${product.id}'),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(12)),
                            ),
                            SlidableAction(
                              onPressed: (_) => _deleteProduct(context, product),
                              backgroundColor: AppColors.outOfStock,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outlined,
                              label: 'Delete',
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(12)),
                            ),
                          ],
                        ),
                        child: ProductCard(
                          product: product,
                          categoryName: cat?.name ?? 'Unknown',
                          onTap: () => context.push('/products/${product.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openFilterBottomSheet(BuildContext context) {
    final products = context.read<ProductProvider>();
    final categories = context.read<CategoryProvider>().categories;

    String? tempCatId = products.selectedCategoryId;
    StockStatus? tempStatus = products.statusFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        tempCatId = null;
                        tempStatus = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Category',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Categories'),
                    selected: tempCatId == null,
                    onSelected: (val) {
                      if (val) setSheetState(() => tempCatId = null);
                    },
                  ),
                  ...categories.map(
                    (c) => ChoiceChip(
                      label: Text(c.name),
                      selected: tempCatId == c.id,
                      onSelected: (val) {
                        setSheetState(() => tempCatId = val ? c.id : null);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Stock Status',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Status'),
                    selected: tempStatus == null,
                    onSelected: (val) {
                      if (val) setSheetState(() => tempStatus = null);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('In Stock'),
                    selected: tempStatus == StockStatus.inStock,
                    onSelected: (val) {
                      setSheetState(() =>
                          tempStatus = val ? StockStatus.inStock : null);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Low Stock'),
                    selected: tempStatus == StockStatus.lowStock,
                    onSelected: (val) {
                      setSheetState(() =>
                          tempStatus = val ? StockStatus.lowStock : null);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Out of Stock'),
                    selected: tempStatus == StockStatus.outOfStock,
                    onSelected: (val) {
                      setSheetState(() =>
                          tempStatus = val ? StockStatus.outOfStock : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    products.setCategoryFilter(tempCatId);
                    products.setStatusFilter(tempStatus);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: c.withValues(alpha: 0.15),
      checkmarkColor: c,
      labelStyle: TextStyle(
        color: selected ? c : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
