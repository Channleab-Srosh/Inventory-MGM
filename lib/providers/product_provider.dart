import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../data/mock_data.dart';

/// Manages product list with search/filter
class ProductProvider extends ChangeNotifier {
  final List<Product> _products = List.from(MockData.products);
  String _searchQuery = '';
  String? _selectedCategoryId;
  StockStatus? _statusFilter;

  // ---- Getters ----
  List<Product> get filteredProducts => _applyFilters();
  List<Product> get allProducts => List.unmodifiable(_products);
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  StockStatus? get statusFilter => _statusFilter;

  // ---- Summary stats ----
  int get totalProducts => _products.length;
  int get totalQuantity => _products.fold(0, (s, p) => s + p.quantity);
  int get lowStockCount =>
      _products.where((p) => p.stockStatus == StockStatus.lowStock).length;
  int get outOfStockCount =>
      _products.where((p) => p.stockStatus == StockStatus.outOfStock).length;
  double get totalStockValue =>
      _products.fold(0.0, (s, p) => s + p.price * p.quantity);

  List<Product> get lowStockProducts => _products
      .where((p) =>
          p.stockStatus == StockStatus.lowStock ||
          p.stockStatus == StockStatus.outOfStock)
      .toList();

  // ---- Filter / search ----
  List<Product> _applyFilters() {
    var list = List<Product>.from(_products);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q))
          .toList();
    }
    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_statusFilter != null) {
      list = list.where((p) => p.stockStatus == _statusFilter).toList();
    }
    return list;
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _statusFilter = null;
    notifyListeners();
  }

  void setStatusFilter(StockStatus? status) {
    _statusFilter = status;
    _selectedCategoryId = null;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _statusFilter = null;
    notifyListeners();
  }

  // ---- CRUD ----
  Product? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final idx = _products.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _products[idx] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Update quantity after a stock movement
  void adjustQuantity(String productId, int delta) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx >= 0) {
      final p = _products[idx];
      final newQty = (p.quantity + delta).clamp(0, 999999);
      _products[idx] = p.copyWith(quantity: newQty);
      notifyListeners();
    }
  }

  String generateId() => 'p${DateTime.now().millisecondsSinceEpoch}';
}
