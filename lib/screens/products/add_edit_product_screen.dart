import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';

/// Full-screen Add/Edit Product form
class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _descCtrl;

  String? _selectedCategoryId;
  String? _selectedSupplierId;
  bool _saving = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    final product = _isEditing
        ? context.read<ProductProvider>().findById(widget.productId!)
        : null;

    _nameCtrl = TextEditingController(text: product?.name ?? '');
    _skuCtrl = TextEditingController(text: product?.sku ?? '');
    _priceCtrl = TextEditingController(
        text: product != null ? product.price.toStringAsFixed(2) : '');
    _qtyCtrl = TextEditingController(
        text: product != null ? product.quantity.toString() : '0');
    _minStockCtrl = TextEditingController(
        text: product != null ? product.minStockLevel.toString() : '10');
    _descCtrl = TextEditingController(text: product?.description ?? '');
    _selectedCategoryId = product?.categoryId;
    _selectedSupplierId = product?.supplierId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _minStockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    // Capture provider BEFORE await to avoid BuildContext across async gap
    final products = context.read<ProductProvider>();

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (_isEditing) {
      final existing = products.findById(widget.productId!);
      if (existing != null) {
        products.updateProduct(existing.copyWith(
          name: _nameCtrl.text.trim(),
          sku: _skuCtrl.text.trim(),
          price: double.parse(_priceCtrl.text),
          quantity: int.parse(_qtyCtrl.text),
          minStockLevel: int.parse(_minStockCtrl.text),
          categoryId: _selectedCategoryId,
          supplierId: _selectedSupplierId,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ));
      }
    } else {
      products.addProduct(Product(
        id: products.generateId(),
        name: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        quantity: int.parse(_qtyCtrl.text),
        minStockLevel: int.parse(_minStockCtrl.text),
        categoryId: _selectedCategoryId!,
        supplierId: _selectedSupplierId!,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Product updated!' : 'Product added!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final suppliers = context.watch<SupplierProvider>().allSuppliers;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker placeholder
            Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: AppColors.primary, size: 32),
                      const SizedBox(height: 4),
                      Text('Add Photo',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel(theme, 'Basic Information'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            // SKU with scan button
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(labelText: 'SKU *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'SKU is required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Barcode scanner coming soon')));
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
              validator: (v) => v == null ? 'Category is required' : null,
            ),
            const SizedBox(height: 12),

            // Supplier dropdown
            DropdownButtonFormField<String>(
              value: _selectedSupplierId,
              decoration: const InputDecoration(labelText: 'Supplier *'),
              items: suppliers
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSupplierId = v),
              validator: (v) => v == null ? 'Supplier is required' : null,
            ),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Pricing & Stock'),
            const SizedBox(height: 8),

            // Price
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price *',
                prefixText: '\$ ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Price is required';
                final n = double.tryParse(v);
                if (n == null || n < 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Initial Qty *'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Stock *'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Update Product' : 'Add Product'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Text(label,
        style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary));
  }
}
