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

            // Bottom metadata: reference, reason, note
            if (movement.reference != null || movement.note != null) ...[
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
                  if (movement.note != null)
                    Expanded(
                      child: Text(
                        'Note: ${movement.note}',
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
    );
  }
}
