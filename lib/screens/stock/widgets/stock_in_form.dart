import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/supplier_provider.dart';
import '../../../providers/stock_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/product.dart';
import 'stock_form_components.dart';

/// Form widget for recording Stock In
class StockInForm extends StatefulWidget {
  final String? initialProductId;
  final int? initialQuantity;

  const StockInForm({
    super.key,
    this.initialProductId,
    this.initialQuantity,
  });

  @override
  State<StockInForm> createState() => _StockInFormState();
}

class _StockInFormState extends State<StockInForm> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  String? _selectedSupplierId;
  int _quantity = 1;
  final _costCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuantity != null && widget.initialQuantity! > 0) {
      _quantity = widget.initialQuantity!;
    }
    if (widget.initialProductId != null) {
      _applyInitialProduct(widget.initialProductId!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sup = context.read<SupplierProvider>();
      if (sup.allSuppliers.isEmpty) {
        sup.fetchSuppliers();
      }
    });
  }

  @override
  void didUpdateWidget(covariant StockInForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuantity != null &&
        widget.initialQuantity != oldWidget.initialQuantity) {
      _quantity = widget.initialQuantity!;
    }
    if (widget.initialProductId != null &&
        widget.initialProductId != oldWidget.initialProductId) {
      _applyInitialProduct(widget.initialProductId!);
    }
  }

  Future<void> _applyInitialProduct(String productId) async {
    final products = context.read<ProductProvider>();
    final p = products.findById(productId) ??
        await products.fetchProductById(productId);
    if (mounted && p != null) {
      setState(() {
        _selectedProduct = p;
        if (p.supplierId.isNotEmpty) {
          _selectedSupplierId = p.supplierId;
        }
      });
    }
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    _refCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a product')));
      return;
    }
    final stock = context.read<StockProvider>();
    final products = context.read<ProductProvider>();

    setState(() => _submitting = true);

    try {
      final costText = _costCtrl.text.trim();
      final double? parsedCost =
          costText.isNotEmpty ? double.tryParse(costText) : null;

      final noteParts = [
        if (_refCtrl.text.trim().isNotEmpty) 'Ref: ${_refCtrl.text.trim()}',
        if (parsedCost != null && parsedCost > 0)
          'Unit Cost: \$${parsedCost.toStringAsFixed(2)}',
        if (_noteCtrl.text.trim().isNotEmpty) _noteCtrl.text.trim(),
      ];
      final note = noteParts.isNotEmpty ? noteParts.join(' - ') : null;

      await stock.recordStockIn(
        productId: _selectedProduct!.id,
        quantity: _quantity,
        supplierId: _selectedSupplierId,
        unitCost: parsedCost,
        note: note,
        transactionDate: _date,
      );
      products.adjustQuantity(_selectedProduct!.id, _quantity);
      products.loadLowStock();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _submitting = false;
        _selectedProduct = null;
        _selectedSupplierId = null;
        _quantity = 1;
        _costCtrl.clear();
        _refCtrl.clear();
        _noteCtrl.clear();
        _date = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Stock In recorded successfully!'),
        ]),
        backgroundColor: AppColors.chartIn,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context
        .watch<SupplierProvider>()
        .allSuppliers
        .where((s) => s.isActive || s.id == _selectedSupplierId)
        .toList();
    final stock = context.watch<StockProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product selector
              ProductSelectorField(
                selectedProduct: _selectedProduct,
                onSelect: (p) => setState(() {
                  _selectedProduct = p;
                  if (p.supplierId.isNotEmpty) {
                    _selectedSupplierId = p.supplierId;
                  }
                }),
              ),
              const SizedBox(height: 12),

              // Live calculation preview (New Stock = Current Stock + Quantity)
              if (_selectedProduct != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Current Stock',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryText)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_selectedProduct!.quantity} ${_selectedProduct!.unit}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child:
                            Icon(Icons.add, size: 16, color: AppColors.success),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Quantity',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryText)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '+$_quantity ${_selectedProduct!.unit}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward,
                            size: 16, color: AppColors.secondaryText),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('New Stock',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryText)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_selectedProduct!.quantity + _quantity} ${_selectedProduct!.unit}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Supplier
              DropdownButtonFormField<String>(
                key: ValueKey('supplier_dropdown_$_selectedSupplierId'),
                isExpanded: true,
                initialValue: suppliers.any((s) => s.id == _selectedSupplierId)
                    ? _selectedSupplierId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Supplier *',
                  prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                ),
                hint: const Text('Select a supplier'),
                items: [
                  ...suppliers.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.isActive ? s.name : '${s.name} (Inactive)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Supplier is required' : null,
                onChanged: (v) => setState(() => _selectedSupplierId = v),
              ),
              const SizedBox(height: 12),

              // Quantity
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedProduct != null
                          ? 'Quantity (${_selectedProduct!.unit})'
                          : 'Quantity',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  QuantityStepper(
                    value: _quantity,
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Unit cost
              TextFormField(
                controller: _costCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit Cost (optional)',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 12),

              // Date picker
              DatePickerField(
                date: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chartIn),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_downward),
                label: const Text('Record Stock In'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recent transactions
        const SectionHeader(title: 'Recent Stock In'),
        const SizedBox(height: 8),
        if (stock.recentStockIn.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No recent stock in records yet',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ),
          )
        else
          ...stock.recentStockIn.map((m) => StockRecentTile(movement: m)),
        const SizedBox(height: 80),
      ],
    );
  }
}
