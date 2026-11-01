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
  final String? unit;
  final double? unitCost;
  final String? supplierId;
  final StockOutReason? reason;
  final String? reference;
  final String? note;
  final int? stockBefore;
  final int? stockAfter;
  final String userId;
  final String userName;
  final DateTime date;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    this.unit = 'pcs',
    this.stockBefore,
    this.stockAfter,
    this.unitCost,
    this.supplierId,
    this.reason,
    this.reference,
    this.note,
    required this.userId,
    required this.userName,
    required this.date,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    // Determine movement type
    final rawType = json['transactionType']?.toString().toUpperCase() ??
        json['type']?.toString().toUpperCase() ??
        '';
    final isOut = rawType.contains('OUT');

    return StockMovement(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      type: isOut ? MovementType.stockOut : MovementType.stockIn,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: (json['unitOfMeasure'] as String?)?.toLowerCase() ??
          (json['unit'] as String?)?.toLowerCase() ??
          'pcs',
      stockBefore: (json['quantityBefore'] as num?)?.toInt() ??
          (json['stockBefore'] as num?)?.toInt(),
      stockAfter: (json['quantityAfter'] as num?)?.toInt() ??
          (json['stockAfter'] as num?)?.toInt(),
      unitCost: (json['unitCost'] as num?)?.toDouble(),
      supplierId: json['supplierId']?.toString(),
      reference: json['reference']?.toString() ?? json['productSku']?.toString(),
      note: json['note']?.toString(),
      userId: json['createdById']?.toString() ?? json['userId']?.toString() ?? '1',
      userName: json['createdByUsername']?.toString() ??
          json['userName']?.toString() ??
          'User',
      date: (DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now()).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productSku': reference,
      'productName': productName,
      'transactionType': isStockIn ? 'STOCK_IN' : 'STOCK_OUT',
      'quantity': quantity,
      'unitOfMeasure': (unit ?? 'pcs').toUpperCase(),
      'quantityBefore': stockBefore,
      'quantityAfter': stockAfter,
      'note': note,
      'reference': reference,
      'createdById': userId,
      'createdByUsername': userName,
      'createdAt': date.toIso8601String(),
    };
  }

  bool get isStockIn => type == MovementType.stockIn;
  bool get isStockOut => type == MovementType.stockOut;

  String get formattedQuantity => '$quantity ${unit ?? "pcs"}';
}
