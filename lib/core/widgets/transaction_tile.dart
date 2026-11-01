import 'package:flutter/material.dart';
import '../../models/stock_movement.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';

/// Reusable Transaction / Movement Tile matching the modern 16px card & pill aesthetic
class TransactionTile extends StatelessWidget {
  final StockMovement movement;
  final VoidCallback? onTap;
  final bool showReference;

  const TransactionTile({
    super.key,
    required this.movement,
    this.onTap,
    this.showReference = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == MovementType.stockIn;
    final fgColor = isIn ? AppColors.inStockText : AppColors.outOfStockText;
    final bgColor = isIn ? AppColors.inStockBg : AppColors.outOfStockBg;
    final icon = isIn ? Icons.south_west_rounded : Icons.north_east_rounded;
    final sign = isIn ? '+' : '-';
    final typeLabel = isIn ? 'STOCK IN' : 'STOCK OUT';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(movement.date.year, movement.date.month, movement.date.day);
    final diffDays = today.difference(txDay).inDays;

    final String dateStr;
    if (diffDays == 0) {
      dateStr = 'Today · ${AppUtils.formatTime(movement.date)}';
    } else if (diffDays == 1) {
      dateStr = 'Yesterday · ${AppUtils.formatTime(movement.date)}';
    } else {
      dateStr = AppUtils.formatDateTime(movement.date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Circular pastel icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: fgColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Info center stack
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              movement.productName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: fgColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$dateStr · ${movement.userName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (movement.stockBefore != null && movement.stockAfter != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Stock: ${movement.stockBefore} → ${movement.stockAfter} ${movement.unit ?? "pcs"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (showReference && movement.reference != null && movement.reference!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Ref: ${movement.reference}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Quantity trailing
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$sign${movement.quantity} ${movement.unit ?? "pcs"}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: fgColor,
                      ),
                    ),
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
