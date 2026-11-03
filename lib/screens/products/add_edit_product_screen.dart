import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../data/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/product_image.dart';

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
  String _status = 'Active';
  late String _unit;
  final List<String> _units = List.from(Product.commonUnits);
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

    final initialUnit = product?.unit.toLowerCase() ?? 'pcs';
    if (!_units.contains(initialUnit)) {
      _units.add(initialUnit);
    }
    _unit = initialUnit;
    _loadBackendUnits();

    _selectedCategoryId = product?.categoryId;
    _selectedSupplierId = product?.supplierId;
    _status = product?.status ?? 'Active';
    _existingImage = product?.imageUrl;
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

  File? _pickedImage;
  String? _existingImage; // server image URL (set in initState)

  Future<void> _pickImage(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (x != null) setState(() => _pickedImage = File(x.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          if (_pickedImage != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Remove selected photo', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _pickedImage = null);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canManageProducts != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts have view-only access to products.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    // Capture provider BEFORE await to avoid BuildContext across async gap
    final products = context.read<ProductProvider>();

    setState(() => _saving = true);

    final effectiveUnit = _unit;
    String? productId = widget.productId;

    bool success = false;
    if (_isEditing) {
      final existing = products.findById(widget.productId!);
      if (existing != null) {
        success = await products.updateProduct(existing.copyWith(
          name: _nameCtrl.text.trim(),
          sku: _skuCtrl.text.trim(),
          price: double.parse(_priceCtrl.text),
          quantity: int.parse(_qtyCtrl.text),
          minStockLevel: int.parse(_minStockCtrl.text),
          unit: effectiveUnit,
          categoryId: _selectedCategoryId,
          supplierId: _selectedSupplierId,
          status: _status,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ));
      }
    } else {
      final created = await products.addProduct(Product(
        id: products.generateId(),
        name: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        quantity: int.parse(_qtyCtrl.text),
        minStockLevel: int.parse(_minStockCtrl.text),
        unit: effectiveUnit,
        categoryId: _selectedCategoryId!,
        supplierId: _selectedSupplierId!,
        status: _status,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ));
      success = created != null;
      productId = created?.id;
    }

    // The create API has no image, so the photo is only handled when editing:
    // product is saved first (PUT), then the image is uploaded (POST /products/{id}/image).
    bool imageFailed = false;
    if (success && productId != null && _pickedImage != null) {
      imageFailed = !await products.uploadImage(productId, _pickedImage!);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(imageFailed
              ? 'Product saved, but the image failed: ${products.error ?? 'upload error'}'
              : (_isEditing ? 'Product updated!' : 'Product added!')),
          backgroundColor: imageFailed ? AppColors.danger : null,
        ));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(products.error ?? 'Failed to save product'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user?.canManageProducts != true) {
      return Scaffold(
        appBar:
            AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Access Restricted',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Staff accounts have view-only access to products. Adding and editing products is restricted to administrators and warehouse managers.',
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

    final categories = context
        .watch<CategoryProvider>()
        .allCategories
        .where((c) => c.isActive || c.id == _selectedCategoryId)
        .toList();
    final suppliers = context
        .watch<SupplierProvider>()
        .allSuppliers
        .where((s) => s.isActive || s.id == _selectedSupplierId)
        .toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Product Photo (Works for both Add and Edit)
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          width: 110,
                          height: 110,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: _pickedImage != null
                              ? Image.file(_pickedImage!, fit: BoxFit.cover)
                              : ProductImage(
                                  path: _existingImage,
                                  fallback: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined,
                                          color: AppColors.primary, size: 34),
                                      SizedBox(height: 6),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              (_pickedImage != null || _existingImage != null)
                                  ? Icons.edit
                                  : Icons.add,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      if (_pickedImage != null)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => setState(() => _pickedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _sectionLabel(theme, 'Basic Information'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Product Name *'),
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
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'SKU is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
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
                  isExpanded: true,
                  initialValue:
                      categories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.isActive ? c.name : '${c.name} (Inactive)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => v == null ? 'Category is required' : null,
                ),
                const SizedBox(height: 12),

                // Supplier dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      suppliers.any((s) => s.id == _selectedSupplierId)
                          ? _selectedSupplierId
                          : null,
                  decoration: const InputDecoration(labelText: 'Supplier *'),
                  items: suppliers
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.isActive ? s.name : '${s.name} (Inactive)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSupplierId = v),
                  validator: (v) => v == null ? 'Supplier is required' : null,
                ),
                const SizedBox(height: 12),

                // Status dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status *'),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                const SizedBox(height: 20),

                _sectionLabel(theme, 'Pricing & Stock'),
                const SizedBox(height: 8),

                // Price
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixText: '\$ ',
                    helperText: 'Positive price (e.g. 19.99)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Price is required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n < 0) return 'Enter a valid positive price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Unit of Measure selector
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit of Measure *',
                    prefixIcon: Icon(Icons.straighten_outlined, size: 20),
                  ),
                  items: _units
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              '${u.toUpperCase()} (${_unitDescription(u)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _unit = v);
                    }
                  },
                ),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 280;
                    final qtyField = TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText:
                            _isEditing ? 'Current Stock *' : 'Initial Qty *',
                        hintText: '0',
                        helperText: 'Numbers only (non-negative)',
                        suffixText: _unit,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Initial quantity is required';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null) return 'Numbers only';
                        if (n < 0) return 'Stock quantity cannot be negative';
                        return null;
                      },
                    );
                    final minStockField = TextFormField(
                      controller: _minStockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Min Stock *',
                        hintText: '10',
                        helperText: 'Numbers only (non-negative)',
                        suffixText: _unit,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Min stock is required';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null) return 'Numbers only';
                        if (n < 0) return 'Min stock cannot be negative';
                        return null;
                      },
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          qtyField,
                          const SizedBox(height: 12),
                          minStockField,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: qtyField),
                        const SizedBox(width: 12),
                        Expanded(child: minStockField),
                      ],
                    );
                  },
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
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Text(label,
        style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary));
  }


  Future<void> _loadBackendUnits() async {
    try {
      final backendUnits = await ApiService().getUnitsOfMeasure();
      if (backendUnits.isNotEmpty && mounted) {
        setState(() {
          for (final u in backendUnits) {
            final lower = u.toLowerCase();
            if (!_units.contains(lower)) {
              _units.add(lower);
            }
          }
        });
      }
    } catch (_) {}
  }

  String _unitDescription(String unit) {
    switch (unit.toLowerCase()) {
      case 'pcs':
        return 'Pieces';
      case 'box':
        return 'Boxes';
      case 'pack':
        return 'Packs';
      case 'bottle':
        return 'Bottles';
      case 'can':
        return 'Cans / Tins';
      case 'kg':
        return 'Kilograms';
      case 'liter':
        return 'Liters';
      case 'dozen':
        return 'Dozens (12 pcs)';
      case 'case':
        return 'Cases';
      case 'carton':
        return 'Cartons';
      case 'bundle':
        return 'Bundles';
      case 'bale':
        return 'Bales';
      case 'sack':
        return 'Sacks';
      case 'bag':
        return 'Bags';
      case 'pallet':
        return 'Pallets';
      case 'roll':
        return 'Rolls';
      case 'set':
        return 'Sets';
      case 'pair':
        return 'Pairs';
      case 'tray':
        return 'Trays';
      default:
        return unit.toUpperCase();
    }
  }
}