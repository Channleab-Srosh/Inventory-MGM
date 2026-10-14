/// Stock status of a product
enum StockStatus { inStock, lowStock, outOfStock }

/// Product model
class Product {
  final String id;
  String name;
  String sku;
  String categoryId;
  String supplierId;
  double price;
  int quantity;
  int minStockLevel;
  String? imageUrl;
  String? description;
  DateTime createdAt;
  DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.supplierId,
    required this.price,
    required this.quantity,
    required this.minStockLevel,
    this.imageUrl,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Computed stock status
  StockStatus get stockStatus {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= minStockLevel) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  Product copyWith({
    String? name,
    String? sku,
    String? categoryId,
    String? supplierId,
    double? price,
    int? quantity,
    int? minStockLevel,
    String? imageUrl,
    String? description,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
