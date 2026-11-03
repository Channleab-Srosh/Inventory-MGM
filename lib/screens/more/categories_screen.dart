import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/category.dart';

/// Features 6 & 7: Category Management Screen
/// Operations: Add, View, Edit, Delete, Search
/// Business rule: If category is used by products, recommend soft deactivation.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchCtrl = TextEditingController();
  bool? _statusFilter; // true=Active, false=Inactive, null=All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cat = context.read<CategoryProvider>();
      if (cat.allCategories.isEmpty) cat.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user?.canViewCategories != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category Management')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Access Restricted', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Staff accounts do not have permission to view or manage categories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final catProv = context.watch<CategoryProvider>();
    final prodProv = context.watch<ProductProvider>();
    final canManageCategories = auth.user?.canManageCategories ?? false;
    final allCats = catProv.categories;

    final categories = allCats.where((c) {
      if (_statusFilter != null && c.isActive != _statusFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search categories...',
              onChanged: catProv.setSearch,
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
                _StatusFilterChip(
                  label: 'All (${catProv.allCategories.length})',
                  selected: _statusFilter == null,
                  onSelected: () => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'Active (${catProv.allCategories.where((c) => c.isActive).length})',
                  selected: _statusFilter == true,
                  color: AppColors.inStock,
                  onSelected: () => setState(() => _statusFilter = true),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'Inactive (${catProv.allCategories.where((c) => !c.isActive).length})',
                  selected: _statusFilter == false,
                  color: AppColors.danger,
                  onSelected: () => setState(() => _statusFilter = false),
                ),
              ],
            ),
          ),

          Expanded(
            child: catProv.isLoading && catProv.allCategories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : catProv.error != null && catProv.allCategories.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text(
                                catProv.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.danger, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => catProv.fetchCategories(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => catProv.fetchCategories(),
                        child: categories.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  EmptyState(
                                    message: 'No categories found',
                                    subtitle: catProv.search.isNotEmpty
                                        ? 'Try a different search term'
                                        : 'Tap the + button to create a category',
                                    icon: Icons.category_outlined,
                                  ),
                                ],
                              )
                            : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final count = prodProv.allProducts
                          .where((p) => p.categoryId == cat.id)
                          .length;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.category_outlined,
                                    color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            cat.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (cat.isActive ? AppColors.inStock : AppColors.danger)
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            cat.isActive ? 'ACTIVE' : 'INACTIVE',
                                            style: TextStyle(
                                              color: cat.isActive ? AppColors.inStock : AppColors.danger,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$count product${count == 1 ? "" : "s"} assigned',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (canManageCategories) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  tooltip: 'Edit',
                                  onPressed: () => _showAddEditSheet(context, cat),
                                ),
                                IconButton(
                                  icon: Icon(
                                    cat.isActive ? Icons.toggle_on : Icons.toggle_off,
                                    size: 26,
                                    color: cat.isActive ? AppColors.inStock : AppColors.grey500,
                                  ),
                                  tooltip: cat.isActive ? 'Deactivate' : 'Reactivate',
                                  onPressed: () {
                                    catProv.toggleCategoryStatus(cat.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '"${cat.name}" is now ${cat.isActive ? "inactive" : "active"}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: AppColors.danger),
                                  tooltip: 'Delete',
                                  onPressed: () => _handleDeleteCategory(context, cat, count),
                                ),
                              ],
                            ],
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
      floatingActionButton: canManageCategories
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditSheet(context, null),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            )
          : null,
    );
  }

  /// Business Rule Implementation (Notion Page 7):
  /// "If a category is being used by products, you should decide whether:
  /// • deletion is blocked, or
  /// • the category becomes inactive.
  /// For your project, I recommend soft deactivation."
  Future<void> _handleDeleteCategory(BuildContext context, Category cat, int productCount) async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canManageCategories != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts cannot delete categories.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final catProv = context.read<CategoryProvider>();

    if (productCount > 0) {
      // Products are using this category -> Recommend soft deactivation as per Notion
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Category In Use'),
          content: Text(
            'Category "${cat.name}" has $productCount product(s) linked to it.\n\n'
            'To maintain catalog integrity, soft deactivation is recommended instead of permanent deletion.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: const Text('Soft Deactivate'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.pop(ctx, 'deactivate'),
            ),
          ],
        ),
      );

      if (result == 'deactivate' && context.mounted) {
        catProv.deactivateCategory(cat.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${cat.name}" has been soft-deactivated.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } else {
      // No products using this category -> Allow clean deletion
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Delete Category',
        message: 'Are you sure you want to delete "${cat.name}"? This category has no products.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.danger,
      );

      if (confirmed && context.mounted) {
        final success = await catProv.deleteCategory(cat.id);
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category "${cat.name}" deleted.'),
                backgroundColor: AppColors.danger,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(catProv.error ?? 'Failed to delete category'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }
    }
  }

  void _showAddEditSheet(BuildContext context, Category? category) {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canManageCategories != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts cannot create or edit categories.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEditCategorySheet(category: category),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: c.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? c : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

class _AddEditCategorySheet extends StatefulWidget {
  final Category? category;
  const _AddEditCategorySheet({this.category});

  @override
  State<_AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<_AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _isActive = true;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<CategoryProvider>();
    final name = _nameCtrl.text.trim();

    if (_isEditing) {
      await prov.updateCategory(widget.category!.copyWith(
        name: name,
        isActive: _isActive,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully!')),
        );
      }
    } else {
      await prov.addCategory(Category(
        id: prov.generateId(),
        name: name,
        isActive: _isActive,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New category created successfully!')),
        );
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit Category' : 'New Category',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Drinks, Food, Electronics',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Category name is required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active Status'),
                subtitle: Text(_isActive
                    ? 'Products can be assigned to this category'
                    : 'Category is inactive'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                activeThumbColor: AppColors.inStock,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(_isEditing ? 'Save Changes' : 'Create Category'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}
