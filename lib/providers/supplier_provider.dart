import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../data/mock_data.dart';

/// Manages supplier list
class SupplierProvider extends ChangeNotifier {
  final List<Supplier> _suppliers = List.from(MockData.suppliers);
  String _search = '';

  List<Supplier> get suppliers => _filtered();
  List<Supplier> get allSuppliers => List.unmodifiable(_suppliers);
  String get search => _search;

  List<Supplier> _filtered() {
    if (_search.isEmpty) return List.unmodifiable(_suppliers);
    final q = _search.toLowerCase();
    return _suppliers
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            (s.email?.toLowerCase().contains(q) ?? false) ||
            (s.phone?.contains(q) ?? false))
        .toList();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  Supplier? findById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void addSupplier(Supplier supplier) {
    _suppliers.add(supplier);
    notifyListeners();
  }

  void updateSupplier(Supplier updated) {
    final idx = _suppliers.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) {
      _suppliers[idx] = updated;
      notifyListeners();
    }
  }

  void deleteSupplier(String id) {
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  String generateId() => 'sup${DateTime.now().millisecondsSinceEpoch}';
}
