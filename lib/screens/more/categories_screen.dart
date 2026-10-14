import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/category.dart';

/// Categories management screen
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CategoryProvider>();
    final prodProv = context.watch<ProductProvider>();
    final categories = catProv.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.isEmpty
          ? EmptyState(
              message: 'No categories yet',
              icon: Icons.category_outlined,
              action: ElevatedButton.icon(
                onPressed: () => _showAddEditSheet(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final count = prodProv.allProducts
                    .where((p) => p.categoryId == cat.id)
                    .length;
                return Dismissible(
                  key: ValueKey(cat.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => ConfirmDialog.show(
                    context,
                    title: 'Delete Category',
                    message:
                        'Delete "${cat.name}"? Products in this category will not be deleted.',
                  ),
                  onDismissed: (_) => catProv.deleteCategory(cat.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.outOfStock,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outlined, color: Colors.white),
                  ),
                  child: Card(
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.category_outlined,
                            color: AppColors.primary, size: 22),
                      ),
                      title: Text(cat.name),
                      subtitle: Text('$count products'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showAddEditSheet(context, cat),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditSheet(BuildContext context, Category? category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddEditCategorySheet(category: category),
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
  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<CategoryProvider>();
    if (_isEditing) {
      prov.updateCategory(widget.category!.copyWith(name: _nameCtrl.text.trim()));
    } else {
      prov.addCategory(Category(
        id: prov.generateId(),
        name: _nameCtrl.text.trim(),
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(_isEditing ? 'Edit Category' : 'Add Category',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Category Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Update' : 'Add Category'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
