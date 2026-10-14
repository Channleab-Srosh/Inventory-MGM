import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/stock_movement.dart';
import '../../models/product.dart';

/// Stock In / Stock Out screen with segmented control
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  int _selectedTab = 0; // 0=In, 1=Out

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history_outlined, size: 18),
            label: const Text('History →'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Stock In'),
                  icon: Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Stock Out'),
                  icon: Icon(Icons.arrow_upward, size: 16),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (s) =>
                  setState(() => _selectedTab = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _selectedTab == 0
                        ? AppColors.chartIn
                        : AppColors.chartOut;
                  }
                  return null;
                }),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _selectedTab == 0
                ? const _StockInForm()
                : const _StockOutForm(),
          ),
        ],
      ),
    );
  }
}

// ===================== STOCK IN FORM =====================
class _StockInForm extends StatefulWidget {
  const _StockInForm();

  @override
  State<_StockInForm> createState() => _StockInFormState();
}

class _StockInFormState extends State<_StockInForm> {
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
    final auth = context.read<AuthProvider>();
    final stock = context.read<StockProvider>();
    final products = context.read<ProductProvider>();

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final movement = StockMovement(
      id: stock.generateId(),
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      type: MovementType.stockIn,
      quantity: _quantity,
      unitCost: _costCtrl.text.isNotEmpty ? double.tryParse(_costCtrl.text) : null,
      supplierId: _selectedSupplierId,
      reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      userId: auth.user?.id ?? 'u1',
      userName: auth.user?.name ?? 'User',
      date: _date,
    );

    stock.addMovement(movement);
    products.adjustQuantity(_selectedProduct!.id, _quantity);

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
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
    final suppliers = context.watch<SupplierProvider>().allSuppliers;
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
              _ProductSelector(
                selectedProduct: _selectedProduct,
                onSelect: (p) => setState(() => _selectedProduct = p),
              ),
              const SizedBox(height: 12),

              // Feature 30: Live calculation preview (New Stock = Current Stock + Quantity)
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
                      Column(
                        children: [
                          const Text('Current Stock',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText)),
                          const SizedBox(height: 2),
                          Text('${_selectedProduct!.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                      const Icon(Icons.add,
                          size: 18, color: AppColors.success),
                      Column(
                        children: [
                          const Text('Quantity',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText)),
                          const SizedBox(height: 2),
                          Text('+$_quantity',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.success)),
                        ],
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 18, color: AppColors.secondaryText),
                      Column(
                        children: [
                          const Text('New Stock',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText)),
                          const SizedBox(height: 2),
                          Text('${_selectedProduct!.quantity + _quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Supplier
              DropdownButtonFormField<String>(
                value: _selectedSupplierId,
                decoration:
                    const InputDecoration(labelText: 'Supplier (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...suppliers.map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _selectedSupplierId = v),
              ),
              const SizedBox(height: 12),

              // Quantity
              Row(
                children: [
                  const Text('Quantity',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  QuantityStepper(
                    value: _quantity,
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reference Number
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (optional)',
                  hintText: 'e.g. PO-2024-001',
                  prefixIcon: Icon(Icons.tag, size: 20),
                ),
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
              _DatePickerField(
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
        ...stock.recentTransactions
            .where((m) => m.type == MovementType.stockIn)
            .take(5)
            .map((m) => _RecentTile(movement: m)),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ===================== STOCK OUT FORM =====================
class _StockOutForm extends StatefulWidget {
  const _StockOutForm();

  @override
  State<_StockOutForm> createState() => _StockOutFormState();
}

class _StockOutFormState extends State<_StockOutForm> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  int _quantity = 1;
  StockOutReason _reason = StockOutReason.sale;
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
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
    if (_quantity > (_selectedProduct?.quantity ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quantity exceeds available stock!')));
      return;
    }

    // Capture providers BEFORE await to avoid BuildContext across async gap
    final auth = context.read<AuthProvider>();
    final stock = context.read<StockProvider>();
    final products = context.read<ProductProvider>();

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 400));

    stock.addMovement(StockMovement(
      id: stock.generateId(),
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      type: MovementType.stockOut,
      quantity: _quantity,
      reason: _reason,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      userId: auth.user?.id ?? 'u1',
      userName: auth.user?.name ?? 'User',
      date: _date,
    ));
    products.adjustQuantity(_selectedProduct!.id, -_quantity);

    if (mounted) {
      setState(() {
        _submitting = false;
        _selectedProduct = null;
        _quantity = 1;
        _reason = StockOutReason.sale;
        _noteCtrl.clear();
        _date = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
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
              _ProductSelector(
                selectedProduct: _selectedProduct,
                onSelect: (p) => setState(() {
                  _selectedProduct = p;
                  _quantity = 1;
                }),
              ),
              if (_selectedProduct != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Available: $availableQty units',
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
                  const Text('Quantity',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  QuantityStepper(
                    value: _quantity,
                    max: availableQty > 0 ? availableQty : 1,
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

              _DatePickerField(
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
        ...stock.recentTransactions
            .where((m) => m.type == MovementType.stockOut)
            .take(5)
            .map((m) => _RecentTile(movement: m)),
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

// ---- Shared widgets ----

/// Product selector bottom sheet trigger
class _ProductSelector extends StatelessWidget {
  final Product? selectedProduct;
  final ValueChanged<Product> onSelect;

  const _ProductSelector(
      {required this.selectedProduct, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.grey800
              : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: AppColors.grey500, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedProduct?.name ?? 'Select Product...',
                style: selectedProduct == null
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductSelectorSheet(onSelect: (p) {
        onSelect(p);
        Navigator.pop(context);
      }),
    );
  }
}

class _ProductSelectorSheet extends StatefulWidget {
  final ValueChanged<Product> onSelect;
  const _ProductSelectorSheet({required this.onSelect});

  @override
  State<_ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<_ProductSelectorSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final all = context.read<ProductProvider>().allProducts;
    final filtered = _search.isEmpty
        ? all
        : all
            .where((p) =>
                p.name.toLowerCase().contains(_search.toLowerCase()) ||
                p.sku.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              )),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchField(
              hint: 'Search products...',
              onChanged: (q) => setState(() => _search = q),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final p = filtered[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(p.name),
                  subtitle: Text('SKU: ${p.sku} · Qty: ${p.quantity}'),
                  onTap: () => widget.onSelect(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple date picker field
class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DatePickerField({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.grey800
              : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.grey500, size: 18),
            const SizedBox(width: 12),
            Text(AppUtils.formatDate(date),
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Recent movement tile in stock forms
class _RecentTile extends StatelessWidget {
  final StockMovement movement;
  const _RecentTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.chartIn : AppColors.chartOut;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
            isIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: color, size: 16),
      ),
      title: Text(movement.productName,
          style: theme.textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(AppUtils.timeAgo(movement.date),
          style: theme.textTheme.bodyMedium),
      trailing: Text(
        '${isIn ? '+' : '-'}${movement.quantity}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
