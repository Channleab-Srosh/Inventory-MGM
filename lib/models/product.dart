/// Stock status of a product
enum StockStatus { inStock, lowStock, outOfStock }

/// Product model
class Product {
  final String id;
  String name;
  String sku;
  String categoryId;
  String supplierId;
  String? categoryName;
  String? supplierName;
  double price;
  int quantity;
  int minStockLevel;
  String unit;
  String? imageUrl;
  String? description;
  String status;
  DateTime createdAt;
  DateTime updatedAt;

  static const List<String> commonUnits = [
    'pcs',
    'box',
    'pack',
    'bottle',
    'can',
    'kg',
    'liter',
    'dozen',
    'case',
    'carton',
    'bundle',
    'bale',
    'sack',
    'bag',
    'pallet',
    'roll',
    'set',
    'pair',
    'tray',
  ];

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.supplierId,
    this.categoryName,
    this.supplierName,
    required this.price,
    required this.quantity,
    required this.minStockLevel,
    this.unit = 'pcs',
    this.imageUrl,
    this.description,
    this.status = 'Active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json) {
    // Category ID & Name
    String catId = '';
    String? catName;
    if (json['category'] is Map) {
      catId = json['category']['id']?.toString() ?? '';
      catName = json['category']['name']?.toString();
    } else {
      catId = json['categoryId']?.toString() ?? '';
      catName = json['categoryName']?.toString();
    }

    // Supplier ID & Name
    String supId = '';
    String? supName;
    if (json['supplier'] is Map) {
      supId = json['supplier']['id']?.toString() ?? '';
      supName = json['supplier']['name']?.toString();
    } else {
      supId = json['supplierId']?.toString() ?? '';
      supName = json['supplierName']?.toString();
    }

    // Status
    String status = 'Active';
    if (json['active'] != null) {
      status = (json['active'] as bool) ? 'Active' : 'Inactive';
    } else if (json['status'] != null) {
      status = json['status'].toString();
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      categoryId: catId,
      categoryName: catName,
      supplierId: supId,
      supplierName: supName,
      price: (json['unitPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      quantity: (json['stockQuantity'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      minStockLevel: (json['minimumStock'] as num?)?.toInt() ??
          (json['minStockLevel'] as num?)?.toInt() ??
          10,
      unit: (json['unitOfMeasure'] as String?)?.toLowerCase() ??
          (json['unit'] as String?)?.toLowerCase() ??
          'pcs',
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      status: status,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'categoryId': categoryId,
      'supplierId': supplierId,
      'unitPrice': price,
      'stockQuantity': quantity,
      'minimumStock': minStockLevel,
      'unitOfMeasure': unit.toUpperCase(),
      'imageUrl': imageUrl,
      'description': description,
      'active': status.toLowerCase() == 'active',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Computed stock status
  StockStatus get stockStatus {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= minStockLevel) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  /// Formatted quantity with unit (e.g., "55 cans", "42 kg")
  String get quantityWithUnit => '$quantity $unit';

  /// Formatted minimum stock level with unit (e.g., "20 cans", "10 kg")
  String get minStockWithUnit => '$minStockLevel $unit';

  Product copyWith({
    String? name,
    String? sku,
    String? categoryId,
    String? categoryName,
    String? supplierId,
    String? supplierName,
    double? price,
    int? quantity,
    int? minStockLevel,
    String? unit,
    String? imageUrl,
    String? description,
    String? status,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
