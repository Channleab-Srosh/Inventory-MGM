import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product.dart';
import '../../../models/stock_movement.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../history/widgets/movement_detail_card.dart';

/// Reusable product selector input with modal bottom sheet
class ProductSelectorField extends StatelessWidget {
  final Product? selectedProduct;
  final ValueChanged<Product> onSelect;

  const ProductSelectorField({
    super.key,
    required this.selectedProduct,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductSelectorSheet(onSelect: (p) {
        onSelect(p);
        Navigator.pop(context);
      }),
    );
  }
}

/// Searchable product bottom sheet
class ProductSelectorSheet extends StatefulWidget {
  final ValueChanged<Product> onSelect;
  const ProductSelectorSheet({super.key, required this.onSelect});

  @override
  State<ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<ProductSelectorSheet> {
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: DraggableScrollableSheet(
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
                ),
              ),
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
                        child: const Icon(Icons.inventory_2_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'SKU: ${p.sku} · Qty: ${p.quantity} ${p.unit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => widget.onSelect(p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date & Time picker field for recording stock transactions
class DatePickerField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({
    super.key,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null && context.mounted) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date),
          );
          final finalDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime?.hour ?? date.hour,
            pickedTime?.minute ?? date.minute,
          );
          onChanged(finalDateTime);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppUtils.formatDateTime(date),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const Icon(Icons.access_time_rounded,
                color: AppColors.secondaryText, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Recent movement tile in stock forms
class StockRecentTile extends StatelessWidget {
  final StockMovement movement;
  const StockRecentTile({super.key, required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.chartIn : AppColors.chartOut;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => MovementDetailCard.showMovementDetailSheet(context, movement),
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isIn ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 16,
          ),
        ),
        title: Text(
          movement.productName,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movement.stockBefore != null && movement.stockAfter != null
                  ? '${AppUtils.formatDateTime(movement.date)} · Stock: ${movement.stockBefore} → ${movement.stockAfter} ${movement.unit ?? "pcs"}'
                  : AppUtils.formatDateTime(movement.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
            if (isIn && movement.unitCost != null && movement.unitCost! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Unit Cost: ${AppUtils.formatCurrency(movement.unitCost!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chartIn,
                  ),
                ),
              ),
            if (isIn && movement.supplierName != null && movement.supplierName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Supplier: ${movement.supplierName}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (!isIn && movement.customerName != null && movement.customerName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Customer: ${movement.customerName}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chartOut,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${isIn ? '+' : '-'}${movement.quantity} ${movement.unit ?? "pcs"}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
