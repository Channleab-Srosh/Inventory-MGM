/// Inventory report response model matching backend InventoryReportResponse.java
class InventoryReportItem {
  final String id;
  final String sku;
  final String name;
  final String? categoryName;
  final String? supplierName;
  final String unitOfMeasure;
  final double unitPrice;
  final int stockQuantity;
  final int minimumStock;
  final double totalValue;
  final bool lowStock;
  final bool active;
  final DateTime updatedAt;

  InventoryReportItem({
    required this.id,
    required this.sku,
    required this.name,
    this.categoryName,
    this.supplierName,
    this.unitOfMeasure = 'PCS',
    required this.unitPrice,
    required this.stockQuantity,
    required this.minimumStock,
    required this.totalValue,
    required this.lowStock,
    required this.active,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  int get quantity => stockQuantity;
  int get minStockLevel => minimumStock;
  bool get isLowStock => lowStock;
  bool get isOutOfStock => stockQuantity <= 0;

  factory InventoryReportItem.fromJson(Map<String, dynamic> json) {
    return InventoryReportItem(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryName: json['categoryName']?.toString(),
      supplierName: json['supplierName']?.toString(),
      unitOfMeasure: json['unitOfMeasure']?.toString() ?? 'PCS',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toInt() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      lowStock: (json['lowStock'] as bool?) ?? false,
      active: (json['active'] as bool?) ?? true,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'categoryName': categoryName,
      'supplierName': supplierName,
      'unitOfMeasure': unitOfMeasure,
      'unitPrice': unitPrice,
      'stockQuantity': stockQuantity,
      'minimumStock': minimumStock,
      'totalValue': totalValue,
      'lowStock': lowStock,
      'active': active,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
