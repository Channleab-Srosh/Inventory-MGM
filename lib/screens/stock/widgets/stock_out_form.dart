import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/stock_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/stock_movement.dart';
import '../../../models/product.dart';
import 'stock_form_components.dart';

/// Form widget for recording Stock Out
class StockOutForm extends StatefulWidget {
  final String? initialProductId;
  const StockOutForm({super.key, this.initialProductId});

  @override
  State<StockOutForm> createState() => _StockOutFormState();
}

class _StockOutFormState extends State<StockOutForm> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  String? _selectedCustomerId;
  int _quantity = 1;
  StockOutReason _reason = StockOutReason.sale;
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProductId != null) {
      _applyInitialProduct(widget.initialProductId!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cust = context.read<CustomerProvider>();
      if (cust.allCustomers.isEmpty) {
        cust.fetchCustomers();
      }
    });
  }

  @override
  void didUpdateWidget(covariant StockOutForm oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      });
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canStockOut != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Permission denied: Staff accounts cannot perform stock out.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a product')));
      return;
    }
    final availableQty = _selectedProduct?.quantity ?? 0;
    if (_quantity > availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Text(
              'Insufficient stock. Available quantity: $availableQty ${_selectedProduct?.unit ?? "pcs"}'),
        ]),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final stock = context.read<StockProvider>();
    final products = context.read<ProductProvider>();
    final custProv = context.read<CustomerProvider>();
    final selectedCustomer = custProv.allCustomers
        .where((c) => c.id == _selectedCustomerId)
        .firstOrNull;

    setState(() => _submitting = true);

    try {
      final noteParts = [
        'Reason: ${_reason.name}',
        if (selectedCustomer != null) 'Customer: ${selectedCustomer.name}',
        if (_noteCtrl.text.trim().isNotEmpty) _noteCtrl.text.trim(),
      ];
      final note = noteParts.join(' - ');

      await stock.recordStockOut(
        productId: _selectedProduct!.id,
        quantity: _quantity,
        customerId: _selectedCustomerId,
        reason: _reason,
        note: note,
        transactionDate: _date,
      );
      products.adjustQuantity(_selectedProduct!.id, -_quantity);
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
        _selectedCustomerId = null;
        _quantity = 1;
        _reason = StockOutReason.sale;
        _noteCtrl.clear();
        _date = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Stock Out recorded successfully!'),
        ]),
        backgroundColor: AppColors.chartOut,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user?.canStockOut != true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 56, color: AppColors.chartOut),
              const SizedBox(height: 16),
              Text(
                'Stock Out Restricted',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has the Staff role. Staff members are not permitted to record Stock Out movements.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      );
    }

    final stock = context.watch<StockProvider>();
    final availableQty = _selectedProduct?.quantity ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductSelectorField(
                selectedProduct: _selectedProduct,
                onSelect: (p) => setState(() {
                  _selectedProduct = p;
                  _quantity = 1;
                }),
              ),
              if (_selectedProduct != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Available: $availableQty ${_selectedProduct!.unit}',
                  style: TextStyle(
                    color: availableQty == 0
                        ? AppColors.outOfStock
                        : AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),

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

              // Reason chips
              const Text('Reason',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StockOutReason.values.map((r) {
                  final label = _reasonLabel(r);
                  return ChoiceChip(
                    label: Text(label),
                    selected: _reason == r,
                    onSelected: (_) => setState(() => _reason = r),
                    selectedColor: AppColors.chartOut.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _reason == r ? AppColors.chartOut : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Customer selector
              Consumer<CustomerProvider>(
                builder: (context, custProv, _) {
                  final customers = custProv.allCustomers
                      .where((c) => c.isActive || c.id == _selectedCustomerId)
                      .toList();
                  final isCustomerRequired = _reason != StockOutReason.damaged;
                  final currentVal =
                      customers.any((c) => c.id == _selectedCustomerId)
                          ? _selectedCustomerId
                          : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey('customer_dropdown_${_reason.name}_$_selectedCustomerId'),
                      isExpanded: true,
                      initialValue: currentVal,
                      decoration: InputDecoration(
                        labelText: isCustomerRequired
                            ? 'Customer *'
                            : 'Customer (optional for damage)',
                        helperText: !isCustomerRequired
                            ? 'Customer is not required for damaged goods'
                            : null,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      hint: Text(customers.isEmpty
                          ? 'No customers available'
                          : 'Select a customer'),
                      items: [
                        if (!isCustomerRequired)
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Customer (Damage)'),
                          ),
                        ...customers.map((c) => DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(
                                c.isActive
                                    ? '${c.name} (${c.phone})'
                                    : '${c.name} (${c.phone}) (Inactive)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      validator: (val) {
                        if (isCustomerRequired && (val == null || val.isEmpty)) {
                          return 'Customer is required for ${_reasonLabel(_reason).toLowerCase()} operations';
                        }
                        return null;
                      },
                      onChanged: (val) =>
                          setState(() => _selectedCustomerId = val),
                    ),
                  );
                },
              ),

              DatePickerField(
                date: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chartOut),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_upward),
                label: const Text('Record Stock Out'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Recent Stock Out'),
        const SizedBox(height: 8),
        if (stock.recentStockOut.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No recent stock out records yet',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ),
          )
        else
          ...stock.recentStockOut.map((m) => StockRecentTile(movement: m)),
        const SizedBox(height: 80),
      ],
    );
  }

  String _reasonLabel(StockOutReason r) {
    switch (r) {
      case StockOutReason.sale:
        return 'Sale';
      case StockOutReason.damaged:
        return 'Damaged';
      case StockOutReason.other:
        return 'Other';
    }
  }
}
