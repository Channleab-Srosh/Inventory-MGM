import 'package:flutter/material.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/models/product.dart';
import 'package:inventory_management/models/category.dart';
import 'package:inventory_management/models/supplier.dart';

/// Modal bottom sheet for filtering products by Category, Supplier, and Stock Status.
class ProductFilterSheet extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialSupplierId;
  final StockStatus? initialStatus;
  final List<Category> categories;
  final List<Supplier> suppliers;
  final void Function(String? categoryId, String? supplierId, StockStatus? status)
      onApply;

  const ProductFilterSheet({
    super.key,
    this.initialCategoryId,
    this.initialSupplierId,
    this.initialStatus,
    required this.categories,
    required this.suppliers,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String? initialCategoryId,
    required String? initialSupplierId,
    required StockStatus? initialStatus,
    required List<Category> categories,
    required List<Supplier> suppliers,
    required void Function(
            String? categoryId, String? supplierId, StockStatus? status)
        onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductFilterSheet(
        initialCategoryId: initialCategoryId,
        initialSupplierId: initialSupplierId,
        initialStatus: initialStatus,
        categories: categories,
        suppliers: suppliers,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  String? _tempCatId;
  String? _tempSupId;
  StockStatus? _tempStatus;

  @override
  void initState() {
    super.initState();
    _tempCatId = widget.initialCategoryId;
    _tempSupId = widget.initialSupplierId;
    _tempStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
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
                    setState(() {
                      _tempCatId = null;
                      _tempSupId = null;
                      _tempStatus = null;
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
                  selected: _tempCatId == null,
                  onSelected: (val) {
                    if (val) setState(() => _tempCatId = null);
                  },
                ),
                ...widget.categories.map(
                  (c) => ChoiceChip(
                    label: Text(c.name),
                    selected: _tempCatId == c.id,
                    onSelected: (val) {
                      setState(() => _tempCatId = val ? c.id : null);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Supplier',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Suppliers'),
                  selected: _tempSupId == null,
                  onSelected: (val) {
                    if (val) setState(() => _tempSupId = null);
                  },
                ),
                ...widget.suppliers.map(
                  (s) => ChoiceChip(
                    label: Text(s.name),
                    selected: _tempSupId == s.id,
                    onSelected: (val) {
                      setState(() => _tempSupId = val ? s.id : null);
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
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Status'),
                  selected: _tempStatus == null,
                  onSelected: (val) {
                    if (val) setState(() => _tempStatus = null);
                  },
                ),
                ChoiceChip(
                  label: const Text('In Stock'),
                  selected: _tempStatus == StockStatus.inStock,
                  onSelected: (val) {
                    setState(() =>
                        _tempStatus = val ? StockStatus.inStock : null);
                  },
                ),
                ChoiceChip(
                  label: const Text('Low Stock'),
                  selected: _tempStatus == StockStatus.lowStock,
                  onSelected: (val) {
                    setState(() =>
                        _tempStatus = val ? StockStatus.lowStock : null);
                  },
                ),
                ChoiceChip(
                  label: const Text('Out of Stock'),
                  selected: _tempStatus == StockStatus.outOfStock,
                  onSelected: (val) {
                    setState(() =>
                        _tempStatus = val ? StockStatus.outOfStock : null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_tempCatId, _tempSupId, _tempStatus);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
