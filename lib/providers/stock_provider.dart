import 'package:flutter/foundation.dart';
import '../models/stock_movement.dart';
import '../data/mock_data.dart';

/// Manages stock movements (in/out history)
class StockProvider extends ChangeNotifier {
  final List<StockMovement> _movements = List.from(MockData.movements);

  // Filter state
  String _search = '';
  MovementType? _typeFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _productFilter;

  List<StockMovement> get allMovements => List.unmodifiable(_movements);
  List<StockMovement> get filteredMovements => _applyFilters();
  String get search => _search;
  MovementType? get typeFilter => _typeFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get productFilter => _productFilter;

  /// Last 5 movements for dashboard
  List<StockMovement> get recentMovements {
    final sorted = List<StockMovement>.from(_movements)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  /// Recent transactions for stock screen (last 10)
  List<StockMovement> get recentTransactions {
    final sorted = List<StockMovement>.from(_movements)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  List<StockMovement> _applyFilters() {
    var list = List<StockMovement>.from(_movements);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((m) => m.productName.toLowerCase().contains(q)).toList();
    }
    if (_typeFilter != null) {
      list = list.where((m) => m.type == _typeFilter).toList();
    }
    if (_startDate != null) {
      list = list.where((m) => m.date.isAfter(
          _startDate!.subtract(const Duration(seconds: 1)))).toList();
    }
    if (_endDate != null) {
      list = list.where((m) => m.date.isBefore(
          _endDate!.add(const Duration(days: 1)))).toList();
    }
    if (_productFilter != null) {
      list = list.where((m) => m.productId == _productFilter).toList();
    }
    // Sort newest first
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void setSearch(String q) { _search = q; notifyListeners(); }
  void setTypeFilter(MovementType? t) { _typeFilter = t; notifyListeners(); }
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start; _endDate = end; notifyListeners();
  }
  void setProductFilter(String? id) { _productFilter = id; notifyListeners(); }
  void clearFilters() {
    _search = ''; _typeFilter = null;
    _startDate = null; _endDate = null; _productFilter = null;
    notifyListeners();
  }

  /// Add a new movement and return it
  StockMovement addMovement(StockMovement movement) {
    _movements.insert(0, movement);
    notifyListeners();
    return movement;
  }

  String generateId() => 'm${DateTime.now().millisecondsSinceEpoch}';

  /// Stock movements for a specific product
  List<StockMovement> movementsForProduct(String productId) {
    return _movements
        .where((m) => m.productId == productId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ---- Chart data ----
  List<double> get stockInLast7Days => MockData.stockInLast7Days();
  List<double> get stockOutLast7Days => MockData.stockOutLast7Days();
}
