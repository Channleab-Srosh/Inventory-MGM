/// Type of stock movement
enum MovementType { stockIn, stockOut }

/// Reason for stock out
enum StockOutReason { sale, damaged, other }

/// Represents a single stock movement (in or out)
class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final double? unitCost;
  final String? supplierId;
  final StockOutReason? reason;
  final String? reference;
  final String? note;
  final String userId;
  final String userName;
  final DateTime date;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    this.unitCost,
    this.supplierId,
    this.reason,
    this.reference,
    this.note,
    required this.userId,
    required this.userName,
    required this.date,
  });

  bool get isStockIn => type == MovementType.stockIn;
}
