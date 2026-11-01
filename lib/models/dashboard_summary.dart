/// Dashboard summary metrics model matching backend DashboardSummaryResponse.java
class DashboardSummary {
  final int totalProducts;
  final int totalCategories;
  final int totalSuppliers;
  final int totalStockQuantity;
  final double totalInventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalStockInQuantity;
  final int totalStockOutQuantity;

  const DashboardSummary({
    this.totalProducts = 0,
    this.totalCategories = 0,
    this.totalSuppliers = 0,
    this.totalStockQuantity = 0,
    this.totalInventoryValue = 0.0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalStockInQuantity = 0,
    this.totalStockOutQuantity = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ??
          (json['totalItems'] as num?)?.toInt() ??
          0,
      totalCategories: (json['totalCategories'] as num?)?.toInt() ?? 0,
      totalSuppliers: (json['totalSuppliers'] as num?)?.toInt() ?? 0,
      totalStockQuantity: (json['totalStockQuantity'] as num?)?.toInt() ??
          (json['totalUnits'] as num?)?.toInt() ??
          0,
      totalInventoryValue: (json['totalInventoryValue'] as num?)?.toDouble() ??
          (json['totalInventoryValuation'] as num?)?.toDouble() ??
          0.0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (json['outOfStockCount'] as num?)?.toInt() ?? 0,
      totalStockInQuantity: (json['totalStockInQuantity'] as num?)?.toInt() ?? 0,
      totalStockOutQuantity: (json['totalStockOutQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'totalCategories': totalCategories,
      'totalSuppliers': totalSuppliers,
      'totalStockQuantity': totalStockQuantity,
      'totalInventoryValue': totalInventoryValue,
      'lowStockCount': lowStockCount,
      'outOfStockCount': outOfStockCount,
      'totalStockInQuantity': totalStockInQuantity,
      'totalStockOutQuantity': totalStockOutQuantity,
    };
  }
}
