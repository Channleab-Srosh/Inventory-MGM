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
  final String? supplierName;
  final String? customerId;
  final String? customerName;
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
    this.supplierName,
    this.customerId,
    this.customerName,
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

    // Parse reason
    StockOutReason? parsedReason;
    final rawReason = (json['reason'] ?? json['stockOutReason'])?.toString().toUpperCase();
    if (rawReason != null && rawReason.isNotEmpty) {
      if (rawReason.contains('SALE')) {
        parsedReason = StockOutReason.sale;
      } else if (rawReason.contains('DAMAG')) {
        parsedReason = StockOutReason.damaged;
      } else if (rawReason.contains('OTHER') || rawReason.contains('OTH')) {
        parsedReason = StockOutReason.other;
      }
    }

    // Fallback: extract reason from note if not set explicitly
    if (parsedReason == null && json['note'] != null) {
      final noteLower = json['note'].toString().toLowerCase();
      if (noteLower.contains('reason: damage') || noteLower.contains('reason: damaged')) {
        parsedReason = StockOutReason.damaged;
      } else if (noteLower.contains('reason: other') || noteLower.contains('reason: oth')) {
        parsedReason = StockOutReason.other;
      } else if (noteLower.contains('reason: sale')) {
        parsedReason = StockOutReason.sale;
      }
    }

    // Default for stock out if reason is still null
    if (parsedReason == null && isOut) {
      parsedReason = StockOutReason.sale;
    }

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
      unitCost: (json['unitCost'] as num?)?.toDouble() ??
          (json['cost'] as num?)?.toDouble() ??
          (() {
            if (json['note'] != null) {
              final match = RegExp(r'(?:Unit Cost|Cost):\s*\$?([0-9]+(?:\.[0-9]+)?)', caseSensitive: false)
                  .firstMatch(json['note'].toString());
              if (match != null) {
                return double.tryParse(match.group(1)!);
              }
            }
            return null;
          })(),
      supplierId: json['supplierId']?.toString(),
      supplierName: json['supplierName']?.toString(),
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString(),
      reason: parsedReason,
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
      'reason': reason != null
          ? (reason == StockOutReason.damaged ? 'DAMAGE' : reason!.name.toUpperCase())
          : null,
      'quantity': quantity,
      'unitOfMeasure': (unit ?? 'pcs').toUpperCase(),
      'quantityBefore': stockBefore,
      'quantityAfter': stockAfter,
      if (unitCost != null) 'unitCost': unitCost,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'customerId': customerId,
      'customerName': customerName,
      'note': note,
      'reference': reference,
      'createdById': userId,
      'createdByUsername': userName,
      'createdAt': date.toIso8601String(),
    };
  }

  bool get isStockIn => type == MovementType.stockIn;
  bool get isStockOut => type == MovementType.stockOut;

  /// Returns note without internal Unit Cost tag if present
  String? get displayNote {
    if (note == null) return null;
    final cleaned = note!
        .replaceAll(RegExp(r'(?:^|\s*-\s*)Unit Cost:\s*\$?[0-9]+(?:\.[0-9]+)?', caseSensitive: false), '')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String get formattedQuantity => '$quantity ${unit ?? "pcs"}';
}
