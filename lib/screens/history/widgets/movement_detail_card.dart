import 'package:flutter/material.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/models/stock_movement.dart';

/// Transaction card matching Notion Page 11:
/// Date, Product, Type, Qty, Before, After, User, Reference
class MovementDetailCard extends StatelessWidget {
  final StockMovement movement;
  const MovementDetailCard({super.key, required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.chartIn : AppColors.chartOut;
    final theme = Theme.of(context);
    final sign = isIn ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMovementDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Top: Icon + Product Name + Qty
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isIn ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isIn ? 'STOCK_IN' : 'STOCK_OUT',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isIn && movement.reason != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (movement.reason == StockOutReason.damaged
                                        ? AppColors.danger
                                        : movement.reason == StockOutReason.other
                                            ? AppColors.warning
                                            : AppColors.inStock)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                movement.reason == StockOutReason.damaged
                                    ? 'DAMAGE'
                                    : movement.reason == StockOutReason.other
                                        ? 'OTHER'
                                        : 'SALE',
                                style: TextStyle(
                                  color: movement.reason == StockOutReason.damaged
                                      ? AppColors.danger
                                      : movement.reason == StockOutReason.other
                                          ? AppColors.warning
                                          : AppColors.inStock,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.secondaryText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppUtils.formatDateTime(movement.date),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$sign${movement.quantity}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      movement.unit ?? 'units',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Middle: Before / After Stock comparison (Required by Notion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Before: ',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                      Text(
                        movement.stockBefore != null
                            ? '${movement.stockBefore} ${movement.unit ?? ""}'
                            : '-',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 13, color: AppColors.grey500),
                      ),
                      const Text(
                        'After: ',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                      Text(
                        movement.stockAfter != null
                            ? '${movement.stockAfter} ${movement.unit ?? ""}'
                            : '-',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isIn ? AppColors.inStock : AppColors.chartOut,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 13, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        movement.userName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Supplier or Customer Info Badge
            if (isIn && movement.supplierName != null && movement.supplierName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Supplier: ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                  ),
                  Expanded(
                    child: Text(
                      movement.supplierName!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else if (!isIn && movement.customerName != null && movement.customerName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.chartOut),
                  const SizedBox(width: 6),
                  const Text(
                    'Customer: ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                  ),
                  Expanded(
                    child: Text(
                      movement.customerName!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else if (!isIn && movement.reason == StockOutReason.damaged) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.report_problem_outlined, size: 14, color: AppColors.danger),
                  SizedBox(width: 6),
                  Text(
                    'Damaged Goods (No customer assigned)',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ],

            // Bottom metadata: reference, reason, note, cost
            if (isIn && movement.unitCost != null && movement.unitCost! > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.attach_money_rounded, size: 14, color: AppColors.chartIn),
                  const SizedBox(width: 4),
                  const Text(
                    'Unit Cost: ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                  ),
                  Text(
                    AppUtils.formatCurrency(movement.unitCost!),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.chartIn),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(Total: ${AppUtils.formatCurrency(movement.unitCost! * movement.quantity)})',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ],
            if (movement.reference != null || movement.displayNote != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (movement.reference != null)
                    Expanded(
                      child: Text(
                        'Ref: ${movement.reference}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.secondaryText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (movement.displayNote != null)
                    Expanded(
                      child: Text(
                        'Note: ${movement.displayNote}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.secondaryText),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  void _showMovementDetailSheet(BuildContext context) {
    showMovementDetailSheet(context, movement);
  }

  /// Show detailed bottom sheet for a stock movement transaction
  static void showMovementDetailSheet(BuildContext context, StockMovement movement) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.chartIn : AppColors.chartOut;
    final sign = isIn ? '+' : '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isIn ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.productName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transaction #${movement.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isIn ? 'STOCK IN' : 'STOCK OUT',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.swap_horiz,
                label: 'Quantity Change',
                value: '$sign${movement.quantity} ${movement.unit ?? "pcs"}',
                valueColor: color,
              ),
              _buildDetailRow(
                icon: Icons.layers_outlined,
                label: 'Stock Before → After',
                value:
                    '${movement.stockBefore ?? "-"} → ${movement.stockAfter ?? "-"} ${movement.unit ?? "pcs"}',
              ),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Date & Time',
                value: AppUtils.formatDateTime(movement.date),
              ),
              _buildDetailRow(
                icon: Icons.person_outline,
                label: 'Recorded By',
                value: movement.userName,
              ),
              if (isIn) ...[
                _buildDetailRow(
                  icon: Icons.storefront_outlined,
                  label: 'Supplier',
                  value: movement.supplierName ??
                      (movement.supplierId != null
                          ? 'Supplier #${movement.supplierId}'
                          : 'N/A'),
                  valueColor: AppColors.primary,
                ),
                if (movement.unitCost != null && movement.unitCost! > 0) ...[
                  _buildDetailRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Unit Cost',
                    value: AppUtils.formatCurrency(movement.unitCost!),
                    valueColor: AppColors.chartIn,
                  ),
                  _buildDetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Total Cost',
                    value: AppUtils.formatCurrency(
                        movement.unitCost! * movement.quantity),
                    valueColor: AppColors.chartIn,
                  ),
                ],
              ] else ...[
                _buildDetailRow(
                  icon: Icons.assignment_ind_outlined,
                  label: 'Customer',
                  value: movement.customerName ??
                      (movement.reason == StockOutReason.damaged
                          ? 'Not Required (Damaged Goods)'
                          : 'N/A'),
                  valueColor:
                      movement.customerName != null ? AppColors.chartOut : null,
                ),
                _buildDetailRow(
                  icon: Icons.category_outlined,
                  label: 'Reason',
                  value: movement.reason == StockOutReason.damaged
                      ? 'DAMAGE'
                      : movement.reason == StockOutReason.other
                          ? 'OTHER'
                          : 'SALE',
                ),
              ],
              if (movement.reference != null && movement.reference!.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.tag,
                  label: 'Reference / SKU',
                  value: movement.reference!,
                ),
              if (movement.displayNote != null && movement.displayNote!.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.note_outlined,
                  label: 'Note',
                  value: movement.displayNote!,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.grey500),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
