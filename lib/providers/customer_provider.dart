import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/user_profile.dart';
import '../data/api_service.dart';

/// Manages customer directory with backend fetching, search, pagination, and CRUD support
class CustomerProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Customer> _customers = [];
  String _search = '';
  bool _isLoading = false;
  String? _error;
  UserProfile? _currentUser;

  CustomerProvider({UserProfile? currentUser}) : _currentUser = currentUser {
    if (_api.hasToken) {
      fetchCustomers();
    }
  }

  void updateUser(UserProfile? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clear() {
    _customers = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  UserProfile? get currentUser => _currentUser;
  List<Customer> get customers => _filtered();
  List<Customer> get allCustomers => List.unmodifiable(_customers);
  String get search => _search;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Customer> _filtered() {
    if (_search.isEmpty) return List.unmodifiable(_customers);
    final q = _search.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.email?.toLowerCase().contains(q) ?? false) ||
            c.phone.contains(q))
        .toList();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  /// Fetch customers from API
  Future<void> fetchCustomers({String? search}) async {
    if (!_api.hasToken) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getCustomers(search: search, size: 100);
      _customers = list.map((item) => Customer.fromJson(item as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Customer? findById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add Customer via API
  Future<Customer?> addCustomer(Customer customer) async {
    if (_currentUser != null && !_currentUser!.canManageCustomers) {
      _error = 'Permission denied: Staff accounts cannot add customers.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createCustomer(
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
      );
      final created = Customer.fromJson(data);
      _customers.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Update Customer via API
  Future<Customer?> updateCustomer(Customer customer) async {
    if (_currentUser != null && !_currentUser!.canManageCustomers) {
      _error = 'Permission denied: Staff accounts cannot update customers.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.updateCustomer(
        customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
      );
      final updated = Customer.fromJson(data);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Toggle Customer active/inactive status via API
  Future<bool> toggleCustomerStatus(String id, bool active) async {
    if (_currentUser != null && !_currentUser!.canManageCustomers) {
      _error = 'Permission denied: Staff accounts cannot change customer status.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.updateCustomerStatus(id, active);
      final updated = Customer.fromJson(data);
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _customers[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Soft deactivation: set active = false via API
  Future<bool> deactivateCustomer(String id) async {
    return toggleCustomerStatus(id, false);
  }

  /// Delete Customer via API (Admin only)
  Future<bool> deleteCustomer(String id) async {
    if (_currentUser != null && !_currentUser!.canDeleteCustomers) {
      _error = 'Permission denied: Only Administrators can delete customers.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
