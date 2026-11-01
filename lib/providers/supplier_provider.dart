import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../models/user_profile.dart';
import '../data/api_service.dart';

/// Manages supplier list with real backend fetching, search, and CRUD support
class SupplierProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Supplier> _suppliers = [];
  String _search = '';
  bool _isLoading = false;
  String? _error;
  UserProfile? _currentUser;

  SupplierProvider({UserProfile? currentUser}) : _currentUser = currentUser {
    if (_api.hasToken) {
      fetchSuppliers();
    }
  }

  void updateUser(UserProfile? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clear() {
    _suppliers = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  UserProfile? get currentUser => _currentUser;
  List<Supplier> get suppliers => _filtered();
  List<Supplier> get allSuppliers => List.unmodifiable(_suppliers);
  String get search => _search;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// Fetch suppliers from API
  Future<void> fetchSuppliers() async {
    if (!_api.hasToken) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getSuppliers(size: 100);
      _suppliers = list.map((item) => Supplier.fromJson(item as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Supplier? findById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add Supplier via API
  Future<Supplier?> addSupplier(Supplier supplier) async {
    if (_currentUser != null && !_currentUser!.canManageSuppliers) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete suppliers.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createSupplier(
        name: supplier.name,
        phone: supplier.phone ?? '',
        email: supplier.email,
        address: supplier.address,
      );
      final created = Supplier.fromJson(data);
      _suppliers.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Update Supplier via API
  Future<bool> updateSupplier(Supplier updated) async {
    if (_currentUser != null && !_currentUser!.canManageSuppliers) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete suppliers.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.updateSupplier(
        updated.id,
        name: updated.name,
        phone: updated.phone ?? '',
        email: updated.email,
        address: updated.address,
      );
      final saved = Supplier.fromJson(data);
      final idx = _suppliers.indexWhere((s) => s.id == updated.id);
      if (idx >= 0) {
        _suppliers[idx] = saved;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Delete Supplier via API
  Future<bool> deleteSupplier(String id) async {
    if (_currentUser != null && !_currentUser!.canManageSuppliers) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete suppliers.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteSupplier(id);
      _suppliers.removeWhere((s) => s.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void toggleSupplierStatus(String id) {
    if (_currentUser != null && !_currentUser!.canManageSuppliers) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete suppliers.';
      notifyListeners();
      return;
    }

    final idx = _suppliers.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      final current = _suppliers[idx];
      final newStatus = current.isActive ? 'Inactive' : 'Active';
      _suppliers[idx] = current.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  String generateId() => 'sup${DateTime.now().millisecondsSinceEpoch}';
}
